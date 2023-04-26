local lazy_events = { 'BufRead', 'CursorHold', 'CursorMoved', 'BufNewFile', 'InsertEnter' }

local function nvim_tree_config()
  require('nvim-tree').setup({
    view = {
      side = 'left',
      signcolumn = 'no',
    },
    actions = {
      open_file = {
        window_picker = {
          exclude = {
            filetype = { 'packer', 'qf', 'toggleterm', 'notify', 'diff' },
            buftype = { 'nofile', 'terminal', 'help' },
          },
        },
      },
    },
    renderer = {
      add_trailing = true,
      group_empty = true,
      highlight_git = true,
      icons = {
        show = {
          file = true,
          folder_arrow = false,
          folder = true,
          git = false,
        },
        glyphs = {
          default = ' ',
          symlink = ' ',
          folder = {
            arrow_open = '▾',
            arrow_closed = '▸',
            default = '▸',
            open = '▾',
            empty = '▸',
            empty_open = '▾',
            symlink = '▸',
            symlink_open = '▾',
          },
        },
      },
    },
  })
end

--- hrsh7th/nvim-cmp
local function nvim_cmp_config()
  local cmp = require('cmp')

  cmp.setup({
    mapping =  cmp.mapping.preset.insert({
      ['<cr>'] = cmp.mapping.confirm(),
      -- replace omnifunc?
      ['<c-x><c-o>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'nvim_lua' },
    }, {
      { name = 'buffer' },
      { name = 'path' },
      { name = 'emoji' },
    }),
    experimental = { ghost_text = false },
  })

  cmp.setup.cmdline('/', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'nvim_lsp_document_symbol' },
    }, {
      { name = 'buffer' },
    }),
  })

  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' },
    }, {
      { name = 'cmdline' },
    }),
  })
end

require('packer').startup(function(use)

    use({'neovim/nvim-lspconfig'})
    use({ 'hrsh7th/nvim-cmp', config = nvim_cmp_config })
    use({ 'hrsh7th/cmp-nvim-lsp' })
    use({ 'saadparwaiz1/cmp_luasnip' })
    use({ 'L3MON4D3/LuaSnip' })
    use({ 'hrsh7th/cmp-path', after = 'nvim-cmp' })

    use({ 'liuchengxu/vista.vim' , cmd = {'Vista', 'Vista!', 'Vista!!'} })

    -- use tree
    use({ 
        'nvim-tree/nvim-tree.lua',
        cmd = 'NvimTreeToggle',
        config = nvim_tree_config,
    })
    -- Github copilot
    use({ 'github/copilot.vim' })

    -- zoom in/out
    use({ 'troydm/zoomwintab.vim', cmd = 'ZoomWinTabToggle' })

    -- <Ctrl>+n like behavior <C-d> in Sublime text
    use({ 'mg979/vim-visual-multi' })

    -- linter(?
    use({ 'dense-analysis/ale', ft = {'javascript', 'typescript'} })

    -- fzf search
    use ({
        'junegunn/fzf.vim',
        requires = { 'junegunn/fzf', run = ':call fzf#install()' }
    })

    -- auto-pairs
    use({ 'jiangmiao/auto-pairs' })

    -- usage \ + cc to commend, \ + cu to uncommend
    use({ 'scrooloose/nerdcommenter' })

    -- filetype
    use({ 'sheerun/vim-polyglot' , event = lazy_events })

    -- Indent
    use({ 'nathanaelkane/vim-indent-guides' })

    -- snippets <C-j> to expand snippets
    use({ 'SirVer/ultisnips' })
    use({ 'honza/vim-snippets' })

    -- Interface
    use({ 'itchyny/lightline.vim' })
    use({ 'edkolev/tmuxline.vim', cmd = {'Tmuxline', 'TmuxlineSnapshot'} })
    use({ 'kaicataldo/material.vim', branch = 'main' })

    -- emmet usage <C-y>, to expand the html tag
    use({ 'mattn/emmet-vim' })

    -- floating terminal
    use({ 'voldikss/vim-floaterm' })

    -- lsp setting
    require('lsp_config')
end)

-- NvimTree {{{
-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true
-- }}}

-- Copilot {{{
vim.cmd([[imap <silent><script><expr> <C-f> copilot#Accept("")]])
vim.keymap.set('i', '<C-v>', '<Plug>(copilot-next)')
vim.keymap.set('i', '<C-r>', '<Plug>(copilot-previous)')
vim.g.copilot_no_tab_map = true
-- }}}

-- Diagnostic {{{
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, {
        virtual_text = {
            prefix = '😖',
        },
        update_in_insert = false
    }
)
-- }}}

-- enable diagnostic signs in the sign column
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

return 
