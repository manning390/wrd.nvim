local curl = require "plenary.curl"

local DATAMUSE_API_URL = "https://api.dataMuse.com/words"

local Muse = {
  key = "datamuse",
  available_methods = {
    "means_like",
    "sounds_like",
    "spelled_like",
    "synonym",
    "antonym",
    "popular_nouns",
    "popular_adjectives",
    "generalize",
    "compromise",
    "homophones"
  },
}

function Muse.entry_maker(entry)
  return {
    value = entry,
    ordinal = entry.word,
    display = entry.word,
  }
end

function Muse.entry_selected(selected_entry_value)
  return selected_entry_value.word
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

  -- Map data to telescope entries
  data = vim.tbl_map(Muse.entry_maker, data)

  return data
end

function Muse.means_like(word)
  local query = { ml = word }
  return Muse._query(query), "Means Like"
end

function Muse.sounds_like(word)
  local query = { sl = word }
  return Muse._query(query), "Sounds Like"
end

function Muse.spelled_like(word)
  local query = { sp = word }
  return Muse._query(query), "Spelled Like"
end

function Muse._related(word, type)
  local query = { ['rel_' .. type] = word }
  return Muse._query(query)
end

function Muse.synonym(word)
  return Muse._related(word, 'syn'), "Synonym"
end

function Muse.antonym(word)
  return Muse._related(word, 'ant'), "Antonym"
end

function Muse.popular_nouns(word)
  return Muse._related(word, 'jja'), "Popular Nouns"
end

function Muse.popular_adjectives(word)
  return Muse._related(word, 'jjb'), "Popular Adjectives"
end

function Muse.generalize(word)
  return Muse._related(word, 'gen'), "Generalize"
end

function Muse.compromise(word)
  return Muse._related(word, 'com'), "Compromise"
end

function Muse.homophones(word)
  return Muse._related(word, 'hom'), "Homophone"
end

return Muse
