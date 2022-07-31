lua << EOF
vim.opt.backup = false                          -- creates a backup file
vim.opt.completeopt = { "menuone", "noinsert" } -- mostly just for cmp
vim.opt.ignorecase = true                       -- ignore case in search patterns
vim.opt.mouse = "a"                             -- allow the mouse to be used in neovim
vim.opt.smartcase = true                        -- smart case
vim.opt.smartindent = true                      -- make indenting smarter again
vim.opt.splitbelow = true                       -- force all horizontal splits to go below current window
vim.opt.splitright = true                       -- force all vertical splits to go to the right of current window
vim.opt.swapfile = false                        -- creates a swapfile
vim.opt.termguicolors = true                    -- set term gui colors (most terminals support this)
vim.opt.timeoutlen = 1000                       -- time to wait for a mapped sequence to complete (in milliseconds)
vim.opt.undofile = true                         -- enable persistent undo
vim.opt.updatetime = 300                        -- faster completion (4000ms default)
vim.opt.writebackup = false                     -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
vim.opt.expandtab = true                        -- convert tabs to spaces
vim.opt.shiftwidth = 4                          -- the number of spaces inserted for each indentation
vim.opt.tabstop = 4                             -- insert 2 spaces for a tab
vim.opt.cursorline = true                       -- highlight the current line
vim.opt.number = true                           -- set numbered lines
vim.opt.numberwidth = 4                         -- set number column width
vim.opt.signcolumn = "yes"                      -- always show the sign column, otherwise it would shift the text each time
vim.opt.wrap = false                            -- display lines as one long line
vim.opt.scrolloff = 8                           
vim.opt.sidescrolloff = 8
vim.opt.hidden = true -- required to keep multiple buffers and open multiple buffers
vim.opt.backspace = { 'indent', 'eol', 'start' }

local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)
keymap('n', '<leader>e', ':Lexplore 20 `dirname %`<CR>', opts)
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

function format_range_operator()
  local old_func = vim.go.operatorfunc
  _G.op_func_formatting = function()
    local start = vim.api.nvim_buf_get_mark(0, '[')
    local finish = vim.api.nvim_buf_get_mark(0, ']')
    vim.lsp.buf.range_formatting({}, start, finish)
    vim.go.operatorfunc = old_func
    _G.op_func_formatting = nil
  end
  vim.go.operatorfunc = 'v:lua.op_func_formatting'
  vim.api.nvim_feedkeys('g@', 'n', false)
end
vim.api.nvim_set_keymap("n", "<leader>format", "<cmd>lua format_range_operator()<CR>", {noremap = true})
EOF

set grepprg=rg\ --vimgrep\ --smart-case
set path+=Assets/Scripts/**
set wildmenu
set wildignore+=*.meta
let g:netrw_liststyle=3     " tree view
let g:netrw_list_hide= netrw_gitignore#Hide()
let g:netrw_list_hide.=',.*\.meta'
let g:netrw_banner=0

call plug#begin()
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp-signature-help'
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'
Plug 'rafamadriz/friendly-snippets'
Plug 'windwp/nvim-autopairs'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'folke/tokyonight.nvim'
call plug#end()

lua << EOF

local kind_icons = {
  Text = "", Method = "", Function = "", Constructor = "", Field = "", Variable = "", Class = "ﴯ", Interface = "", Module = "", Property = "ﰠ", Unit = "", Value = "", Enum = "", Keyword = "", Snippet = "", Color = "", File = "", Reference = "", Folder = "", EnumMember = "", Constant = "", Struct = "", Event = "", Operator = "", TypeParameter = ""
}

local cmp = require'cmp'
cmp.setup({
    snippet = {
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body)
      end,
    },
    formatting = {
        format = function(entry, vim_item)
          vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind)
          return vim_item
        end
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
      ['<Tab>'] = function(fallback)
        if cmp.visible() then
          cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
        else
          fallback()
        end
      end
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'nvim_lsp_signature_help' },
      { name = 'vsnip' }
    })
  })

local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

require("nvim-autopairs").setup {}
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
cmp.event:on(
  'confirm_done',
  cmp_autopairs.on_confirm_done()
)

local signs = {
    DiagnosticSignError = "",
    DiagnosticSignWarn = "",
    DiagnosticSignHint = "",
    DiagnosticSignInfo = ""
}
for type, icon in pairs(signs) do
    vim.fn.sign_define(type, {text = icon, texthl = type})
end

vim.diagnostic.config({ virtual_text = false, severity_sort = true })

local on_attach = function(client, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  local bufopts = { noremap=true, silent=true, buffer=bufnr }  
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)  
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<leader>af', vim.lsp.buf.formatting, bufopts)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "gl", '<cmd>lua vim.diagnostic.open_float({ border = "rounded" })<CR>', { noremap = true, silent = true })
end

require'lspconfig'.omnisharp.setup{
    capabilities = capabilities,
	on_attach = on_attach,
    cmd = { "/home/vlad/.local/share/omnisharp-linux-x64/run", "--languageserver" , "--hostPID", tostring(vim.fn.getpid()) },
    root_dir = require'lspconfig'.util.root_pattern("*.csproj","*.sln"),
    enable_roslyn_analyzers = true,
}

require'nvim-treesitter.configs'.setup {
  ensure_installed = { "c_sharp" },    
  auto_install = true,  
  highlight = {    
    enable = true,    
  },
}

vim.o.background = 'light'
vim.g.tokyonight_colors = { bg_highlight = "#050505", bg = "#000000", fg = "#ffffff", bg_visual = "#202020", fg_sidebar = "#ffffff", fg_dark = "#ffffff", bg_search = "#202020" }
vim.g.tokyonight_italic_keywords = false 
vim.g.tokyonight_transparent = true
vim.cmd[[colorscheme tokyonight]]
EOF

