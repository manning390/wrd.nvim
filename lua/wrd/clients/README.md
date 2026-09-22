# Wrd client contract

A client fetches provider data and converts it into Wrd's provider-independent
result model. Pickers never inspect provider-specific response fields.

Clients may be built into `lua/wrd/clients/` and selected with `client_key`, or
passed directly as `client` to `setup()` or `run()`.

## Client

```lua
local client = {
    key = "example",                 -- required, stable and non-empty
    name = "Example Dictionary",     -- optional display name
    available_methods = {
        related = "Related Words",   -- method key -> picker label
    },
    method_descriptions = {           -- optional in-picker help
        related = "words related by the example service",
    },
}

-- Every advertised method must be implemented. Return the provider response,
-- return nil when the operation is cancelled, or raise an error on failure.
function client.related(word)
    return example_api.lookup(word)
end

-- Required. Convert one provider response into a list of Wrd results.
function client.normalize(response)
    return vim.tbl_map(function(item)
        return {
            word = item.term,
            score = item.relevance,
            parts_of_speech = item.parts,
            definitions = vim.tbl_map(function(text)
                return { text = text }
            end, item.meanings or {}),
            raw = item,
        }
    end, response.items or {})
end

return client
```

An empty normalized list means the query had no results. Malformed normalized
records are skipped with a warning that names the client and record index. A
client whose contract itself is incomplete is rejected before it is queried.

## Normalized result

Only `word` is required:

```lua
{
    word = "curd",                   -- required, non-empty string
    rank = 5,                         -- optional positive integer
    score = 10050128,                 -- optional provider relevance
    parts_of_speech = { "noun" },    -- optional
    definitions = {
        {
            part_of_speech = "noun", -- optional
            text = "Coagulated milk.", -- required for a definition
            source = "Example",      -- optional string or provider structure
        },
    },
    provenance = nil,                 -- optional string or provider structure
    origin = nil,                     -- optional string or provider structure
    concept = nil,                    -- optional string or provider structure
    raw = {},                         -- optional provider-specific metadata
}
```

Wrd recognizes `noun`/`n`, `verb`/`v`, `adjective`/`adj`, and
`adverb`/`adv`. It trims words and definitions, removes invalid optional
metadata, and assigns a stable rank from provider order when a rank is absent
or conflicts with an earlier result. Provider order is otherwise preserved.

Rank navigation and definition previews therefore work for every client.
Part-of-speech controls appear only when normalized results contain reliable
part-of-speech metadata. A client may explicitly advertise that capability
with `capabilities = { parts_of_speech = true }` when an empty response makes
inference impossible.

See `datamuse.lua` for the built-in adapter.

## Feature-complete shape

A provider can opt into every current picker feature by returning richer
records from `normalize`:

```lua
function client.normalize(response)
    local results = {}
    for index, item in ipairs(response.matches) do
        results[index] = {
            word = item.label,
            rank = item.provider_rank,
            score = item.score,
            parts_of_speech = item.grammar,
            definitions = vim.tbl_map(function(definition)
                return {
                    part_of_speech = definition.grammar,
                    text = definition.text,
                    source = definition.source,
                }
            end, item.definitions or {}),
            provenance = item.attribution,
            origin = item.etymology,
            concept = item.cluster,
            raw = item,
        }
    end
    return results
end
```

These field names are Wrd's contract; the raw provider may use any shape.
