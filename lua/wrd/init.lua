local ok, telescope = pcall(require, "telescope")

if not ok then
	error("Wrd Error: This plugin requires nvim-telescope/telescope.nvim")
end

local config = require("wrd.config")
local workflow = require("wrd.workflow")

local wrd = {}
local runner

function wrd.setup(opts)
	local current = config.setup(opts)

	if current.commands then
		require("wrd.commands").setup()
	end
end

local function get_runner()
	if not runner then
		runner = workflow.new({ setup = wrd.setup })
	end
	return runner
end

-- opts {
--    word: string,
--    method: string
--    client_key: string
--    client: Client
--    mappings: { mode = { [key] = action } }
--    rank_jump: { enabled: boolean, delay_ms: number }
--    prompt: string
-- }
function wrd.run(opts)
	return get_runner().run(opts)
end

function wrd.run_methods(opts)
	return get_runner().methods(opts)
end

return wrd
