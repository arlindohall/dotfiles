return {
  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
  -- configure catppuccin to use Mocha theme
  {
    "catppuccin/nvim",
    opts = {
      flavor = "mocha",
    },
    config = function() end,
  },
}
