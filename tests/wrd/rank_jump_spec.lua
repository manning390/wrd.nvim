local rank_jump = require("wrd.rank_jump")

local function picker_with(entries)
	local selected_row
	local picker = {
		manager = {
			iter = function()
				local index = 0
				return function()
					index = index + 1
					return entries[index]
				end
			end,
		},
		get_row = function(_, index)
			return index - 1
		end,
		set_selection = function(_, row)
			selected_row = row
		end,
	}

	return picker, function()
		return selected_row
	end
end

describe("rank jump", function()
	it("finds an original rank in the currently visible entries", function()
		local picker = picker_with({
			{ wrd = { rank = 3 } },
			{ wrd = { rank = 17 } },
		})

		assert.are.equal(1, rank_jump.find_row(picker, 17))
		assert.is_nil(rank_jump.find_row(picker, 2))
	end)

	it("moves selection without changing picker entries", function()
		local entries = {
			{ wrd = { rank = 1 } },
			{ wrd = { rank = 9 } },
		}
		local picker, selected_row = picker_with(entries)

		assert.is_true(rank_jump.select(picker, 9))
		assert.are.equal(1, selected_row())
		assert.are.equal(2, #entries)
	end)

	it("selects a rank packed into a grid cell", function()
		local active_column
		local refreshed = false
		local state = {
			activate = function(_, column) active_column = column end,
			refresh = function() refreshed = true end,
		}
		local picker, selected_row = picker_with({
			{
				wrd = { rank = 1 },
				wrd_grid = {
					cells = { { rank = 1 }, { rank = 51 } },
					state = state,
				},
			},
		})

		assert.is_true(rank_jump.select(picker, 51))
		assert.are.equal(2, active_column)
		assert.are.equal(0, selected_row())
		assert.is_true(refreshed)
	end)

	it("commits a single-digit rank after the debounce", function()
		local scheduled
		local committed
		local controller = rank_jump.new({
			schedule = function(_, callback)
				scheduled = callback
			end,
			on_commit = function(rank)
				committed = rank
			end,
		})

		controller.feed("9")
		assert.are.equal("9", controller.pending())
		assert.is_nil(committed)
		scheduled()
		assert.are.equal(9, committed)
		assert.are.equal("", controller.pending())
	end)

	it("commits unambiguous multi-digit ranks immediately", function()
		local committed
		local controller = rank_jump.new({
			schedule = function() end,
			on_commit = function(rank)
				committed = rank
			end,
		})

		controller.feed("1")
		controller.feed("7")
		assert.are.equal(17, committed)
	end)

	it("supports rank 100 and ignores stale debounce callbacks", function()
		local scheduled = {}
		local committed
		local controller = rank_jump.new({
			schedule = function(_, callback)
				table.insert(scheduled, callback)
			end,
			on_commit = function(rank)
				committed = rank
			end,
		})

		controller.feed("1")
		controller.feed("0")
		scheduled[1]()
		assert.is_nil(committed)
		controller.feed("0")
		assert.are.equal(100, committed)
	end)

	it("resolves the ambiguous rank 10 when its latest debounce expires", function()
		local scheduled = {}
		local committed
		local controller = rank_jump.new({
			schedule = function(_, callback)
				table.insert(scheduled, callback)
			end,
			on_commit = function(rank)
				committed = rank
			end,
		})

		controller.feed("1")
		controller.feed("0")
		scheduled[1]()
		assert.is_nil(committed)
		scheduled[2]()
		assert.are.equal(10, committed)
	end)

	it("allows pending input to be committed early", function()
		local committed
		local controller = rank_jump.new({
			schedule = function() end,
			on_commit = function(rank)
				committed = rank
			end,
		})

		controller.feed("1")
		assert.are.equal("1", controller.pending())
		assert.is_true(controller.commit())
		assert.are.equal(1, committed)
	end)

	it("reports zero and out-of-range ranks through the commit callback", function()
		local committed = {}
		local controller = rank_jump.new({
			schedule = function() end,
			on_commit = function(rank)
				table.insert(committed, rank)
			end,
		})

		controller.feed("0")
		controller.feed("1")
		controller.feed("0")
		controller.feed("1")

		assert.are.same({ 0, 101 }, committed)
	end)
end)
