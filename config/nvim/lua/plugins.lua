
local lazy_events = { 'BufRead', 'CursorHold', 'CursorMoved', 'BufNewFile', 'InsertEnter' }

-- bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

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
            filetype = { 'lazy', 'qf', 'toggleterm', 'notify', 'diff' },
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

require('lazy').setup({
  { 'hrsh7th/nvim-cmp', config = nvim_cmp_config },
  'hrsh7th/cmp-nvim-lsp',
  'saadparwaiz1/cmp_luasnip',
  'L3MON4D3/LuaSnip',
  { 'hrsh7th/cmp-path' },

  -- lsp (config lives in lua/lsp_config.lua)
  { 'neovim/nvim-lspconfig', config = function() require('lsp_config') end },

  { 'liuchengxu/vista.vim', cmd = { 'Vista' } }, -- :Vista!! still triggers via the Vista stub

  -- file tree
  {
    'nvim-tree/nvim-tree.lua',
    cmd = 'NvimTreeToggle',
    config = nvim_tree_config,
  },

  -- Github copilot
  'github/copilot.vim',
  'nvim-lua/plenary.nvim',
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    branch = 'main',
    config = function()
      require('CopilotChat').setup()
    end,
  },

  -- zoom in/out
  { 'troydm/zoomwintab.vim', cmd = 'ZoomWinTabToggle' },

  -- <Ctrl>+n like behavior <C-d> in Sublime text
  'mg979/vim-visual-multi',

  -- linter
  { 'dense-analysis/ale', ft = { 'javascript', 'typescript' } },

  -- fzf search
  { 'junegunn/fzf.vim', dependencies = { { 'junegunn/fzf', build = ':call fzf#install()' } } },

  -- auto-pairs (integrates with nvim-cmp: adds () after completing a function)
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup({})
      local cmp_autopairs = require('nvim-autopairs.completion.cmp')
      require('cmp').event:on('confirm_done', cmp_autopairs.on_confirm_done())
    end,
  },

  -- \ + cc to comment, \ + cu to uncomment
  'scrooloose/nerdcommenter',

  -- filetype
  { 'sheerun/vim-polyglot', event = lazy_events },

  -- Indent guides
  { 'lukas-reineke/indent-blankline.nvim', main = 'ibl', opts = {} },

  -- snippets <C-j> to expand
  'SirVer/ultisnips',
  'honza/vim-snippets',

  -- Interface
  'itchyny/lightline.vim',
  { 'edkolev/tmuxline.vim', cmd = { 'Tmuxline', 'TmuxlineSnapshot' } },
  {
    'kaicataldo/material.vim',
    branch = 'main',
    priority = 1000, -- load colorscheme before other start plugins
    config = function()
      vim.g.material_terminal__italics = 1
      vim.g.material_theme_style = 'default'
      vim.cmd('colorscheme material')
    end,
  },

  -- emmet <C-y>, to expand html tag
  'mattn/emmet-vim',

  -- floating terminal
  'voldikss/vim-floaterm',

  -- AI: CodeCompanion (chat + inline, uses $ANTHROPIC_API_KEY)
  {
    'olimorris/codecompanion.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('codecompanion').setup({
        strategies = {
          chat = { adapter = 'anthropic' },
          inline = { adapter = 'anthropic' },
        },
      })
    end,
  },

  -- AI: Avante (Cursor-like, uses $ANTHROPIC_API_KEY)
  {
    'yetone/avante.nvim',
    event = 'VeryLazy',
    version = false,
    build = 'make', -- builds the native binary; needs make + a C compiler
    opts = {
      provider = 'claude',
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'nvim-tree/nvim-web-devicons',
    },
  },
})

-- NvimTree {{{
-- disable netrw at the very start (strongly advised)
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
vim.diagnostic.config({
    virtual_text = {
        prefix = '😖',
    },
    update_in_insert = false,
})
-- }}}

-- enable diagnostic signs in the sign column
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
