local M = {}

function M.style()
  local env = vim.env.TOKYO_NIGHT_STYLE
  if env == "day" or env == "night" then
    return env
  end
  if vim.fn.executable("tokyo-night-style") == 1 then
    local out = vim.fn.trim(vim.fn.system({ "tokyo-night-style" }))
    if out == "day" or out == "night" then
      return out
    end
  end
  return "night"
end

function M.colorscheme()
  return "tokyonight-" .. M.style()
end

function M.apply()
  local name = M.colorscheme()
  if vim.g.colors_name ~= name then
    vim.cmd.colorscheme(name)
  end
end

return M
