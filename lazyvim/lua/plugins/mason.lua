-- Function to check if 'bundle exec' works in the current working directory
local function is_bundle_exec_available(cwd)
  local result = vim.fn.trim(vim.fn.system("cd " .. cwd .. " && bundle exec ruby -v"))
  return vim.v.shell_error == 0 and result ~= ""
end

local function get_ruby_cmd(cmd)
  local cwd = vim.fn.getcwd()
  local result = {}
  if is_bundle_exec_available(cwd) then
    result = { "bundle", "exec" }
  end

  for _, v in ipairs(cmd) do
    table.insert(result, v)
  end

  return result
end

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
          cmd = get_ruby_cmd({ "ruby-lsp" }),
          filetypes = { "ruby" },
        },
        sorbet = {
          mason = false,
          cmd = get_ruby_cmd({ "srb", "tc", "--lsp" }),
          init_options = {
            enableTypedFalseCompletionNudges = true,
          },
          filetypes = { "ruby" },
        },
        rubocop = {
          mason = false,
          cmd = get_ruby_cmd({ "rubocop", "--lsp" }),
          filetypes = { "ruby" },
        },
      },
    },
  },
}
