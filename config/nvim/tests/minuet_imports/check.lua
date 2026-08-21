-- Self-check for lua/minuet_imports.lua.
-- Run: nvim --headless tests/minuet_imports/main.py -c "luafile tests/minuet_imports/check.lua"
-- Exercises the real pipeline against three cases in one buffer: a cross-file
-- function call (bare, from an import), a plain-import + method call (type
-- inferred through a local variable), and a same-file function whose call
-- site is far from its definition. No minuet/LLM call involved.
local bufnr = vim.api.nvim_get_current_buf()

-- put the cursor right where a real edit would leave it: mid-typing the
-- last (unclosed) call, in insert mode (only insert mode lets the cursor
-- rest past the last character, which is what "just typed `(`" looks like).
-- everything above the last line is complete, valid syntax.
vim.cmd('normal! G$')
vim.cmd('startinsert!')

local attached = vim.wait(15000, function()
  return #vim.lsp.get_clients({ bufnr = bufnr, name = 'jedi_language_server' }) > 0
end, 200)
assert(attached, 'jedi_language_server never attached to main.py')

-- kick the debounced refresh the same way real insert-mode typing would
vim.api.nvim_exec_autocmds('TextChangedI', { buffer = bufnr })

local mi = require('minuet_imports')
local resolved = vim.wait(15000, function()
  return mi.get_context(bufnr) ~= ''
end, 200)
assert(resolved, 'minuet_imports never populated its cache for main.py')

local ctx = mi.get_context(bufnr)
print('--- resolved context ---')
print(ctx)
print('------------------------')

-- case 1: cross-file bare call (from-import)
assert(ctx:match('run_data_preprocess%.py'), 'missing run_pipeline source path')
assert(ctx:match('def run_pipeline'), 'missing run_pipeline signature')

-- case 2: plain `import x as alias` + method call, type inferred through `loader`
assert(ctx:match('db%.py'), 'missing db.py source path (Loader/fetch)')
assert(ctx:match('def fetch'), 'missing Loader.fetch signature')
assert(ctx:match('Fetch a single record'), 'missing fetch docstring')

-- case 3: same-file function, call site far from its definition
assert(ctx:match('def far_away_helper'), 'missing far_away_helper signature (same-file, far from call site)')
assert(ctx:match('Doubles x'), 'missing far_away_helper docstring')

-- builtin calls near the cursor (`print(loader)`) must be filtered as noise
assert(not ctx:match('def print'), 'builtin print() should have been filtered, not resolved')

print('ALL CHECKS PASSED')
vim.cmd('qa!')
