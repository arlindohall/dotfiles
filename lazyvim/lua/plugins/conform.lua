-- According to LazyVim docs, don't set plugin.config
--
-- I don't know if that means this for sure, but I think I shouln't do the normal `return { "my-plugin" = {...} }`
-- pattern here because it would break LazyVim itself, so I'm sticking with this because:
-- 1. It seems right
-- 2. It works so kinda who cares
--
-- https://www.lazyvim.org/plugins/formatting#confomnvim
require("conform").setup({
  formatters_by_ft = {
    javascript = { "prettier" },
    typescript = { "prettier" },
  },
})
