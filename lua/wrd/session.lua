local M = {}

function M.new(opts, handlers)
	opts = opts or {}
	handlers = handlers or {}
	local base_options = vim.tbl_extend("force", {}, opts)
	local session = {
		query_word = base_options.word,
		method = base_options.method,
		target = base_options.target,
		client = base_options.client,
	}

	function session.options(overrides)
		return vim.tbl_extend("force", {}, base_options, overrides or {})
	end

	function session.follow(word)
		return handlers.run(session.options({ word = word }))
	end

	function session.choose_method()
		return handlers.run_methods(session.options({ method = "" }))
	end

	function session.change_word(word)
		return handlers.run(session.options({ word = word }))
	end

	return session
end

return M
