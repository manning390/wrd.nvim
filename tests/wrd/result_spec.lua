local result = require("wrd.result")

local function load_fixture()
	local lines = vim.fn.readfile("tests/fixtures/datamuse/cheese.json")
	return vim.json.decode(table.concat(lines, "\n"))
end

describe("normalized results", function()
	it("normalizes Datamuse entries without changing their order", function()
		local raw = load_fixture()
		local entries = result.normalize_datamuse(raw)

		assert.are.equal(4, #entries)
		assert.are.equal("cheeseflower", entries[1].word)
		assert.are.equal("mozzarella", entries[2].word)
		assert.are.equal("cheesy", entries[3].word)
		assert.are.equal("curd", entries[4].word)
		assert.are.equal(4, entries[4].rank)
		assert.are.equal(10050128, entries[4].score)
		assert.are.equal(raw[4], entries[4].raw)
	end)

	it("normalizes parts of speech from tags and definitions", function()
		local entries = result.normalize_datamuse(load_fixture())

		assert.are.same({ "adjective" }, entries[3].parts_of_speech)
		assert.are.same({ "noun", "verb" }, entries[4].parts_of_speech)
	end)

	it("parses definition prefixes while preserving qualifiers", function()
		local entries = result.normalize_datamuse(load_fixture())
		local curd = entries[4]

		assert.are.same({
			part_of_speech = "noun",
			text = "(India) Dahi.",
		}, curd.definitions[2])
		assert.are.same({
			part_of_speech = "verb",
			text = "(intransitive) To form curd; to curdle.",
		}, curd.definitions[3])
	end)

	it("accepts definitions without a known prefix", function()
		assert.are.same({
			part_of_speech = nil,
			text = "A plain definition.",
		}, result.parse_definition("A plain definition."))
	end)

	it("filters locally while preserving original ranks and order", function()
		local entries = result.normalize_datamuse(load_fixture())
		local nouns = result.filter_by_part_of_speech(entries, "noun")
		local adjectives = result.filter_by_part_of_speech(entries, "adj")

		assert.are.same(
			{ "cheeseflower", "mozzarella", "curd" },
			vim.tbl_map(function(entry)
				return entry.word
			end, nouns)
		)
		assert.are.same(
			{ 1, 2, 4 },
			vim.tbl_map(function(entry)
				return entry.rank
			end, nouns)
		)
		assert.are.same(
			{ "cheesy" },
			vim.tbl_map(function(entry)
				return entry.word
			end, adjectives)
		)
	end)

	it("returns a new complete list for the all filter", function()
		local entries = result.normalize_datamuse(load_fixture())
		local all = result.filter_by_part_of_speech(entries, "all")

		assert.are.same(entries, all)
		assert.are_not.equal(entries, all)
	end)
end)
