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
  -- 사용자 설정 반영
  M.config = vim.tbl_deep_extend("force", M.config, config or {})

  -- 하이라이트 정의 (원래 쓰던 색을 그대로 사용)
  local guifg = M.config.cell_name_fg
  local bg = M.config.cell_line_bg

  -- 셀 이름/라인에 쓸 하이라이트 그룹 (이름은 예시, 기존 코드와 충돌 없게 자유롭게)
  vim.api.nvim_set_hl(0, "PyCellName", { fg = guifg, bg = bg })
  -- 필요시 대시(—)에 별도 하이라이트를 주고 싶으면 아래처럼 사용
  -- vim.api.nvim_set_hl(0, "PyCellDash", { fg = guifg, bg = bg })

  -- 사인 정의(이미 다른 곳에서 정의했다면 생략 가능)
  -- 파일 상단의 M.sign_namespace = "cell_sign_namespace"에 맞춰 sign 이름을 정의
  -- 여기서는 'cell_name_sign' 텍스트 사인을 예시로 둠
  pcall(vim.fn.sign_define, "PyCell", { text = "▎", texthl = "PyCellName" })

  ------------------------------------------------------------------
  -- 🔹 자동명령(최신 API)
  --   파이썬 버퍼에서 읽기/편집/스크롤 등의 이벤트가 발생하면 다시 그려준다
  ------------------------------------------------------------------
  local aug = vim.api.nvim_create_augroup("pycell_deco", { clear = true })

  vim.api.nvim_create_autocmd(
    { "BufReadPost", "BufWinEnter", "TextChanged", "TextChangedI", "InsertLeave", "WinScrolled" },
    {
      group = aug,
      pattern = "*.py",
      callback = function(args)
        -- refresh는 bufnr를 받도록 되어 있으면 args.buf 전달, 아니면 생략
        -- (아래 refresh 패치에서 bufnr 인자를 받도록 권장)
        local ok, mod = pcall(require, "pycell_deco")
        if ok and type(mod.refresh) == "function" then
          mod.refresh(args.buf)
        end
      end,
    }
  )
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
    local width = vim.api.nvim_get_option_value("textwidth", {buf = bufnr})

    -- textwidth = 0 이면 줄바꿈 기준이 없으니, 창 너비로 대체
    if width == 0 then
    width = vim.api.nvim_win_get_width(0)
    end

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
            local n_dash = math.max(width - vim.fn.strdisplaywidth(lines[i]) - 1, 0)
            vim.api.nvim_buf_set_extmark(bufnr, M.dash_namespace, i - 1 + offset, 0, {
                virt_text = { { ("—"):rep(n_dash) } },
                hl_mode = "combine",
            })
        end
    end
end

return M
