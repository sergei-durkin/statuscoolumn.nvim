local utils = require("statuscoolumn.utils")

local statuscolumn = {}

local catppuccino_macchiato = {
  cursorline = {
    bg = "#383838",
  },

  number = {
    normal = "#606684",
    accent = "#B9C4F8",
  },

  diagnostics = {
    error = "#FF6188",
    warning = "#FFCA80",
    info = "#A9DC76",
    hint = "#76E3EA",
  },

  git = {
    added = "#A6DA95",
    modified = "#EED4A0",
    removed = "#ED8796",
  },

  git_staged = {
    added = "#5A7C61",
    modified = "#467C7B",
    removed = "#7F605C",
  },
}

statuscolumn.config = {
  number = {
    type = "hybrid",
  },

  border = {
    enabled = true,
    text = "│",
  },

  fold = {
    enabled = true,
    text = {
      opened = "",
      closed = "",
      scope = " ",
    },
  },

  colors = catppuccino_macchiato,
}

statuscolumn.setHl = function()
  local colors = statuscolumn.config.colors
  local cursor_bg = colors.cursorline and colors.cursorline.bg or nil

  local function set_pair(name, fg)
    vim.api.nvim_set_hl(0, name, { fg = fg })
    vim.api.nvim_set_hl(0, name .. "Cursor", { fg = fg, bg = cursor_bg })
  end

  set_pair("StatusColumnNumbers", colors.number.normal)
  set_pair("StatusColumnNumbersAccent", colors.number.accent)

  set_pair("LspDiagnosticsSignError", colors.diagnostics.error)
  set_pair("LspDiagnosticsSignWarning", colors.diagnostics.warning)
  set_pair("LspDiagnosticsSignInformation", colors.diagnostics.info)
  set_pair("LspDiagnosticsSignHint", colors.diagnostics.hint)

  set_pair("GitSignsAdd", colors.git.added)
  set_pair("GitSignsChange", colors.git.modified)
  set_pair("GitSignsDelete", colors.git.removed)

  set_pair("GitSignsStagedAdd", colors.git_staged.added)
  set_pair("GitSignsStagedChange", colors.git_staged.modified)
  set_pair("GitSignsStagedDelete", colors.git_staged.removed)
end

statuscolumn.hl = function(name)
  if name and vim.v.lnum == vim.fn.line(".") then
    return name .. "Cursor"
  end
  return name
end

statuscolumn.fold = function(cfg)
  local _output = ""

  local foldlvl_before = vim.fn.foldlevel((vim.v.lnum - 1) >= 1 and (vim.v.lnum - 1) or 1)
  local foldlvl_current = vim.fn.foldlevel(vim.v.lnum)
  local foldlvl_after = vim.fn.foldlevel((vim.v.lnum + 1) <= vim.fn.line("$") and (vim.v.lnum + 1) or vim.fn.line("$"))

  local foldclosed = vim.fn.foldclosed(vim.v.lnum)

  if type(cfg.hl.default) == "string" then
    _output = "%#" .. cfg.hl.default .. "#"
  end

  if foldlvl_current == 0 then
    _output = type(cfg.space) == "string" and _output .. cfg.space or _output .. " "

    return _output
  end

  if foldclosed ~= -1 and foldclosed == vim.v.lnum then
    _output = type(cfg.hl.closed) == "string" and _output .. "%#" .. cfg.hl.closed .. "#" or _output
    _output = type(cfg.text.closed) == "string" and _output .. cfg.text.closed or _output .. "-"

    return _output
  end

  if foldlvl_current > foldlvl_before then
    _output = type(cfg.hl.opened) == "string" and _output .. "%#" .. cfg.hl.opened .. "#" or _output
    _output = type(cfg.text.opened) == "string" and _output .. cfg.text.opened or _output .. "+"

    return _output
  end

  _output = type(cfg.hl.scope) == "string" and _output .. "%#" .. cfg.hl.scope .. "#" or _output
  _output = type(cfg.text.scope) == "string" and _output .. cfg.text.scope or _output .. " "

  return _output
end

statuscolumn.number = function(cfg)
  local _output, _color = "", ""

  if cfg.icon and cfg.icon.text then
    local _icon = utils.icon(cfg.icon)
    _output = "%=" .. _icon
    return _output
  end

  if cfg.mode == "normal" then
    _output = vim.v.lnum
  end

  if cfg.mode == "relative" then
    _output = vim.v.relnum
  end

  if cfg.mode == "hybrid" then
    _output = vim.v.relnum == 0 and vim.v.lnum or vim.v.relnum
  end

  _color = type(cfg.hl) == "string" and "%#" .. cfg.hl .. "#" or ""
  if cfg.current_line_hl and vim.v.lnum == vim.fn.line(".") then
    _color = "%#" .. cfg.current_line_hl .. "#"
  end

  return _color ~= "" and _color .. "%=%{" .. _output .. "}" or "%=%{ " .. _output .. "}"
end

statuscolumn.gap = function(cfg)
  local _output = ""

  if type(cfg.hl) == "string" then
    _output = "%#" .. cfg.hl .. "#"
  end

  _output = _output .. cfg.text

  return _output
end

statuscolumn.border = function(cfg)
  if type(cfg.hl) == "string" then
    return "%#" .. cfg.hl .. "#" .. cfg.text
  end

  return cfg.text
end

statuscolumn.render = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local signs = utils.get_signs(bufnr, vim.v.lnum)
  local git_sign, number_icon

  for _, s in ipairs(signs) do
    if s.name and s.name:find("Git") then
      git_sign = utils.icon(s)
    else
      number_icon = s
    end
  end

  local numbers_hl = statuscolumn.hl("StatusColumnNumbers")
  local accent_hl = statuscolumn.hl("StatusColumnNumbersAccent")

  return table.concat({
    -- render gitsigns
    git_sign or statuscolumn.gap({
        hl = numbers_hl,
        text = " ",
      }),

    statuscolumn.gap({
      hl = numbers_hl,
      text = " ",
    }),

    -- render number
    statuscolumn.number({
      hl = numbers_hl,
      current_line_hl = accent_hl,
      mode = statuscolumn.config.number.type,
      right_align = true,
      icon = number_icon,
    }),

    statuscolumn.gap({
      hl = numbers_hl,
      text = " ",
    }),

    -- render fold
    statuscolumn.config.fold.enabled
        and statuscolumn.fold({
          hl = {
            default = numbers_hl,
            opened = numbers_hl,
            closed = numbers_hl,
            scope = numbers_hl,
          },
          text = statuscolumn.config.fold.text,
        })
      or "",

    statuscolumn.gap({
      hl = numbers_hl,
      text = " ",
    }),

    -- render border
    statuscolumn.config.border.enabled
        and statuscolumn.border({
          text = statuscolumn.config.border.text,
        })
      or "",
  })
end

statuscolumn.setup = function(cfg)
  if cfg then
    statuscolumn.config = vim.tbl_deep_extend("force", statuscolumn.config, cfg)
  end

  statuscolumn.setHl()

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("StatusColumnHighlights", { clear = true }),
    callback = statuscolumn.setHl,
  })

  vim.o.statuscolumn = "%!v:lua.require('statuscoolumn').render()"
end

return statuscolumn
