local selection = require("wrd.selection")

describe("selection targets", function()
	local bufnr

	before_each(function()
		bufnr = vim.api.nvim_create_buf(false, true)
		vim.bo[bufnr].modifiable = true
	end)

	after_each(function()
		if vim.api.nvim_buf_is_valid(bufnr) then
			vim.api.nvim_buf_delete(bufnr, { force = true })
		end
	end)

	it("finds the keyword containing the cursor and not adjacent whitespace", function()
		assert.are.same({ 8, 14 }, { selection.word_bounds("replace cheese now", 10) })
		assert.is_nil(selection.word_bounds("replace cheese now", 7))
	end)

	it("builds an inclusive characterwise visual range", function()
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "aged cheese" })

		local target = selection.visual_target(bufnr, nil, { 1, 1 }, { 1, 4 }, "v")

		assert.are.equal("range", target.kind)
		assert.are.equal("aged", selection.text(target))
	end)

	it("replaces a captured word range", function()
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "aged cheese" })
		local target = {
			bufnr = bufnr,
			kind = "word",
			start_row = 0,
			start_col = 5,
			end_row = 0,
			end_col = 11,
		}

		assert.is_true(selection.apply(target, "cheddar"))
		assert.are.same({ "aged cheddar" }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
	end)

	it("inserts at an empty target without deleting surrounding text", function()
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "say  please" })
		local target = {
			bufnr = bufnr,
			kind = "insert",
			start_row = 0,
			start_col = 4,
			end_row = 0,
			end_col = 4,
		}

		assert.is_true(selection.apply(target, "cheese"))
		assert.are.same({ "say cheese please" }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
	end)

	it("replaces complete selected lines", function()
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "one", "two", "three" })
		local target = selection.line_target(bufnr, nil, 1, 2)

		assert.is_true(selection.apply(target, "combined"))
		assert.are.same({ "combined", "three" }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
	end)

	it("leaves block selections and unmodifiable buffers untouched", function()
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "cheese" })
		assert.is_false(selection.apply({ bufnr = bufnr, kind = "block" }, "curd"))

		vim.bo[bufnr].modifiable = false
		assert.is_false(selection.apply({ bufnr = bufnr, kind = "insert" }, "curd"))
		assert.are.same({ "cheese" }, vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
	end)
end)
