local function run_python_smart()
	-- 1. Get the file path, directory, and Python command
	local file_path = vim.fn.expand("%:p")
	local file_dir = vim.fn.fnamemodify(file_path, ":h") -- Directory of the current file
	local conda_prefix = os.getenv("CONDA_PREFIX")
	local python_cmd = "python"

	if conda_prefix and #conda_prefix > 0 then
		python_cmd = conda_prefix .. "/bin/python"
	end

	-- The command to execute the script
	local exec_cmd = string.format("%s %s", python_cmd, vim.fn.shellescape(file_path))

	-- 2. Check if Neovim is running inside a Tmux session
	local is_in_tmux = os.getenv("TMUX")

	if is_in_tmux then
		-- OPTION A: Run in Tmux (Best for long services/large output)

		-- The Tmux command: split horizontally, set directory, run script, stay in bash
		-- '-c' sets the new pane's path, and we prepend 'cd' for robust directory change
		local tmux_exec = string.format("cd %s && %s; zsh", vim.fn.shellescape(file_dir), exec_cmd)

		-- The full shell command to send to Tmux
		-- Using 'split-window -h' for horizontal split (side-by-side)
		local tmux_cmd = string.format('silent !tmux split-window -h -c \\"\\#{pane_current_path}\\" "%s"', tmux_exec)

		vim.cmd(tmux_cmd)
	else
		-- OPTION B: Run in Neovim internal terminal (Suitable for short scripts)

		-- Neovim command: vsplit on the right, change directory for the current pane, then run the terminal
		-- Note: Changing cwd for the terminal pane in Nvim is complex.
		-- The robust way is to run 'cd' inside the terminal before the script.
		local nvim_cmd = string.format("vert rightbelow terminal cd %s && %s", vim.fn.shellescape(file_dir), exec_cmd)

		vim.cmd(nvim_cmd)
	end
end

-- Map the function to <leader>r
vim.keymap.set("n", "<leader>r", run_python_smart, { desc = "Run Python File (Tmux/Nvim Split)" })
