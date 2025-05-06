-- Function to check if 'bundle exec' works in the current working directory
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
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        svelte = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruby_lsp = {
          mason = false,
          cmd = { "ruby-lsp" },
          filetypes = { "ruby" },
        },
        sorbet = {
          mason = false,
          cmd = { "srb", "tc", "--lsp" },
          init_options = {
            enableTypedFalseCompletionNudges = true,
          },
          filetypes = { "ruby" },
        },
        rubocop = {
          mason = false,
          cmd = { "rubocop", "--lsp" },
          filetypes = { "ruby" },
        },
      },
    },
  },
}
