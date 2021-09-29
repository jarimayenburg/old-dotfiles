-------------------------------------
-- My NVIM configuration Lua module
-------------------------------------

local M = {}

function M.setup()
  require("jari.basics").setup()
  require("jari.plugins").setup()
  require("jari.lightline").setup()
  require("jari.lsp").setup()
  require("jari.telescope").setup()
  require("jari.treesitter").setup()
end

return M
