--  This code is reusing a lot of codes of lukas-reineke/jeadlines.nvim
local vim = vim
local M = {}

M.dash_namespace = vim.api.nvim_create_namespace "cell_dash_namespace"
M.sign_namespace = "cell_sign_namespace"

M.config = {
    cell_name_fg = "#1abc9c",
    cell_line_bg = nil
}

M.setup = function(config)
    M.config = vim.tbl_deep_extend("force", M.config, config or {})

    local guifg = M.config.cell_name_fg
    local guibg = M.config.cell_line_bg
    if guifg == nil then
        guifg = "NONE"
    end
    if guibg == nil then
        guibg = "NONE"
    end

    local hl_cmd = string.format("highlight PyCell guifg=%s guibg=%s", guifg, guibg)

    vim.cmd(hl_cmd)

    vim.fn.sign_define("PyCell", { linehl = "PyCell" })

    vim.cmd [[augroup PyCell]]
    vim.cmd [[autocmd FileType python, autocmd FileChangedShellPost,Syntax,TextChanged,InsertLeave,WinScrolled * lua require('pycell_deco').refresh()]]
    vim.cmd [[augroup END]]
end

M.refresh = function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.fn.sign_unplace(M.sign_namespace, { buffer = bufnr })
    vim.api.nvim_buf_clear_namespace(0, M.dash_namespace, 1, -1)

    local cell_pattern = "^ *# %%+"
    local sign_name = "PyCell"
    local offset = math.max(vim.fn.line "w0" - 1, 0)
    local range = math.min(vim.fn.line "w$", vim.api.nvim_buf_line_count(bufnr))
    local lines = vim.api.nvim_buf_get_lines(bufnr, offset, range, false)
    local width = vim.api.nvim_get_option("textwidth")

    for i = 1, #lines do
        local _, pos_cell_end = lines[i]:find(cell_pattern)

        if pos_cell_end then
            vim.fn.sign_place(
                0,
                M.sign_namespace,
                sign_name,
                bufnr,
                { lnum = i + offset }
            )
            local n_dash = width - #lines[i] - 1
            vim.api.nvim_buf_set_extmark(bufnr, M.dash_namespace, i - 1 + offset, 0, {
                virt_text = { { ("—"):rep(n_dash) } },
                hl_mode = "combine",
            })
        end
    end
end

return M
