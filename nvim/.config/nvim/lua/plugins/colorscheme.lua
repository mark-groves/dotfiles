-- Tokyo Night Night or Day from the desktop color-scheme.
local tokyo = require("config.tokyo-night")

return {
  {
    "folke/tokyonight.nvim",
    opts = { style = tokyo.style() },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        tokyo.apply()
      end,
    },
  },
}
