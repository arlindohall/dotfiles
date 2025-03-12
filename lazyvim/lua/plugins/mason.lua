return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "prettier",
        "ruby-lsp",
        "rubocop",
        "sorbet",
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
  },
  {
    "neovim/nvim-lspconfig",
  },
}
