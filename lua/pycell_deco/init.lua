--  This code reuses ideas from lukas-reineke/headlines.nvim
local vim = vim
local M = {}

M.dash_namespace = vim.api.nvim_create_namespace "cell_dash_namespace"
M.sign_namespace = "cell_sign_namespace" -- sign group name

-- Minimal configuration: a single color applied everywhere
M.config = {
  -- Single color used for header, cell name and dash
  color = "#1abc9c",
}

M.setup = function(config)
  -- Merge user configuration
  M.config = vim.tbl_deep_extend("force", M.config, config or {})

  -- Version guard: this plugin targets Neovim >= 0.11
  if vim.fn.has("nvim-0.11") ~= 1 then
    vim.schedule(function()
      vim.notify("pycell_deco.nvim requires Neovim 0.11+", vim.log.levels.WARN)
    end)
  end

  -- Define a single highlight group used by all visual elements
  local color = M.config.color
  vim.api.nvim_set_hl(0, "PyCellHL", { fg = color })

  -- Define sign used for cell headers (uses the same highlight)
  pcall(vim.fn.sign_define, "PyCell", { text = "▎", texthl = "PyCellHL" })

  -- Autocommands: attach buffer-local redraws for Python files
  local aug = vim.api.nvim_create_augroup("pycell_deco", { clear = true })

  -- Create buffer-local autocmds when a Python buffer is detected
  vim.api.nvim_create_autocmd("FileType", {
    group = aug,
    pattern = "python",
    callback = function(args)
      local buf = args.buf
      -- Initial draw
      M.refresh(buf, vim.api.nvim_get_current_win())

      -- Redraw on relevant events for this buffer
      local events = {
        "BufWinEnter",
        "TextChanged",
        "TextChangedI",
        "InsertLeave",
        "WinScrolled",
      }
      for _, ev in ipairs(events) do
        vim.api.nvim_create_autocmd(ev, {
          group = aug,
          buffer = buf,
          callback = function()
            M.refresh(buf, vim.api.nvim_get_current_win())
          end,
        })
      end
    end,
  })
end


M.refresh = function(bufnr, winid)
  -- Determine target buffer/window
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  winid = winid or vim.api.nvim_get_current_win()

  -- Only run for Python buffers
  if vim.bo[bufnr].filetype ~= "python" then return end

  -- Clear previous signs and extmarks
  vim.fn.sign_unplace(M.sign_namespace, { buffer = bufnr })
  vim.api.nvim_buf_clear_namespace(bufnr, M.dash_namespace, 0, -1)

  local cell_pattern = "^ *# %%+"
  local sign_name = "PyCell"

  -- Work on visible window range for performance
  local offset = math.max(vim.fn.line "w0" - 1, 0)
  local last = math.min(vim.fn.line "w$", vim.api.nvim_buf_line_count(bufnr))
  local lines = vim.api.nvim_buf_get_lines(bufnr, offset, last, false)

  -- Determine target width: prefer 'textwidth', fallback to window width
  local width = vim.api.nvim_get_option_value("textwidth", { buf = bufnr })
  if width == 0 then
    width = vim.api.nvim_win_get_width(winid)
  end

  -- Use the same highlight group for all rendered parts
  local cell_hl = "PyCellHL"

  for i = 1, #lines do
    local s_cell, e_cell = lines[i]:find(cell_pattern)
    if e_cell then
      -- 1) Place sign at the header line
      vim.fn.sign_place(0, M.sign_namespace, sign_name, bufnr, { lnum = i + offset })

      -- 2) Highlight the entire header line, including any cell name
      --    Using the same highlight for consistent appearance.
      vim.api.nvim_buf_set_extmark(bufnr, M.dash_namespace, i - 1 + offset, 0, {
        hl_group = cell_hl,
        end_row = i - 1 + offset,
        end_col = #lines[i], -- highlight to the end of the line
        hl_mode = "combine",
      })

      -- 3) Draw the dash line to the right edge (same color)
      local n_dash = math.max(width - vim.fn.strdisplaywidth(lines[i]) - 1, 0)
      if n_dash > 0 then
        vim.api.nvim_buf_set_extmark(bufnr, M.dash_namespace, i - 1 + offset, 0, {
          virt_text = { { ("—"):rep(n_dash), cell_hl } },
          hl_mode = "combine",
        })
      end
    end
  end
end

return M
