-- Leetcode auto runner

local overseer = require("overseer")

overseer.register_template({
	name = "Test C++ file",
	builder = function(_)
		local file = vim.api.nvim_buf_get_name(0)
		local out = vim.fn.fnamemodify(file, ":p:h") .. "/a.out"

		return {
            name = "Test " .. file,
			cmd = { "sh", "-c" },
			args = {
				table.concat({
					"clang++ -std=c++23 -g -O2 -fsanitize=address,undefined -o " .. out .. " " .. file,
					out,
				}, " && "),
			},
			components = {
				"default",
				"on_result_notify",
			},
		}
	end,
	condition = {
		callback = function()
			return vim.bo.filetype == "cpp"
		end,
	},
})
