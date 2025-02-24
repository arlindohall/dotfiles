-- According to LazyVim docs, don't set plugin.config
--
-- I don't know if that means this for sure, but I think I shouln't do the normal `return { "my-plugin" = {...} }`
-- pattern here because it would break LazyVim itself.
--
-- However, I've kept the pattern because...
-- 1. It seems right
-- 2. It works so kinda who cares
-- 3. I was getting errors with the way before this one
--
-- https://www.lazyvim.org/plugins/formatting#confomnvim
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
      },
    },
  },
}
