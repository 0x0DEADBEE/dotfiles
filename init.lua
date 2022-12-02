local lfs = require("lfs")
require('packer').startup(function(use)
    use "c60cb859/bufMov.nvim"
    use "ray-x/lsp_signature.nvim"
    use "hrsh7th/cmp-buffer"
    use "hrsh7th/nvim-cmp"
    use "hrsh7th/cmp-nvim-lsp"
    use "https://gitlab.com/yorickpeterse/nvim-window.git"
    use "folke/trouble.nvim"
    use "williamboman/mason.nvim"
    use "neovim/nvim-lspconfig"
    use "nvim-tree/nvim-tree.lua"
    use "nvim-treesitter/nvim-treesitter"
    use "easymotion/vim-easymotion"
    use "github/copilot.vim"
    use "wbthomason/packer.nvim"
    use "preservim/tagbar" -- exuberant-ctags
end)
require("trouble").setup({
    icons = false,
    fold_open = "", --icons
    fold_closed = "",
    indent_lines = true,
    signs = {
        error = "E",
        warning = "W",
        hint = "H",
        information = "I",
        other = "O",
    },
}) --TODO refresh
require("lsp_signature").setup({
    floating_window_off_y = 0,
    floating_window_above_cur_line = true,
    floating_window = true,
    fix_pos = true, -- do not auto-close floating window until I've entered all parameters
    hint_enable = false, -- do not show virtual text hint
    hint_prefix = "-> ", -- point at the current parameter, when it's present
    handler_opts = {
        border = "none",
    },
})
local cmp = require("cmp") -- TODO event listening
cmp.setup({
    mapping = {
        ["<Tab>"] = function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end,
        ["<S-Tab>"] = function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end,
        ["<CR>"] = function(fallback)
            if cmp.visible() then
                cmp.confirm({
                    behavior = cmp.ConfirmBehavior.Replace, -- do not reinsert the text of the completion you've already typed when you confirm
                    select = true, -- <CR> accepts first completion
                })
            else
                fallback()
            end
        end,
        ["<C-Up>"] = function(fallback)
            if cmp.visible() then
                cmp.scroll_docs(-4)
            else
                fallback()
            end
        end,
        ["<C-Down>"] = function(fallback)
            if cmp.visible() then
                cmp.scroll_docs(4)
            else
                fallback()
            end
        end,
    },
    sources = {
        {name = "nvim_lsp"},
        {name = "buffer"},
    },
})
local lspconfig = require("lspconfig")
local servers = {"sumneko_lua", "pyright", "clangd", "gopls"}
for _, v in pairs(servers) do
    lspconfig[v].setup({
        capabilities = vim.tbl_extend("force", lspconfig.util.default_config.capabilities, require("cmp_nvim_lsp").default_capabilities()),
    })
end
require("mason").setup()
require("nvim-treesitter.configs").setup({
    ensure_installed = {"lua", "python"}, --parsers
    indent = {enable = true},
    --highlight = {enable = true}, --"I get query error: invalid node type at position" paragraph. Syntax highlighting 
})
require("nvim-tree").setup({
    open_on_setup_file = true, -- focus on file window rather than nvim-tree
    view = {
        relativenumber = true,
        number = true,
    },
    renderer = {
        highlight_opened_files = "names",
        icons = {-- To disable the display of icons see |renderer.icons.show|
            show = {
                git = true,
                folder = false,
                file = false,
                folder_arrow = false,
            },
        },
    },
    diagnostics = {
        enable = true,
        icons = {
            hint = "H",
            info = "I",
            warning = "W",
            error = "E",
        },
    },
})
-- config centered on github copilot
local options = { -- TODO negative scrolloff
    cursorline = true,
    cursorlineopt = "screenline",
    filetype = "on", --turned on filetype detection
    foldmethod = "expr",
    foldexpr = "nvim_treesitter#foldexpr()",
    foldnestmax = 1,
    clipboard = vim.opt.clipboard + "unnamedplus" + "unnamed", --xclip required
    expandtab = true,
    hlsearch = false,
    iskeyword = vim.opt.iskeyword + "-" + "_",
    number = true,
    pumheight = 7,
    relativenumber = true,
    scrolloff = 999,
    shiftwidth = 4, -- Number of spaces to use for each step of (auto)indent
    showmode = false,
    smartindent = true, -- Do smart autoindenting when starting a new line
    softtabstop = 4, -- Number of spaces that a <Tab> counts for while performing editing operations
    tabstop = 4, -- Number of spaces that a <Tab> in the file counts for
    updatetime = 200,
}
for k, v in pairs(options) do
    vim.opt[k] = v
end
local globals = {
    tagbar_show_linenumbers = 2, -- show relative line numbers in tagbar window
    copilot_no_tab_map = true,
    tagbar_show_tag_linenumbers = 1, -- show in which line the tag is in the code
    tagbar_show_visibility = 1, -- show whether a tag is Publ, Priv or Prot
    tagbar_visibility_symbols = {
        public = "PUBL ",
        protected = "PROT ",
        private = "PRIV ",
    }
}
for k, v in pairs(globals) do
    vim.g[k] = v
end
local speed_coding = {"q", "w", "qa", "wa", "q!", "w!", "qa!", "wa!"} -- TODO define commands
-- partiallly accept GitHub copilot suggestion, word by word.
local function partiallyAccept()
    local _ = vim.fn['copilot#Accept']("")
    local suggestion = vim.fn['copilot#TextQueuedForInsertion']()
    return vim.fn.split(suggestion,  [[[ .\(\)\\\/]\zs]])[1] -- stop accepting the word/completion when we run into : dot, space, parenthesis, slash, backslash
