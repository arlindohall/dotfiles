-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

local function relative_filename()
  local filename = vim.fn.expand("%:p"):gsub("\\", "/")
  local cwd = vim.fn.getcwd()
  return filename:gsub("^" .. cwd:gsub("\\", "/") .. "/", "")
end

local function filename_relative_to_git()
  vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel"))

  -- Check if the command was successful (i.e., we are in a Git repository)
  if vim.v.shell_error ~= 0 then
    -- If not in a Git repo, fallback to relative to the current directory
    relative_filename()
  end

  local filename = vim.fn.expand("%:p"):gsub("\\", "/")
  return vim.fn.trim(vim.fn.system("git ls-files --full-name " .. filename))
end

local function copy_filename_to_register(type)
  return function()
    local filename_types = {
      relative = relative_filename(),
      absolute = vim.fn.expand("%:p"),
      from_git_root = filename_relative_to_git(),
    }

    local filename = filename_types[type] or relative_filename()
    print(
      "Determined filename to be type="
        .. type
        .. " filename="
        .. filename
        .. " is_fallback="
        .. tostring(filename_types[type] == nil)
    )

    vim.fn.setreg("@", filename)
    vim.fn.setreg("*", filename)
    vim.fn.setreg("+", filename)
    print("Copied filename to @ register: " .. filename)
  end
end

vim.api.nvim_create_user_command("CopyGitFilename", copy_filename_to_register("from_git_root"), {})
vim.api.nvim_create_user_command("CopyRelativeFilename", copy_filename_to_register("relative"), {})
vim.api.nvim_create_user_command("CopyAbsoluteFilename", copy_filename_to_register("absolute"), {})

vim.api.nvim_set_keymap("n", "<leader>gg", ":CopyGitFilename<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>gr", ":CopyRelativeFilename<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>ga", ":CopyAbsoluteFilename<CR>", { noremap = true, silent = true })
