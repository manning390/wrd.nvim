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

	function session.follow(word, lifecycle)
		return handlers.run(session.options({ word = word }), lifecycle)
	end

	function session.choose_method(lifecycle)
		return handlers.run_methods(session.options({ method = "" }), lifecycle)
	end

	function session.change_word(word, lifecycle)
		return handlers.run(session.options({ word = word }), lifecycle)
	end

	function session.reopen(state)
		return handlers.reopen(state)
	end

	return session
end

return M
