local methods = require("wrd.pickers.methods")
local word = require("wrd.pickers.word")

return {
	word_layout = word.layout,
	word_picker = word.open,
	method_picker = methods.open,
}
