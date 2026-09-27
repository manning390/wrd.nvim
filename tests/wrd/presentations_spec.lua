local presentations = require("wrd.presentations")

describe("picker presentations", function()
	it("builds the configured presentation behind a common interface", function()
		local presentation = presentations.new({ { word = "curd", rank = 1 } }, {
			picker = { presentation = "list" },
		})

		assert.are.equal("function", type(presentation.finder))
		assert.are.equal("function", type(presentation.finder_for))
		assert.are.equal("function", type(presentation.activate))
		assert.are.equal("function", type(presentation.attach))
	end)

	it("rejects unsupported presentation names", function()
		assert.has_error(function()
			presentations.new({}, { picker = { presentation = "unknown" } })
		end, "Wrd Error: Unsupported picker presentation 'unknown'")
	end)
end)
