-- Cross-buffer context for minuet inline completion: GitHub Copilot's
-- "neighboring tabs" heuristic (reverse-engineered by
-- thakkarparth007/copilot-explorer). Scans recently-visited buffers of the
-- same filetype, splits each into fixed-size line windows, scores every
-- window against the text right before the cursor with Jaccard similarity
-- (token-set overlap), and keeps the single best window per file.
--
-- Unlike lua/minuet_imports.lua this needs no LSP round trip and no
-- treesitter parser -- it's a cheap, pure local-text heuristic (no
-- understanding of what anything means, just vocabulary overlap), so it
-- runs on any filetype and refreshes on a much shorter debounce.
local M = {}

local WINDOW_LINES = 60 -- Copilot's default fixed-window size
local REF_LINES = 60 -- lines before cursor used as the reference set
local MAX_RECENT_BUFFERS = 20 -- Copilot: "most recently accessed 20 files of the same language"
local MAX_FILES = 3 -- how many distinct files' best window to keep
local MIN_SCORE = 0.15 -- below this it's just incidental keyword overlap (def/return/import), not a real match
local MAX_CHARS = 2500
local DEBOUNCE_MS = 800 -- cheaper than LSP resolution, can refresh more eagerly

M.cache = {} -- bufnr -> formatted string
local recent = {} -- ordered list of bufnr, most-recent last
local timers = {} -- bufnr -> uv_timer

local function tokens(text)
  local set, n = {}, 0
  for w in text:gmatch('%w+') do
    if not set[w] then
      set[w] = true
      n = n + 1
    end
  end
  return set, n
end

local function jaccard(set_a, n_a, set_b, n_b)
  if n_a == 0 or n_b == 0 then
    return 0
  end
  local inter = 0
  for w in pairs(set_a) do
    if set_b[w] then
      inter = inter + 1
    end
  end
  return inter / (n_a + n_b - inter)
end

local function track_recent(bufnr)
  for i, b in ipairs(recent) do
    if b == bufnr then
      table.remove(recent, i)
      break
    end
  end
  table.insert(recent, bufnr)
  while #recent > MAX_RECENT_BUFFERS do
    table.remove(recent, 1)
  end
end

-- best-scoring WINDOW_LINES-line chunk of `bufnr`, scored against ref_set
local function best_window(bufnr, ref_set, ref_n)
  local total = vim.api.nvim_buf_line_count(bufnr)
  local best_score, best_lines = 0, nil
  for start = 0, total - 1, WINDOW_LINES do
    local stop = math.min(start + WINDOW_LINES, total)
    local lines = vim.api.nvim_buf_get_lines(bufnr, start, stop, false)
    local text = table.concat(lines, '\n')
    local set, n = tokens(text)
    local score = jaccard(ref_set, ref_n, set, n)
    if score > best_score then
      best_score, best_lines = score, text
    end
  end
  return best_score, best_lines
end

local function refresh(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype == '' then
    return
  end
  local ft = vim.bo[bufnr].filetype

  local win = vim.fn.bufwinid(bufnr)
  local cursor_row = win ~= -1 and (vim.api.nvim_win_get_cursor(win)[1] - 1) or 0
  local ref_start = math.max(0, cursor_row - REF_LINES)
  local ref_lines = vim.api.nvim_buf_get_lines(bufnr, ref_start, cursor_row + 1, false)
  local ref_set, ref_n = tokens(table.concat(ref_lines, '\n'))
  if ref_n == 0 then
    M.cache[bufnr] = nil
    return
  end

  local candidates = {}
  for _, cand in ipairs(recent) do
    if cand ~= bufnr and vim.api.nvim_buf_is_loaded(cand) and vim.bo[cand].filetype == ft and vim.bo[cand].buflisted then
      local score, text = best_window(cand, ref_set, ref_n)
      if score >= MIN_SCORE then
        table.insert(candidates, {
          score = score,
          text = text,
          path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(cand), ':.'),
        })
      end
    end
  end
  table.sort(candidates, function(a, b)
    return a.score > b.score
  end)

  local parts, total_chars = {}, 0
  for i = 1, math.min(#candidates, MAX_FILES) do
    local c = candidates[i]
    local chunk = string.format('# %s\n%s\n', c.path, c.text)
    total_chars = total_chars + #chunk
    if total_chars > MAX_CHARS then
      break
    end
    table.insert(parts, chunk)
  end
  M.cache[bufnr] = #parts > 0 and table.concat(parts, '\n') or nil
end

---Read by minuet's chat_input template function; always synchronous.
function M.get_context(bufnr)
  local text = M.cache[bufnr or vim.api.nvim_get_current_buf()]
  if not text then
    return ''
  end
  return '<neighboring_files>\n' .. text .. '</neighboring_files>\n'
end

function M.setup()
  local group = vim.api.nvim_create_augroup('MinuetNeighboringFiles', { clear = true })
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function(args)
      if vim.bo[args.buf].buflisted then
        track_recent(args.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'CursorMoved', 'CursorMovedI', 'InsertEnter' }, {
    group = group,
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
  })
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
      for i, b in ipairs(recent) do
        if b == bufnr then
          table.remove(recent, i)
          break
        end
      end
    end,
  })
end

return M
