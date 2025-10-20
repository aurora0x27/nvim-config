-- Leetcode auto runner

function OpenFloatingTerminal(command)
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.6)
	local row = (vim.o.lines - height) / 2
	local col = (vim.o.columns - width) / 2

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		border = "rounded",
		style = "minimal",
	})

	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
	vim.api.nvim_set_option_value("winhighlight", "NormalFloat:NormalFloat,FloatBorder:FloatBorder", { win = win })

	local job_id = vim.fn.jobstart({ "sh", "-c", command }, { term = true, cwd = vim.fn.getcwd() })
	if job_id <= 0 then
		vim.notify("Failed to start job: " .. command, vim.log.levels.ERROR)
	end

	vim.keymap.set("n", "q", function()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end, { buffer = buf, nowait = true, silent = true })

	vim.keymap.set("t", "q", [[<C-\><C-n>:lua vim.api.nvim_win_close(]] .. win .. [[, true)<CR>]], {
		buffer = buf,
		nowait = true,
		silent = true,
	})

	vim.cmd("startinsert")
end

vim.api.nvim_create_user_command("Test", function()
	vim.cmd("write")
	local full_path = vim.fn.expand("%:p")
	OpenFloatingTerminal("clang++ -g -O2 -o a.out " .. full_path .. " && ./a.out")
end, {})
