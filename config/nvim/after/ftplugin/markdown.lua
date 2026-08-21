-- Wide markdown tables shatter when soft-wrapped (render-markdown.nvim redraws
-- them best without wrap). Keep lines intact and scroll horizontally instead.
vim.opt_local.wrap = false
