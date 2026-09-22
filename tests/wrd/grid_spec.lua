local grid = require("wrd.grid")

local function results(count)
	local values = {}
	for rank = 1, count do
		values[rank] = { word = "word" .. rank, rank = rank, parts_of_speech = {}, definitions = {} }
	end
	return values
end

describe("grid presentation model", function()
	it("packs results down columns like OneLook", function()
		local rows = grid.pack(results(10), 3)

		assert.are.equal(4, #rows)
		assert.are.same({ 1, 5, 9 }, vim.tbl_map(function(value) return value.rank end, rows[1].cells))
		assert.are.same({ 4, 8 }, vim.tbl_map(function(value) return value.rank end, rows[4].cells))
	end)

	it("adapts the column count to the available results width", function()
		local state = grid.new(results(20), { columns = 5, cell_width = 18, separator = " │ " }, {})

		assert.are.equal(3, state.set_available_width(65))
		assert.are.equal(5, state.set_available_width(110))
	end)

	it("fuzzy-filters words before repacking cells", function()
		local values = {
			{ word = "alpha", rank = 1 },
			{ word = "beta", rank = 2 },
			{ word = "alphabet", rank = 3 },
		}
		local state = grid.new(values, { columns = 3 }, {})
		local rows = state.rows("alph")

		assert.are.equal(1, #rows)
		assert.are.equal(2, #rows[1].cells)
		assert.are.equal("alpha", rows[1].cells[1].word)
		assert.are.equal("alphabet", rows[1].cells[2].word)
	end)

	it("changes the active result without changing its visual row", function()
		local opts = { target = { kind = "word" } }
		local state = grid.new(results(6), { columns = 2 }, opts)
		local entry = state.make_entry(state.rows("")[1])

		assert.are.equal(1, entry.wrd.rank)
		state.activate(entry, 2)
		assert.are.equal(4, entry.wrd.rank)
		assert.are.equal(opts, entry.wrd.opts)
	end)

	it("does not change the active column while constructing an incomplete final row", function()
		local state = grid.new(results(5), { columns = 2 }, {})
		state.column = 2
		local rows = state.rows("")

		for _, row in ipairs(rows) do
			state.make_entry(row)
		end

		assert.are.equal(2, state.column)
	end)
end)
