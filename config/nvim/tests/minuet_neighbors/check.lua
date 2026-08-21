-- Self-check for lua/minuet_neighbors.lua.
-- Run: nvim --headless tests/minuet_neighbors/main.py -c "luafile tests/minuet_neighbors/check.lua"
-- Opens a vocabulary-similar buffer and a vocabulary-dissimilar buffer
-- alongside main.py, then checks that the Jaccard scan surfaces the similar
-- one's content and excludes the dissimilar one.
local main_buf = vim.api.nvim_get_current_buf()

vim.cmd('edit tests/minuet_neighbors/similar.py')
local similar_buf = vim.api.nvim_get_current_buf()
vim.cmd('edit tests/minuet_neighbors/dissimilar.py')
local dissimilar_buf = vim.api.nvim_get_current_buf()
vim.cmd('buffer ' .. main_buf)

vim.cmd('normal! G$')
vim.cmd('startinsert!')

local mn = require('minuet_neighbors')
mn.cache[main_buf] = nil
vim.api.nvim_exec_autocmds('TextChangedI', { buffer = main_buf })

local resolved = vim.wait(5000, function()
  return mn.cache[main_buf] ~= nil
end, 20)
assert(resolved, 'minuet_neighbors never populated its cache for main.py')

local ctx = mn.get_context(main_buf)
print('--- resolved context ---')
print(ctx)
print('------------------------')

assert(ctx:match('similar%.py'), 'missing similar.py (should score high on shared vocabulary)')
assert(ctx:match('clip_outliers'), 'missing similar.py content')
assert(not ctx:match('dissimilar%.py'), 'dissimilar.py should not have scored high enough to appear')
assert(not ctx:match('requests'), 'dissimilar.py content leaked in despite low similarity')

print('ALL CHECKS PASSED')
vim.cmd('qa!')
