local options = {
    hlsearch = false,
    shiftwidth = 4,
    softtabstop = 4,
    expandtab = true,
    tabstop = 4,
    scrolloff = 999,
    clipboard = vim.opt.clipboard + "unnamedplus" + "unnamed",
    iskeyword = vim.opt.iskeyword + "-" + "_",
    completeopt = vim.opt.completeopt + "menu" + "menuone",
    relativenumber = true,
    number = true
}
for k, v in pairs(options) do
    vim.opt[k] = v
end

require("packer").startup(function(use)
    --use {
    --    "svermeulen/vim-easyclip",
    --    requires = {"tpope/vim-repeat"},
    --}
    use {
        "windwp/nvim-autopairs",
        config = function ()
            require('nvim-autopairs').setup({
                enable_check_bracket_line = true,
                ignored_next_char = "[%w%.]",
            })
        end
    }
    use {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end
    }
    use "wbthomason/packer.nvim"
    use "neovim/nvim-lspconfig"
    use {
        "hrsh7th/nvim-cmp",
        "hrsh7th/cmp-nvim-lsp"
    }
    use "hrsh7th/cmp-buffer"
    use "ray-x/lsp_signature.nvim"
    --use "saadparwaiz1/cmp_luasnip"
    use "L3MON4D3/LuaSnip"
end)

local luasnip = require('luasnip')
local cmp = require("cmp")
cmp.setup({
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<C-e>'] = cmp.mapping.close(), --exit
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, {'i', 's'}),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, {'i', 's'}),
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'buffer' },
        { name = "luasnip" },
    }),
})
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
cmp.event:on(
  'confirm_done',
  cmp_autopairs.on_confirm_done()
)

local lspSignatureCfg = {
    fix_pos = true,
    always_trigger = false,
    hint_enable = false,
}
local lspSignature = require("lsp_signature")
lspSignature.setup(lspSignatureCfg)
local function echoDoc()
end
local lspConfig = require("lspconfig")
local langServers = {"pyright", "sumneko_lua", "clangd", "haskell-language-server"}
local capabilities = require("cmp_nvim_lsp").default_capabilities()
for i=1, #langServers do
    lspConfig[langServers[i]].setup({
        capabilities = capabilities
    })
end
