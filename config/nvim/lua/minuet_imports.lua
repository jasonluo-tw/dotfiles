-- Cross-file context for minuet inline completion.
--
-- minuet only ever sees the current buffer (text before/after cursor); it has
-- no idea what a function/method actually does. This module scans the calls
-- near the cursor — `foo(...)` and `obj.method(...)` alike, treesitter makes
-- no distinction — and asks jedi_language_server where each one is really
-- defined (textDocument/definition). It doesn't matter whether the callee
-- came from `from x import y`, `import x` + `x.y()`, a project-local
-- function defined far above in the same file, or a method on some object:
-- jedi's type inference resolves all of them the same way. Once resolved,
-- the definition's signature + docstring (never its body) is pulled out of
-- the target file via treesitter and cached so minuet's chat_input template
-- can inline it into the prompt.
--
-- ponytail: resolution runs async (debounced on cursor/text changes) while
-- the prompt-building call is synchronous, so the injected context can lag
-- one edit behind. Good enough for "what does this do", not a correctness
-- tool. Overloads and result[1] from a multi-location response: we only
-- ever look at the first location jedi returns.
local M = {}

M.cache = {} -- bufnr -> formatted string
local file_cache = {} -- abs path -> { mtime, text, tree }
local timers = {} -- bufnr -> uv_timer

local MAX_SYMBOLS = 8
local MAX_CHARS = 3000
local DEBOUNCE_MS = 1200
local WINDOW_BEFORE = 60 -- lines above the cursor to scan for calls
local WINDOW_AFTER = 15 -- lines below the cursor to scan for calls
local SAME_FILE_SKIP_RADIUS = 60 -- same-file defs this close to the cursor are already in minuet's own context

-- bare calls to these are noise, not worth a round trip
local BUILTINS = {
  print = true, len = true, range = true, str = true, int = true, float = true,
  bool = true, list = true, dict = true, set = true, tuple = true, isinstance = true,
  super = true, type = true, enumerate = true, zip = true, map = true, filter = true,
  sorted = true, min = true, max = true, sum = true, abs = true, open = true,
  format = true, hasattr = true, getattr = true, setattr = true, repr = true,
  id = true, iter = true, next = true, any = true, all = true, round = true,
  input = true, vars = true,
}

-- built lazily: the python parser may not be compiled yet on first load,
-- and this must never throw at require-time (it would take minuet's whole
-- setup down with it)
local call_query
local function get_call_query()
  if call_query == nil then
    local ok, q = pcall(vim.treesitter.query.parse, 'python', [[
      (call function: (identifier) @callee)
      (call function: (attribute object: (_) @obj attribute: (identifier) @callee))
    ]])
    call_query = ok and q or false
  end
  return call_query or nil
end

-- `foo(...)` and `obj.method(...)` calls within a window around the cursor.
-- captures are emitted in document order and each attribute-call match
-- yields its @obj right before its @callee, so pairing sequentially is safe.
local function call_positions_near_cursor(bufnr, cursor_row)
  local query = get_call_query()
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, 'python')
  if not query or not ok or not parser then
    return {}
  end
  local ids = {}
  for i, name in ipairs(query.captures) do
    ids[name] = i
  end

  local root = parser:parse()[1]:root()
  local win_start = math.max(0, cursor_row - WINDOW_BEFORE)
  local win_end = cursor_row + WINDOW_AFTER

  local seen, positions, pending_obj_text = {}, {}, nil
  for id, node in query:iter_captures(root, bufnr, win_start, win_end) do
    if id == ids.obj then
      pending_obj_text = vim.treesitter.get_node_text(node, bufnr)
    else
      local obj_text = pending_obj_text
      pending_obj_text = nil
      local callee_text = vim.treesitter.get_node_text(node, bufnr)
      local is_noise = not obj_text and BUILTINS[callee_text]
      local key = (obj_text or '') .. '.' .. callee_text
      if not is_noise and not seen[key] then
        seen[key] = true
        local row, col = node:start()
        table.insert(positions, { row = row, col = col })
      end
    end
    if #positions >= MAX_SYMBOLS then
      break
    end
  end
  return positions
end

-- The call actively being typed (cursor right after an unclosed `(`) is the
-- highest-value target, but it's also exactly the one treesitter can't hand
-- back as a clean `call` node: an unclosed paren makes it (and everything
-- lexically after it) fall into an ERROR node, invisible to the query above.
-- jedi's own parser doesn't care about that, so resolve this one position
-- straight off the raw line text instead of relying on treesitter for it.
local function typing_call_position(bufnr, cursor_row, cursor_col)
  local line = vim.api.nvim_buf_get_lines(bufnr, cursor_row, cursor_row + 1, false)[1]
  if not line then
    return nil
  end
  local prefix = line:sub(1, cursor_col)

  local _, e = prefix:find('[%w_]+%.[%w_]+%($')
  if e then
    return { row = cursor_row, col = e - 2 }
  end

  local name
  _, e, name = prefix:find('([%w_]+)%($')
  if e and not BUILTINS[name] then
    return { row = cursor_row, col = e - 2 }
  end

  return nil
end

