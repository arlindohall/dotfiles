return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "prettier",
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruby_lsp = {
          mason = false,
          cmd = { "bundle", "exec", "ruby-lsp" },
          filetypes = { "ruby" },
        },
        sorbet = {
          mason = false,
          cmd = { "bundle", "exec", "srb", "tc", "--lsp" },
          init_options = {
            enableTypedFalseCompletionNudges = true,
          },
          filetypes = { "ruby" },
        },
        rubocop = {
          mason = false,
          cmd = { "bundle", "exec", "rubocop", "--lsp" },
          filetypes = { "ruby" },
        },
      },
    },
  },
}