end

local function smartIndent()
    local currLine, currCol = unpack(vim.api.nvim_win_get_cursor(0))
    --! => nore
    vim.api.nvim_command("normal! gg=G")
    vim.api.nvim_command("normal! " .. currLine .. "G")
end


function updateLSP(path, depth)
    if depth == 0 then
        return
    end
    for file in lfs.dir(path) do 
        local f = path..'/'..file
        if file ~= "." and file ~= ".." and lfs.attributes(f).mode ~= "directory" then
            vim.cmd("vs " .. file)
            vim.cmd("close")
        end
    end
    vim.cmd("NvimTreeRefresh")
end
local all_filetypes = {"*.lua", "*.py", "*.c", "*.cpp", "*.h", "*.hpp", "*.go", "*.html"}

function echoDoc() -- vim.api.nvim_buf_call(bufid, function)
    vim.api.nvim_command(":normal! ggcG")
end

function echoDef(cmd)
    local currWin = vim.api.nvim_get_current_win()
    local currLine, currCol = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_set_current_win(def_win_id)
    vim.api.nvim_command(":buffer ".. currFilePath)
    vim.api.nvim_command("normal! zR")
    vim.api.nvim_command("normal! " .. currLine .. "G")
    vim.api.nvim_command("normal! 0")
    vim.api.nvim_command("normal! " .. currCol .. "l")
    vim.api.nvim_command(cmd)
    --vim.api.nvim_command("set scrolloff=0")
    --vim.api.nvim_command("normal! zt")
    ----vim.api.nvim_command(":MoveBufferLeft")
    --vim.api.nvim_set_current_win(currWin)
end

-- TODO indent mode
local keymaps = { -- :h modes
    {"n", "gy", function()
        echoDef(":lua vim.lsp.buf.type_definition()")
    end, {}},
    {"n", "gr", vim.lsp.buf.references, {}},
    {"n", "gd", function()
        echoDef(":lua vim.lsp.buf.definition()")
    end, {}},
    {"n", "K", vim.lsp.buf.hover, {}},
    {"i", "<C-c>", 'copilot#Accept("<C-c>")', {silent = true, expr = true}},
    {"nv", "<c-w>", "<cmd>:lua require('nvim-window').pick()<CR>", {}},
    {"nv", "<leader>p", '"+p', {noremap=true}}, --xclip?
    {"nv", "<leader>y", '"+y', {noremap=true}},
    {"nv", "c", '"_c', {noremap=true}},
    {"nv", "d", '"_d', {noremap=true}},
    {"nv", "x", '"_x', {noremap=true}},
    {"i", "<c-l>", partiallyAccept, {expr=true}},
    {"n", "<c-f>", smartIndent, {}},
    {"n", "<c-d>", function()
        updateLSP(lfs.currentdir(), 1)
        vim.api.nvim_command("Trouble workspace_diagnostics")
    end, {}},
    {"nov", "F" , "<Plug>(easymotion-Fl)", {}},
    {"nov", "T" , "<Plug>(easymotion-Tl)", {}},
    {"nov", "t" , "<Plug>(easymotion-tl)", {}},
    {"nov", "f" , "<Plug>(easymotion-fl)", {}},

}

local function keymap(modes, key, value, opts)
    for i=1, string.len(modes) do
        local mode = string.sub(modes, i, i)
        vim.keymap.set(mode, key, value, opts)
    end
end

for _, v in pairs(keymaps) do
    keymap(unpack(v))
end

local all_buf_ids = vim.api.nvim_list_bufs()
def_buf_id = 0
def_win_id = 0
doc_buf_id = 0
doc_win_id = 0
currFilePath = ""
-- TODO create a function which saves the buf id of the new window and run a command, and refresh all_buf_ids list, nvim_del_autocmd
-- TODO as source buffer the doc_buf_id, catch exit event
local autocmds = { -- TOSEE https://stackoverflow.com/questions/3837933/autowrite-when-changing-tab-in-vim
    -- TODO check if NvimTree window is alone then quit. 
    {{"TabNew"}, {pattern = all_filetypes, callback= function()
        vim.api.nvim_command("TagbarOpen")
    end}},
    {{"TabNew"}, {pattern = "*", command=":NvimTreeOpen"}},
    --{{"VimEnter"}, {pattern =  all_filetypes, command=":NvimTreeOpen"}},
    {{"VimEnter"}, {pattern =  all_filetypes, callback= function()
        vim.api.nvim_command(":NvimTreeFocus")
        vim.cmd.split()
        vim.api.nvim_command(":wincmd j")
        vim.api.nvim_command(":e doc_win")
        doc_buf_id = vim.api.nvim_get_current_buf()
        doc_win_id = vim.api.nvim_get_current_win()
        --print(doc_buf_id, doc_win_id)
    end}},
    {{"VimEnter"}, {pattern = all_filetypes, callback= function()
        vim.api.nvim_command("TagbarOpen fj")
        vim.cmd.split()
        vim.api.nvim_command(":wincmd j")
        vim.api.nvim_command(":e def_win")
        def_buf_id = vim.api.nvim_get_current_buf()
        def_win_id = vim.api.nvim_get_current_win()
        vim.api.nvim_command("wincmd h")
        --print(def_buf_id, def_win_id)
    end}},
    {{"CursorHoldI"}, {pattern = all_filetypes, command=":TagbarForceUpdate"}},
    {{"CursorHold"}, {pattern = all_filetypes, callback = function()
        currFilePath = vim.api.nvim_buf_get_name(0)
    end}},
}
for _, v in pairs(autocmds) do
    vim.api.nvim_create_autocmd(unpack(v))
end
