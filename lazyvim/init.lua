-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

local function copy_filename_relative_to_git()
  -- Get the Git root directory
  local _git_root = vim.fn.trim(vim.fn.system("git rev-parse --show-toplevel"))
  local filename = vim.fn.expand("%:p"):gsub("\\", "/")

  -- Check if the command was successful (i.e., we are in a Git repository)
  if vim.v.shell_error ~= 0 then
    -- If not in a Git repo, fallback to relative to the current directory
    local cwd = vim.fn.getcwd()
    return filename:gsub("^" .. cwd:gsub("\\", "/") .. "/", "")
  end

  -- If in a Git repo, compute the filename relative to the Git root
  return vim.fn.trim(vim.fn.system("git ls-files --full-name " .. filename))
end

-- Define the function to copy the current filename to the @ register
local function copy_filename_to_register()
  local relative_filename = copy_filename_relative_to_git() -- Get the relative filename
  vim.fn.setreg("@", relative_filename) -- Set the @ register to the relative filename
  vim.fn.setreg("*", relative_filename) -- Set the * register to the relative filename
  vim.fn.setreg("+", relative_filename) -- Set the + register to the relative filename
  print("Copied filename to @ register: " .. relative_filename) -- Optional confirmation message
end

local function copy_filename_relative_to_cwd_to_register()
  local relative_filename = vim.fn.expand("%")
  vim.fn.setreg("@", relative_filename) -- Set the @ register to the relative filename
  vim.fn.setreg("*", relative_filename) -- Set the * register to the relative filename
  vim.fn.setreg("+", relative_filename) -- Set the + register to the relative filename
  print("Copied filename to @ register: " .. relative_filename) -- Optional confirmation message
end

-- Create a command that can be called from the key mapping
vim.api.nvim_create_user_command("CopyFilename", copy_filename_to_register, {})
vim.api.nvim_create_user_command("CopyRelativeFilename", copy_filename_relative_to_cwd_to_register, {})

-- Map <leader>gl to the CopyFilename command
vim.api.nvim_set_keymap("n", "<leader>ga", ":CopyFilename<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>gr", ":CopyRelativeFilename<CR>", { noremap = true, silent = true })