local function read_file_tree(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return nil
  end
  local cached = file_cache[path]
  if cached and cached.mtime == stat.mtime.sec then
    return cached
  end
  local lines = vim.fn.readfile(path)
  local text = table.concat(lines, '\n')
  local ok, parser = pcall(vim.treesitter.get_string_parser, text, 'python')
  if not ok then
    return nil
  end
  cached = { mtime = stat.mtime.sec, text = text, tree = parser:parse()[1] }
  file_cache[path] = cached
  return cached
end

-- walk up to the nearest def/class, including its decorators if any
local function enclosing_def(tree, row, col)
  local node = tree:root():named_descendant_for_range(row, col, row, col)
  while node do
    local t = node:type()
    if t == 'function_definition' or t == 'class_definition' then
      local parent = node:parent()
      if parent and parent:type() == 'decorated_definition' then
        return parent
      end
      return node
    end
    node = node:parent()
  end
  return nil
end

-- slice source text from node start to just before its body: signature (and
-- decorators) without the implementation, plus the docstring if present
local function extract_signature(node, text)
  local inner = node
  if inner:type() == 'decorated_definition' then
    for child in inner:iter_children() do
      local t = child:type()
      if t == 'function_definition' or t == 'class_definition' then
        inner = child
        break
      end
    end
  end
  local body = inner:field('body')[1]
  if not body then
    return nil
  end
  local _, _, start_byte = node:start()
  local _, _, body_byte = body:start()
  local sig = text:sub(start_byte + 1, body_byte):gsub('%s+$', '')

  local docstring
  local first_stmt = body:named_child(0)
  if first_stmt and first_stmt:type() == 'expression_statement' then
    local str_node = first_stmt:named_child(0)
    if str_node and str_node:type() == 'string' then
      docstring = vim.treesitter.get_node_text(str_node, text)
      if #docstring > 400 then
        docstring = docstring:sub(1, 400) .. '..."""'
      end
    end
  end

  return sig, docstring
end

local function resolve_one(bufnr, pos, cursor_row, on_done)
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = { line = pos.row, character = pos.col },
  }
  vim.lsp.buf_request(bufnr, 'textDocument/definition', params, function(_, result)
    if not result or vim.tbl_isempty(result) then
      return on_done(nil)
    end
    local first = result[1]
    local loc = first.range and first or (first.targetRange and { uri = first.targetUri, range = first.targetRange })
    if not loc then
      return on_done(nil)
    end
    local path = vim.uri_to_fname(loc.uri)
    local same_file = path == vim.api.nvim_buf_get_name(bufnr)
    if same_file and math.abs(loc.range.start.line - cursor_row) <= SAME_FILE_SKIP_RADIUS then
      return on_done(nil) -- close enough that minuet's own before/after-cursor context already covers it
    end
    local cached = read_file_tree(path)
    if not cached then
      return on_done(nil)
    end
    local def_node = enclosing_def(cached.tree, loc.range.start.line, loc.range.start.character)
    if not def_node then
      return on_done(nil)
    end
    local sig, doc = extract_signature(def_node, cached.text)
    if not sig then
      return on_done(nil)
    end
    on_done({ path = vim.fn.fnamemodify(path, ':.'), sig = sig, doc = doc })
  end)
end

local function refresh(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= 'python' then
    return
  end
  if not vim.lsp.get_clients({ bufnr = bufnr, name = 'jedi_language_server' })[1] then
    return
  end

  local win = vim.fn.bufwinid(bufnr)
  local cursor = win ~= -1 and vim.api.nvim_win_get_cursor(win) or { 1, 0 }
  local cursor_row, cursor_col = cursor[1] - 1, cursor[2]

  local positions = call_positions_near_cursor(bufnr, cursor_row)
  local typing_pos = typing_call_position(bufnr, cursor_row, cursor_col)
  if typing_pos then
    table.insert(positions, 1, typing_pos) -- what's being typed right now wins the cap over older matches
  end
  while #positions > MAX_SYMBOLS do
    table.remove(positions)
  end
  if #positions == 0 then
    M.cache[bufnr] = nil
    return
  end

  local results, pending = {}, #positions
  local function done(entry)
    if entry then
      table.insert(results, entry)
    end
    pending = pending - 1
    if pending > 0 then
      return
    end
    local parts, total = {}, 0
    for _, e in ipairs(results) do
      local chunk = string.format('# %s\n%s\n%s\n', e.path, e.sig, e.doc or '')
      total = total + #chunk
      if total > MAX_CHARS then
        break
      end
      table.insert(parts, chunk)
    end
    M.cache[bufnr] = #parts > 0 and table.concat(parts, '\n') or nil
  end

  for _, pos in ipairs(positions) do
    resolve_one(bufnr, pos, cursor_row, done)
  end
end

---Read by minuet's chat_input template function; always synchronous.
function M.get_context(bufnr)
  local text = M.cache[bufnr or vim.api.nvim_get_current_buf()]
  if not text then
    return ''
  end
  return '<nearby_call_definitions>\n' .. text .. '</nearby_call_definitions>\n'
end

function M.setup()
  local group = vim.api.nvim_create_augroup('MinuetImportSymbols', { clear = true })
  vim.api.nvim_create_autocmd(
    { 'BufEnter', 'InsertEnter', 'TextChanged', 'TextChangedI', 'CursorMoved', 'CursorMovedI' },
    {
      group = group,
      pattern = '*.py',
      callback = function(args)
        local bufnr = args.buf
        if not timers[bufnr] then
          timers[bufnr] = vim.uv.new_timer()
        end
        timers[bufnr]:stop()
        timers[bufnr]:start(DEBOUNCE_MS, 0, vim.schedule_wrap(function()
          refresh(bufnr)
        end))
      end,
    }
  )
  vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    callback = function(args)
      local bufnr = args.buf
      if timers[bufnr] then
        timers[bufnr]:stop()
        timers[bufnr]:close()
        timers[bufnr] = nil
      end
      M.cache[bufnr] = nil
    end,
  })
end

return M
