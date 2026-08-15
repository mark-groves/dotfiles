local tokyo = require("config.tokyo-night")

vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
  callback = function()
    tokyo.apply()
  end,
})
