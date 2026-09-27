local M = {}

local factories = {
	list = function(results, opts) return require("wrd.presentations.list").new(results, opts) end,
	grid = function(results, opts) return require("wrd.presentations.grid").new(results, opts) end,
}

function M.new(results, opts)
	local name = ((opts or {}).picker or {}).presentation or "list"
	local factory = factories[name]
	if not factory then
		error(string.format("Wrd Error: Unsupported picker presentation '%s'", tostring(name)))
	end
	return factory(results, opts)
end

return M
