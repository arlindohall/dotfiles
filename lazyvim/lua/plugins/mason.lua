local function debug_print(_msg)
  -- print(_msg)
end

local function in_world_monorepo(path)
  return path and string.find(path, "world/trees") ~= nil
end

local function wrap_cmd_bundle_exec(cmd, root_dir)
  if in_world_monorepo(root_dir) then
    local wrapped = { "bundle", "exec" }
    for _, arg in ipairs(cmd) do
      table.insert(wrapped, arg)
    end
    debug_print("[LSP DEBUG] World detected! Wrapping with bundle exec: " .. vim.inspect(wrapped))
    return wrapped
  end
  debug_print("[LSP DEBUG] Not in World, using plain command: " .. vim.inspect(cmd))
  return cmd
end

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "prettier",
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
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
        rust = { "rustfmt" },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Ruby-lsp doesn't have a setup callback because it doesn't work (not sure why),
        -- but it *DOES* need to be installed with `gem install ruby_lsp` in Core to work,
        -- again, not really sure why but it works.
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
      setup = {
        sorbet = function(_, opts)
          debug_print("[LSP DEBUG] Setting up sorbet")
          local lspconfig = require("lspconfig")

          opts.on_new_config = function(config, root_dir)
            debug_print("[LSP DEBUG] sorbet on_new_config called with root_dir: " .. (root_dir or "nil"))
            config.cmd_cwd = root_dir
            config.cmd = wrap_cmd_bundle_exec({ "srb", "tc", "--lsp" }, root_dir)
          end

          lspconfig.sorbet.setup(opts)
          return true -- Prevent default setup
        end,
        rubocop = function(_, opts)
          debug_print("[LSP DEBUG] Setting up rubocop")
          local lspconfig = require("lspconfig")

          opts.on_new_config = function(config, root_dir)
            debug_print("[LSP DEBUG] rubocop on_new_config called with root_dir: " .. (root_dir or "nil"))
            config.cmd_cwd = root_dir
            config.cmd = wrap_cmd_bundle_exec({ "rubocop", "--lsp" }, root_dir)
          end

          lspconfig.rubocop.setup(opts)
          return true -- Prevent default setup
        end,
      },
    },
  },
}
