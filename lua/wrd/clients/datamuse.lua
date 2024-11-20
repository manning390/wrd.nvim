local curl = require "plenary.curl"

local DATAMUSE_API_URL = "https://api.dataMuse.com/words"

local Muse = {
  key = "datamuse",
  available_methods = {
    means_like = "Means Like",
    sounds_like = "Sounds Like",
    spelled_like = "Spelled Like",
    synonym = "Synonym",
    antonym = "Antonym",
    popular_nouns = "Popular Nouns",
    popular_adjectives = "Popular Adjectives",
    generalize = "Generalize",
    compromise = "Compromise",
    homophones = "Homophones"
  },
}

function Muse.entry_maker(entry)
  return {
    value = entry,
    ordinal = entry.word,
    display = entry.word,
    wrd = { word = entry.word }
  }
end

function Muse.previewer(entry)
  return entry.value.defs
end

function Muse._query(query)
  local resp = curl.get({
    url = DATAMUSE_API_URL,
    query = vim.tbl_extend('keep',
      query,
      {
        md = 'dprf', -- Metadata flags: definition, parts of speech, pronunciation, word frequency
      }
    ),
    accept = "application/json"
  })

  if resp.exit ~= 0 then
    error(string.format("Wrd Error: Datamuse api call failed with status '%s'", resp.status))
  end

  local data = vim.fn.json_decode(resp.body)

  return data
end

function Muse.means_like(word)
  local query = { ml = word }
  return Muse._query(query)
end

function Muse.sounds_like(word)
  local query = { sl = word }
  return Muse._query(query)
end

function Muse.spelled_like(word)
  local query = { sp = word }
  return Muse._query(query)
end

function Muse._related(word, type)
  local query = { ['rel_' .. type] = word }
  return Muse._query(query)
end

function Muse.synonym(word)
  return Muse._related(word, 'syn')
end

function Muse.antonym(word)
  return Muse._related(word, 'ant')
end

function Muse.popular_nouns(word)
  return Muse._related(word, 'jja')
end

function Muse.popular_adjectives(word)
  return Muse._related(word, 'jjb')
end

function Muse.generalize(word)
  return Muse._related(word, 'gen')
end

function Muse.compromise(word)
  return Muse._related(word, 'com')
end

function Muse.homophones(word)
  return Muse._related(word, 'hom')
end

return Muse
