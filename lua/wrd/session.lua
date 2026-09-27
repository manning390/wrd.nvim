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
		query_definition = nil,
	}
	local definition_listener

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

	function session.set_query_definition(outcome)
		session.query_definition = outcome
		if definition_listener then
			definition_listener(outcome)
		end
	end

	function session.on_query_definition(callback)
		definition_listener = callback
	end

	return session
end

return M
