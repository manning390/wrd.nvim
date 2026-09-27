describe("Telescope extension", function()
	it("exports setup, run, and method selection through the public Wrd API", function()
		local original_telescope = package.loaded["telescope"]
		local original_extension = package.loaded["telescope._extensions.wrd"]
		local registered
		package.loaded["telescope"] = {
			register_extension = function(spec)
				registered = spec
				return spec
			end,
		}
		package.loaded["telescope._extensions.wrd"] = nil

		local extension = require("telescope._extensions.wrd")
		local wrd = require("wrd")

		package.loaded["telescope"] = original_telescope
		package.loaded["telescope._extensions.wrd"] = original_extension

		assert.are.equal(extension, registered)
		assert.are.equal(wrd.setup, extension.setup)
		assert.are.equal(wrd.run, extension.exports.run)
		assert.are.equal(wrd.run_methods, extension.exports.methods)
	end)
end)
