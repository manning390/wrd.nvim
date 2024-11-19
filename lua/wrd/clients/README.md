# Wrd Clients
Clients are the interface in which the plugin fetches its data. As long as the client follows this interface, the data can be served from anywhere.

## Contract
All clients should have the following fields / functions:

```lua
{
    key = "client_key", -- This is some identifing string, should be unique for all registered clients

    -- A list of methods available for wrd to call for data
    -- The key is the method itself that must match to a method registered to the client module
    -- The value is the prompt and label entry when viewing available methods
    available_methods = { 
      fetch = "Fetch Prompt" 
    },

    -- The method listed within available method
    -- takes single parameter, the word being ran against
    -- returns list of entries
    fetch = function(query_word)
        -- Data can be in any format, as long as it's a list, will be parsed by entry_maker()
        return [
            {
                word = "weird"
                definition = "suggesting something supernatural; uncanny"
            },
            {
                word = "strange"
                definition = "unusual or surprising in a way that is unsettling or hard to understand"
            },
        ]
    end,

    -- Entry maker function, used within telescope
    -- Tells how to parse the data returned by fetch for telescope's and wrd's use
    -- entry is a data item returned by fetch
    entry_maker = function(entry, opts)
      return {
        value = entry, -- Required: The value of the entry item, usually the whole entry item itself
        ordinal = entry.word -- Optional: How the item is filtered and sorted, defaults to value
        display = entry.word -- Optional: What the word looks like within the entry list, defaults to value
        wrd = {
            word = entry.word -- Required: the word for wrd to use for its default actions
            opts = opts -- Optional: Wrd method opts may be overwritten here, provided by default
        }
      }
    end,

    -- Text to be displayed within telescope preview buffer
    -- returns a string
    previewer = function(entry)
      return entry.definition
    end,
}

```

If looking for a working example, check the provided [Datamuse Client](datamuse.lua).
