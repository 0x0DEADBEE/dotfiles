local options = {
    updatetime=300,
    cmdheight= 4,
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
    use {
        "gbprod/substitute.nvim",
        config = function ()
            require("substitute").setup({
                range = {
                    register = '"+'
                }
            })
        end
    }
    use "tpope/vim-surround"
    use "easymotion/vim-easymotion"
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
        { name = 'nvim_lsp_signature_help' },
    }),
})
local cmp_autopairs = require('nvim-autopairs.completion.cmp')
cmp.event:on(
'confirm_done',
cmp_autopairs.on_confirm_done()
)

local lspSignatureCfg = {
    fix_pos = true,
    always_trigger = true,
    hint_enable = false,
}
require("lsp_signature").setup(lspSignatureCfg)

local lspConfig = require("lspconfig")
local langServers = {"pyright", "sumneko_lua", "clangd"}
local capabilities = require("cmp_nvim_lsp").default_capabilities()
for i=1, #langServers do
    lspConfig[langServers[i]].setup({
        capabilities = capabilities
    })
end

local function smartIndent()
    local currLine, currCol = unpack(vim.api.nvim_win_get_cursor(0))
    --! => nore
    vim.api.nvim_command("normal! gg=G")
    vim.api.nvim_command("normal! " .. currLine .. "G")
end

local function map(modes, key, value, opts)
    for i=1, string.len(modes) do
        local mode = string.sub(modes, i, i)
        vim.keymap.set(mode, key, value, opts)
    end
end
local keybindings = {
    {"n", "sx", "<cmd>lua require('substitute.exchange').operator()<cr>", { noremap = true } },
    {"n", "sxx", "<cmd>lua require('substitute.exchange').line()<cr>", { noremap = true } },
    {"x", "sx", "<cmd>lua require('substitute.exchange').visual()<cr>", { noremap = true } },
    {"n", "s", "<cmd>lua require('substitute').operator()<cr>", { noremap = true } },
    {"x", "s", "<cmd>lua require('substitute').visual()<cr>", { noremap = true }},
    {"n", "ss", "<cmd>lua require('substitute').line()<cr>", { noremap = true }},
    {"n", "<a-s-i>", "", {callback=smartIndent}},
    {"xnov", "F" , "<Plug>(easymotion-Fl)", {}},
    {"xnov", "T" , "<Plug>(easymotion-Tl)", {}},
    {"xnov", "t" , "<Plug>(easymotion-tl)", {}},
    {"xnov", "f" , "<Plug>(easymotion-fl)", {}},
    {"xnv", "<leader>p", '"+p', {noremap=true}},
    {"xnv", "<leader>y", '"+y', {noremap=true}},
    {"xnv", "m", 'd', {noremap=true}},
    {"xnv", "mm", 'dd', {noremap=true}},
    {"xnv", "c", '"_c', {noremap=true}},
    {"xnv", "d", '"_d', {noremap=true}},
    {"xnv", "x", '"_x', {noremap=true}},
}
for k, v in pairs(keybindings) do
    map(v[1], v[2], v[3], v[4])
end

local function isempty(s)
    return s == nil or s == ''
end
function echoDoc()
    print("working")
    if not pcall(require, 'lsp_signature') then return end
    local sig = require("lsp_signature").status_line(100)
    if isempty(sig.label) and isempty(sig.hint) then return
    else print(sig.label .. "   " .. sig.hint )
    end
end

local autocmds = {
    {{"CursorHoldI, CursorMoved, CursorHold"}, {pattern = "*", callback = function()
        echoDoc()
    end,}}
}

for k, v in pairs(autocmds) do
    vim.api.nvim_create_autocmd(v[1], v[2])
end
--
--local function isEmptyStr(s)
--    return s == nil or s == ""
--end
--
--function echoDoc()
--    local sig = require("lsp_signature").status_line(200)
--    signature_length = #sig.label
--    sig.label = sig.label:gsub("[\n\r]+", " ")
--    sig.hint = sig.hint:gsub("[\n\r]+", " ")
--    if isEmptyStr(sig.label) and isEmptyStr(sig.hint) then return
--    else print(sig.label .. "   " .. sig.hint )
--    end
--end
--
