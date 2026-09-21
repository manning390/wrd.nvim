local help_window = require("wrd.help_window")

describe("help window", function()
	it("uses a non-focusable disposable buffer without leaving the picker window", function()
		local origin_win = vim.api.nvim_get_current_win()
		local window = help_window.open({ "Wrd help", "q closes" })
		local help_bufnr = window.bufnr

		assert.is_true(window.is_open())
		assert.are.equal(origin_win, vim.api.nvim_get_current_win())
		assert.are.equal("nofile", vim.bo[help_bufnr].buftype)
		assert.is_false(vim.bo[help_bufnr].modifiable)
		assert.is_false(vim.bo[help_bufnr].swapfile)

		window.close(true)

		assert.is_false(window.is_open())
		assert.are.equal(origin_win, vim.api.nvim_get_current_win())
		assert.is_false(vim.api.nvim_buf_is_valid(help_bufnr))
	end)

	it("closes when its parent picker buffer is wiped", function()
		local parent = vim.api.nvim_create_buf(false, true)
		local window = help_window.open({ "Wrd help" }, { parent_bufnr = parent })

		vim.api.nvim_buf_delete(parent, { force = true })

		assert.is_false(window.is_open())
	end)
end)
