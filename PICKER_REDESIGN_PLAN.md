# Wrd Picker Redesign Plan

Last updated: 2026-09-21

## Goal

Make `wrd.nvim` feel like the OneLook Thesaurus while retaining Telescope's
fuzzy-finding strengths: show roughly 100 relevance-ranked words, keep a useful
definition preview visible, filter results by part of speech, and support fast
number-based navigation without turning the number into a fuzzy-search query.

At the same time, simplify the codebase into explicit, testable layers before
adding stateful picker behavior.

## Progress

- [x] Create this local implementation plan and checklist.
- [x] Review the existing `wrd.nvim` architecture and Telescope integration.
- [x] Update the documented Telescope baseline to v0.2.0.
- [x] Confirm that the current Telescope calls are supported by v0.2.x.
- [x] Inspect the OneLook `cheese` result structure.
- [x] Inspect a 100-result Datamuse response, including scores, definitions, and
  part-of-speech tags.
- [x] Record Telescope constraints that affect dense and multi-column results.
- [x] Add initial characterization tests for setup, configuration, client
  selection, and method dispatch.
- [x] Expand characterization coverage to the current pickers and actions.
- [x] Refactor configuration, querying, result shaping, pickers, and actions.
- [x] Implement the first ranked-results and definition-preview presentation.
- [x] Implement part-of-speech filtering.
- [x] Implement number-based navigation that does not modify the prompt.
- [x] Implement bindable in-picker capabilities/help.
- [x] Harden and document the public client contract before adding another
  client or building the multi-column prototype.
- [x] Prototype and decide on a multi-column presentation. Keep the native list
  as the default and support the adaptive grid as an explicit opt-in.
- [x] After the architecture refactor, add a persistent current-query
  definition section above the selected-result definition in the preview.
- [ ] Complete documentation, compatibility tests, and release verification.

## Reference behavior

The OneLook page for `cheese` provides the following useful model:

- A short query/meaning summary above the results.
- A relevance-ordered, numbered list of 100 results.
- Five visual columns, each containing 20 results.
- Filters for All, Nouns, Adjectives, Verbs, Adverbs, Idioms/Slang, and Old.
- Selecting a result opens a definition popover with a word heading, a list of
  definitions, definition-source attribution, a word-origin link, and a related
  concept cluster when that metadata is available.
- Additional concepts and phrases after the main list; these are not required
  for the first version of this redesign.

A plain Datamuse `ml=cheese` query does not exactly reproduce OneLook's visible
ordering. We must distinguish "preserve Datamuse relevance" from "match
OneLook exactly" and test the chosen behavior explicitly.

## Product decisions

### Initial ranked-list behavior

- [ ] Request an explicit, configurable result limit with a default of 100.
  Datamuse now explicitly requests 100; user configuration remains to be wired.
- [x] Assign each normalized response item a stable `rank` before it reaches
  Telescope.
- [x] Preserve the server's order when the fuzzy prompt is empty.
- [x] Keep the original rank visible while filtering.
- [ ] Let Telescope fuzzy-sort the currently eligible results only after the
  user enters a text query.
- [ ] Decide whether exact OneLook ranking parity is feasible through public
  Datamuse parameters or whether API relevance is the documented contract.
- [ ] Add deterministic behavior for duplicate words and results without a
  definition.

### Result presentation

Each normalized result should expose, at minimum:

```lua
{
    word = "cheddar",
    rank = 16,
    score = 20049959,
    parts_of_speech = { "noun" },
    definitions = {
        { part_of_speech = "noun", text = "A hard, full-fat Italian cheese ..." },
    },
    raw = {},
}
```

- [x] Display rank, word, and compact part-of-speech labels in the results pane.
- [x] Keep the word—not its rank or labels—as the Telescope fuzzy-search
  `ordinal`.
- [x] Format the definition content using the useful parts of OneLook's
  selected-word view:
  - word heading and compact part-of-speech information;
  - a blank line followed by readable, wrapped definitions;
  - one visually distinct bullet or numbered item per definition;
  The surrounding OneLook popover and its attribution, origin, and concept
  footer are reference UI rather than required Wrd behavior.
- [x] Strip Datamuse's raw `n\t`, `v\t`, `adj\t`, and `adv\t` prefixes from
  definition text after converting them to normalized labels.
- [x] Preserve qualifiers such as `(India)`, `(uncountable)`, or `(slang)` in
  the rendered definition.
- [x] Confirm that public Datamuse responses do not expose OneLook's origin or
  concept-cluster fields; do not reproduce that popover footer.
- [x] Show a useful fallback when Datamuse supplies no definition.
- [x] Preserve the existing select, follow, and method-switch actions.
- [x] Make Telescope's side-by-side (`horizontal`) layout the recommended
  default: compact results on the left and a larger definition preview on the
  right. This does not make the word results themselves multi-column.
- [x] Expose layout and display choices through configuration rather than
  hard-coding user preferences.

### Part-of-speech filters

Datamuse already returns `n`, `v`, `adj`, and `adv` tags when `md` includes
part-of-speech metadata. Filtering can therefore happen locally without a
second network request.

- [x] Normalize Datamuse tags to `noun`, `verb`, `adjective`, and `adverb`.
- [x] Keep untagged results in All and exclude them from a specific POS filter.
- [x] Add an `All` state plus noun, adjective, verb, and adverb filters.
- [x] Preserve original relative ranking inside every filtered subset.
- [x] Refresh the active picker without clearing the fuzzy prompt.
- [x] Reflect the active filter and eligible count in the results title.
- [x] Use `<C-j>` to cycle filters in insert and normal mode. Telescope 0.2.x
  assigns it to a no-op in insert mode; normal-mode `j`/`k` navigation remains
  available. Direct public actions allow every filter to be rebound separately.
- [x] Skip categories with no eligible entries during the default cycle while
  allowing an explicitly invoked direct filter to show an honest empty subset.
- [ ] Consider Idioms/Slang and Old only after confirming that the public API
  exposes reliable metadata for them.

### Selection and copying

- [x] Capture the original editing target before Telescope takes focus.
- [x] Make Enter replace the captured word or visual range, or insert at the
  captured cursor when it is on whitespace.
- [x] Copy every chosen word to the unnamed, `+`, and `*` registers.
- [x] Add bindable copy-only behavior on `<C-y>` so users can paste elsewhere
  with ordinary Vim operations.
- [x] Support exact characterwise and linewise replacement; keep blockwise
  selections copy-only because one word has no unambiguous rectangular
  replacement.
- [x] Fall back to copy-only with an informational message if the original
  buffer is gone or unmodifiable.
- [x] Preserve the original target across follow and method transitions.

### Number navigation

Ranks must be navigation metadata, not fuzzy-search text. Typing a rank should
move the selection and update the preview while leaving the full result set
visible.

- [x] Target the original rank rather than the current visible row so numeric
  input matches the displayed labels.
- [x] Reserve direct digit input in insert and normal mode for a short-lived
  numeric buffer. Wait 600 ms for an ambiguous next digit, resolve an
  unambiguous rank immediately, and show the pending value on Neovim's message
  line. Allow users to disable this behavior when searching digit-containing
  text matters more than rank navigation.
- [x] Move the picker selection with Telescope's `set_selection` API and keep
  both the prompt and finder contents unchanged.
- [x] Handle ranks excluded by the current fuzzy query with a clear,
  non-destructive message.
- [x] Test ranks 1, 9, 10, and 100, invalid ranks, and stale timers. Do not
  override Backspace or Escape for ephemeral rank input.
- [ ] Verify numeric navigation manually while a part-of-speech filter is
  active. The shared picker manager makes filtered-out ranks non-destructive.

### In-picker capabilities and help

Users should be able to discover Wrd-specific behavior without leaving the
active picker or consulting the README. This is distinct from, but may reuse,
Telescope's built-in `which_key` support.

- [x] Add a public `wrd_help` action that can be assigned through the existing
  `mappings` configuration.
- [x] Use `<F1>` in insert and normal mode after checking Telescope v0.2.x
  defaults. Preserve the ability to disable or remap either binding.
- [x] Show the effective key—not merely the default key—for every documented
  action.
- [x] Explain:
  - fuzzy searching and clearing the prompt;
  - moving through results and opening the selected word;
  - following the selected word with a new related-word query;
  - changing the Datamuse method;
  - enabling, changing, and clearing part-of-speech filtering;
  - entering numeric ranks and their automatic timeout;
  - changing the current search word without leaving the picker workflow;
  - scrolling the definition preview;
  - closing help and closing the picker.
- [x] Build help content dynamically so unfinished, disabled, client-specific,
  or unmapped capabilities are not advertised as available.
- [x] Include the active client and method, plus a short explanation of the
  current method when the client provides one.
- [x] Keep help content generation independent from its window renderer.
- [x] Evaluate native `nvim_open_win`, `plenary.popup`, and
  `plenary.window.float`. The Plenary helpers wrap the native API but add
  global bookkeeping and older option-setting patterns that this focused
  window does not need; use the native API.
- [x] Use a non-focusable floating help overlay rather than a nested Telescope
  picker so the Telescope prompt never loses focus or reconstructs finder state.
- [x] Size and position the help window relative to the editor,
  with sensible behavior in narrow or short terminals.
- [x] Make the help buffer non-modifiable, disposable, and excluded from buffer
  listings and swap files.
- [x] Toggle help with its configured binding. Normal Telescope input remains
  focused underneath; closing the picker also closes help.
- [x] Restore focus to the original Telescope prompt and retain its prompt,
  filters, selection, and preview state after help closes.
- [x] Close the help window if the underlying picker buffer disappears and
  recalculate its centered dimensions when Neovim is resized.
- [x] Keep Telescope's generic `which_key` separately available.
- [x] Allow custom clients to contribute current-method help through an
  optional `method_descriptions` table; result-dependent capabilities remain
  hidden when normalized metadata does not support them.

### Client contract hardening

The normalized result model is intentionally service-independent. This
checkpoint replaces the former implicit `normalize` opt-in and dual picker
path with one validated, extensible contract before another built-in client or
grid is added.

- [x] Define a public Client v2 contract with Lua annotations and prose docs:
  - stable `key` and optional display `name`;
  - advertised method keys and labels;
  - optional method descriptions for capabilities help;
  - query functions and their success, cancellation, empty, and error results;
  - raw-response normalization into service-independent Wrd results.
- [x] Define and validate the public normalized-result contract, including
  required `word` and optional rank, score, POS, definitions, provenance,
  origin, concept, and raw-provider metadata.
- [x] Assign stable fallback ranks centrally when a client omits them; reject or
  skip malformed records with actionable client-specific errors.
- [x] Move `from_datamuse`, `normalize_datamuse`, and Datamuse definition-prefix
  decoding out of the generic `wrd.result` module and into the Datamuse adapter.
- [x] Replace `_wrd_normalized` with explicit picker input/capability state.
  Infer safe capabilities from validated results where possible and allow a
  client to declare optional features when inference is insufficient.
- [x] Make the normalized picker path the primary client interface so ranked
  display, definition previews, help, selection, and numeric navigation work
  for every conforming client.
- [x] Remove the `entry_maker`/`previewer` client path rather than maintaining a
  compatibility adapter. There are no legacy clients to preserve; favor one
  small, explicit contract over permanent dual-path complexity.
- [x] Keep POS filtering optional: clients without reliable POS metadata should
  retain all other normalized-picker features without advertising inert filter
  controls.
- [x] Ensure a custom client can be provided directly through setup without
  living under the built-in `wrd.clients` module namespace.
- [x] Add a fake non-Datamuse client and end-to-end picker-boundary tests
  covering methods, normalization, ranks, definitions, optional capabilities,
  help content, and selection.
- [x] Add malformed-client tests for missing methods, invalid normalized
  records, unsupported capabilities, empty results, and provider errors.
- [x] Rewrite `lua/wrd/clients/README.md` around Client v2 with a minimal client,
  a feature-complete client, and normalized-result examples.
- [ ] Record the stable public contract in release notes. The main README now
  documents direct custom-client injection and links to the complete contract.

Acceptance test for this checkpoint: a fake provider whose raw response has no
Datamuse field names must receive the ranked picker, structured preview, numeric
navigation, selection/copy behavior, and dynamic help. POS controls must appear
only when that provider supplies valid POS metadata.

### Dense and multi-column results

Telescope fundamentally selects rows. `entry_display` can create multiple
fields within one entry, but it does not make several independently selectable
entries on the same row. Packing words into a grid row would require custom
cell selection, preview synchronization, fuzzy-result packing, scrolling, and
accessibility behavior.

- [x] First maximize useful density within native Telescope behavior:
  full-height side-by-side panes (Telescope's `horizontal` strategy), compact
  rows, configurable preview width, and minimal result decorations.
- [x] Measure how many results are visible at common terminal sizes. With the
  default bordered Telescope v0.2 layout, one-line command area, statusline,
  and no tabline, the 95%-height picker exposes approximately 15 rows at 24
  editor lines, 31 at 40 lines, and 50 at 60 lines. A visible tabline costs one
  row.
- [x] Prototype a grid adapter behind an opt-in setting; do not make it the
  default during the prototype. `picker.presentation = "grid"` packs results
  down adaptive columns while the native list remains the default.
- [x] In the prototype, verify cell navigation, numeric jumps, preview updates,
  fuzzy filtering, resizing, scrolling, and selection actions. Pure behavior
  and rank-jump coverage are automated; live Telescope interaction remains the
  current manual checkpoint.
- [x] Compare the grid prototype with native one-entry-per-row behavior.
- [x] Adopt the grid as a supported opt-in while retaining the native list as
  the default. The adapter uses Telescope's dynamic finder and picker refresh
  behavior; keep those dependencies isolated behind the presentation boundary.

## Architecture cleanup

### Target boundaries

Refactoring should preserve public behavior while moving responsibilities into
small modules:

```text
wrd.init
  -> config             defaults, validation, setup state
  -> workflow           public word/method lifecycle orchestration
      -> query          client selection, dispatch, and normalization
  -> result             normalized result model and filters
  -> pickers.words      ranked word picker and picker-local state
  -> pickers.methods    client-method picker
  -> actions            actions operating on the active picker state
  -> clients.datamuse   HTTP parameters and Datamuse response normalization
```

- [x] Add `wrd.config` with immutable defaults, setup merging, and validation.
  - [x] Extract fresh defaults and setup state.
  - [x] Preserve current top-level override behavior.
  - [x] Add validation with actionable errors.
- [x] Replace `vim.g.telescope_wrd_config` and
  `vim.g.telescope_wrd_setup` with module-owned state.
- [x] Define and document the client contract in Lua annotations and the client
  README.
- [x] Separate transport/query errors from empty results and user cancellation.
- [x] Move result normalization out of Telescope `entry_maker` functions.
- [x] Split word and method picker construction into focused modules.
- [x] Keep picker-specific mutable state behind one picker-local controller
  rather than separate globals or unrelated private picker fields.
- [x] Isolate native-list and grid-specific finder, sorter, layout, activation,
  and refresh behavior behind a shared presentation interface.
- [x] Make all picker actions recover their picker-local session/state rather
  than carrying runtime options on result entries or introducing global state.
- [x] Remove repeated client/config resolution from public entry points.
- [x] Make command, direct-Lua, and Telescope-extension entry points call the
  same orchestration path.
- [x] Add consistent `Wrd Error:` failures and `Wrd:` user-facing
  notifications.
- [x] Keep the primary result query synchronous for now; require optional
  secondary lookups such as query definitions to be asynchronous or lazy so
  they do not add another blocking request to picker startup.

### Refactoring sequence

- [x] Freeze current externally visible behavior with characterization tests.
- [x] Extract configuration without changing picker behavior.
- [x] Extract client resolution and query orchestration.
- [x] Introduce the normalized result model and adapt the Datamuse client.
- [x] Split picker modules and reduce `wrd.init` to a public facade.
- [x] Refactor actions around explicit picker state.
- [x] Run the complete test suite after each extraction.
- [x] Keep the implemented ranked-list behavior green throughout the refactor.

## Current-query definition context — after the refactor

Do not add this feature directly to the current `wrd.pickers` orchestration.
Implement it only after a picker session/controller owns query state and the
list/grid presentations share one preview model.

Use a second section in Telescope's existing preview rather than a fourth
managed window. Telescope v0.2 exposes `create_layout`, so another window is
technically possible, but it would require custom mounting, resizing, cleanup,
and focus behavior beyond Telescope's prompt/results/preview assumptions.

Proposed preview structure:

```text
Query · cheese

• A food made from pressed milk curds.

────────────────────────────

Selected · curd · rank 5

• [noun] The part of milk that coagulates ...
```

- [x] Add an optional provider-independent client capability for describing an
  exact word; clients without it retain the selected-result preview unchanged.
- [x] Implement Datamuse exact-word lookup and reject approximate spelling
  matches when determining the query definition.
- [x] Store the normalized query definition on the picker session/controller,
  not on Telescope entries or presentation-specific state.
- [x] Cache definitions by client and word so method changes and repeated
  queries do not issue redundant requests.
- [x] Require query-definition lookup to be asynchronous or lazy before
  implementation; it must not noticeably double picker startup latency.
- [x] Format query and selected definitions through one presentation-independent
  preview model used by both list and grid modes.
- [x] Make the section configurable, including enable/disable and a small
  definition limit so selected-result content retains useful space.
- [x] Hide the section cleanly when no exact definition is available; do not
  present an error or misleading approximate definition as query context.
- [x] Preserve query-definition context across method changes, update it after
  follow/change-word actions, and keep selection preview updates independent.
- [x] Add client-contract, caching, preview-formatting, transition, and
  unavailable-data tests before enabling the section by default.
- [ ] Reconsider a custom fourth window only if the combined preview proves
  unusable in manual list and grid testing.

## Test strategy

Use Plenary's test harness because Plenary is already a required dependency.
Keep most behavior in pure functions so tests do not need a live Telescope UI.

### Unit tests

- [x] Configuration defaults, overrides, validation, and setup idempotence.
- [x] Client lookup and custom-client injection.
- [x] Datamuse query parameter construction, including metadata and result limit.
- [x] Datamuse response normalization from checked-in fixtures.
- [x] Rank preservation and stable filtering.
- [x] Part-of-speech normalization and predicates.
- [x] Definition parsing and preview-line formatting.
- [x] Multi-definition preview formatting, including qualifiers and blank-line
  separation.
- [x] Keep source/origin/concept footer rendering out of scope; the OneLook
  popover was a reference for definition content rather than required UI.
- [x] Entry creation: value, display, ordinal, rank, and action metadata.
- [x] Numeric-jump parsing and rank lookup.
- [x] Help-model generation from effective mappings and enabled capabilities.
- [x] Help-window sizing, buffer options, close behavior, and focus restoration.
- [x] Empty, malformed, cancelled, and failed responses.

### Picker/action integration tests

- [x] Extension registration exposes `run` and `methods`.
- [x] Word picker constructs a finder with 100 ranked entries.
- [x] Selection copying, captured-target application, and picker closing are
  covered across action and real-buffer tests.
- [x] Follow-up search closes the old picker and retains the highlighted word
  and expected options.
- [x] Method switching closes the old picker and retains the current query word;
  only follow (`/`) promotes the highlighted result to a new query word.
- [x] POS filtering refreshes without resetting the prompt.
- [x] Numeric navigation changes selection without changing finder contents.
- [x] Help shows effective mappings and uses a separate window, leaving the
  picker instance untouched while focus moves away and back.
- [x] Closing the underlying picker cleans up an open help window.
- [ ] Preview content follows selection and filter changes.

### Compatibility and automation

- [x] Add a single headless test command for contributors: `./scripts/test`.
- [x] Add a repository-wide StyLua policy and a combined formatting/test check
  that can be run consistently locally. A semantic linter remains optional.
- [ ] Test the minimum supported combination: Neovim 0.10.4 and Telescope
  v0.2.0.
- [ ] Test current stable Neovim and the latest compatible Telescope release.
- [ ] Add CI only after the local commands and fixtures are stable.
- [x] Ensure tests never call the live Datamuse service by default.
- [ ] Keep one optional manual smoke-test procedure for the real service.

## Delivery milestones

### Milestone 1: Safe foundation

- [x] Characterization tests pass.
- [x] Architecture cleanup is complete without intentional behavior changes.
- [x] Public setup, command, direct Lua, and extension interfaces still work.

### Milestone 2: OneLook-style ranked picker

- [x] Up to 100 results retain a stable relevance rank.
- [x] Compact ranked entries and formatted definition previews work.
- [x] Empty prompts preserve server relevance order.
- [ ] Fuzzy queries still produce useful word matches.

### Milestone 3: Filtering and navigation

- [x] POS filters work without another HTTP request.
- [x] The active filter is visible and reversible.
- [x] Numeric navigation moves selection without hiding results.
- [x] Capabilities/help shows the effective bindings for enabled picker actions.
- [x] Existing select, copy, follow, and method actions remain usable in unit
  coverage; manual selection behavior remains a check-in item.

### Milestone 4: Density decision

- [x] Native dense layout is measured and documented.
- [x] Multi-column prototype is evaluated against explicit acceptance criteria.
- [x] The supported layout decision is recorded with its tradeoffs.

Client contract hardening must complete before this milestone begins; the grid
must consume validated Wrd results rather than Datamuse records or legacy
Telescope entries.

### Milestone 5: Current-query definition context

- [x] The architecture refactor and shared preview boundary are complete.
- [x] An optional client description capability supplies normalized exact-word
  data without coupling Telescope to Datamuse.
- [x] The combined query/selection preview works in list and grid modes.
- [x] Caching and fetch behavior do not materially delay opening the picker.
- [x] Missing query definitions degrade to the existing selected-only preview.

### Milestone 6: Release readiness

- [ ] Unit and integration tests pass on the supported version matrix.
- [ ] README documents configuration, mappings, filters, navigation, and layout.
- [ ] Client extension documentation matches the normalized result contract.
- [ ] Manual Datamuse smoke test succeeds.
- [ ] Changelog/release notes summarize breaking and non-breaking changes.

## Check-in points

### Check-in 1: Test harness and configuration extraction — ready

Automated verification:

```sh
./scripts/test
```

Expected result: 9 successful tests, 0 failures, and 0 errors.

Manual verification from a fresh Neovim session using this working tree:

```vim
:lua require("wrd").setup()
:lua require("wrd").setup()
:Wrd cheese
```

Expected behavior:

- Repeating setup produces no duplicate-command error.
- `:Wrd cheese` opens the same Telescope word picker as before this refactor.
- Moving through results updates the existing definition preview.
- `/` follows the selected word and `<Tab>` opens the method picker.

This check-in intentionally makes no visual changes. Report any difference in
the existing picker before work continues into query and result normalization.

### Check-in 2: Query and normalized-result boundary — ready

- [x] Client resolution and method dispatch live in `wrd.query`.
- [x] Offline Datamuse fixtures cover rank, score, parts of speech, and multiple
  definitions.
- [x] `wrd.result` normalizes records and filters them without changing rank.
- [x] Datamuse explicitly requests up to 100 results with `dprf` metadata.
- [x] The legacy picker input and display path remains in place.

Automated verification:

```sh
./scripts/test
```

Expected result: 31 successful tests, 0 failures, and 0 errors.

Manual live-data inspection:

```vim
:lua local d = require("wrd.clients.datamuse"); local raw = d.means_like("cheese"); local items = d.normalize(raw); print(#raw, #items, items[1].rank, items[1].word)
:Wrd cheese
```

Expected behavior:

- The first command reports matching raw and normalized counts, followed by
  rank `1` and the first returned word.
- `:Wrd cheese` still uses the pre-redesign visual presentation.
- Result navigation, preview, follow, and method switching still behave as in
  Check-in 1.
- Following highlighted `parmesan` queries `parmesan`; changing methods retains
  the word used to open the current picker regardless of the highlighted row.
- A method with no results shows an informational notification instead of an
  empty Telescope picker.
- A result without definitions shows `No definition available.` in the preview.

Report any difference in the live picker before the normalized model replaces
the legacy presentation path.

### Check-in 3: Ranked display and OneLook-style preview — ready

- [x] Datamuse uses normalized entries; legacy custom clients retain their
  existing presentation path.
- [x] Results display stable rank, word, and compact POS labels such as
  `[n,adj]`.
- [x] Rank and labels are excluded from the fuzzy-search ordinal.
- [x] Empty prompts preserve Datamuse order instead of breaking ties by word
  length.
- [x] The default layout is a full-height horizontal picker with a larger
  preview pane.
- [x] Preview headings and separate, labeled definition bullets replace raw
  `n\t...` strings.

Automated verification:

```sh
./scripts/test
```

Expected result: 36 successful tests, 0 failures, and 0 errors.

Manual visual review from a fresh Neovim session:

```vim
:Wrd cheese
```

Please check:

- The first unfiltered rows are numbered in Datamuse relevance order.
- Rows resemble `  6. parmesan [n,adj]` and remain reasonably compact.
- Typing `parmesan` matches the word rather than its rank or POS label.
- The preview begins with the selected word and shows definitions as distinct
  bullets with readable blank-line separation.
- Definitions retain qualifiers such as `(slang)` but no longer expose raw
  `n\t` or `adj\t` prefixes.
- `/` and `<Tab>` retain the agreed follow-versus-change-method behavior.
- The 60% preview width is useful at your normal terminal size; note whether
  the results pane feels too narrow or too wide.

This is the preferred point to adjust density and preview formatting before POS
filter actions add more picker state.

### Check-in 4: Direct numeric rank navigation — ready

- [x] Digits are intercepted in insert and normal mode without entering the
  Telescope prompt.
- [x] One- and two-digit ambiguity is resolved with a configurable 600 ms
  debounce; impossible longer prefixes resolve immediately.
- [x] Pending input is visible as `Wrd jump: …_` on the message line.
- [x] Enter resolves the pending rank immediately. Backspace and Escape are not
  intercepted; pending rank input expires automatically.
- [x] Resolving a rank moves only the highlight and preview; the finder and
  fuzzy prompt are unchanged.
- [x] Missing or fuzzy-filtered ranks produce an informational message.
- [x] `rank_jump.enabled = false` restores digits to ordinary Telescope prompt
  input.

Automated verification:

```sh
./scripts/test
```

Expected result: 44 successful tests, 0 failures, and 0 errors.

Manual review from a fresh Neovim session:

```vim
:Wrd cheese
```

Please check:

- Press `9`, pause briefly, and confirm the highlight and definition move to
  rank 9 without hiding any words.
- Press `1` then `7` quickly and confirm rank 17 resolves immediately.
- Press `1` then `0`, pause, and confirm rank 10 is selected; press `1`, `0`,
  `0` quickly and confirm rank 100 is selected.
- Press `1`, then Backspace, and confirm Backspace retains its normal fuzzy-text
  behavior. Escape should retain Telescope's normal close behavior.
- Type a textual fuzzy query that excludes rank 17, then enter `17`; confirm
  the existing filtered list stays intact and an informational message appears.
- Press Enter while a number is pending; it should move the highlight, not
  select/insert the word. A subsequent Enter performs normal word selection.

This is a useful stopping point before POS filtering because numeric jumps can
now be tested against the complete result set. The same rank lookup will be
reused against the locally filtered entries in the next stateful phase.

### Check-in 5: Local part-of-speech filters — ready

- [x] `<C-j>` cycles All, Nouns, Adjectives, Verbs, and Adverbs in both picker
  modes.
- [x] Empty categories are skipped during cycling.
- [x] The results title shows the active filter and eligible count.
- [x] Filtering reuses normalized Datamuse metadata and never repeats the HTTP
  request.
- [x] Telescope refresh retains the existing fuzzy prompt.
- [x] Original ranks and relative order survive every subset.
- [x] Direct public actions support separate custom bindings for each filter.
- [x] Filter state belongs to the active picker rather than a global variable.
- [x] `<C-e>` prompts for a replacement search word and reruns the same method
  while retaining the original insertion target. Cancel and unchanged input
  leave the current picker open.

Automated verification:

```sh
./scripts/test
```

Expected result: 53 successful tests, 0 failures, and 0 errors.

Manual review from a fresh Neovim session:

```vim
:Wrd cheese
```

Please check:

- The initial results title reads `Words · All (N/N)`.
- Repeated `<C-j>` cycles through the POS subsets and returns to All; any subset
  with zero matching words is skipped.
- Each subset retains the displayed original ranks rather than renumbering its
  rows.
- Enter fuzzy text such as `che`, then press `<C-j>` and confirm the text stays
  in the prompt while both constraints apply.
- In a filtered subset, jump to a displayed rank and confirm selection moves.
  Then jump to a rank excluded by that subset and confirm the filter and fuzzy
  prompt remain unchanged while an informational message appears.
- `/`, `<Tab>`, Enter selection, Backspace, and Escape still behave as in the
  preceding checkpoints.

This is the preferred stopping point before implementing capabilities/help.
The picker now has enough stateful behavior that discoverability is the next
problem worth solving; the help model should describe effective mappings rather
than hard-code `<C-j>` or any other default.

### Check-in 6: Capabilities help and deterministic selection — ready

- [x] `<F1>` opens a centered native floating help window and toggles it closed.
- [x] Help shows current query, client, method meaning, POS filter, and effective
  mappings rather than assumed defaults.
- [x] Disabled, unmapped, legacy-client, and normalized-only capabilities are
  omitted when unavailable.
- [x] Closing help with its binding, `q`, or Escape restores the Telescope
  window without reconstructing the picker.
- [x] Resize and parent-buffer cleanup are handled by window-local autocommands.
- [x] Enter applies a selected word to a target captured before Telescope opens;
  `<C-y>` is an explicit copy-only alternative.
- [x] The selected word is stored in the unnamed, `+`, and `*` registers.
- [x] Word, insertion-point, characterwise, and linewise targets have explicit
  behavior; blockwise and unavailable targets fall back to copy-only.

Automated verification:

```sh
./scripts/test
```

Expected result: 66 successful tests, 0 failures, and 0 errors.

Manual help review:

1. Open `:Wrd cheese`, enter some fuzzy text, change the POS filter, and move
   away from the first result.
2. Press `<F1>` and verify the displayed query, method, filter, and mappings.
3. Close with `q`; reopen and close with `<F1>` and Escape.
4. Confirm the prior fuzzy text, POS filter, highlighted word, and preview are
   unchanged after each close.
5. Resize Neovim while help is open and confirm it remains centered and usable.

Manual selection review in a disposable buffer:

1. Put the cursor inside `cheese`, run `:Wrd cheese`, highlight another result,
   and press Enter. The original complete word should be replaced.
2. Put the cursor between two spaces, repeat, and confirm the word is inserted
   without deleting adjacent text.
3. Repeat but press `<C-y>`; the buffer should remain unchanged and normal
   `p`/`P`, `viwp`, or `"_ciw<C-r>"` should paste from the unnamed register.
4. Add the documented visual-mode Lua mapping, select part of a phrase, invoke
   Wrd, and confirm Enter replaces exactly that characterwise selection.
5. Try `:'<,'>Wrd cheese` on disposable lines and confirm Enter replaces the
   selected lines with one word.
6. Optionally test a blockwise selection or unmodifiable buffer; Enter should
   copy without editing and show the reason.

This is the next stopping point. Once the interaction and wording feel right,
the plan moves to Client v2 contract hardening. The multi-column result grid
follows only after that provider boundary is stable.

### Check-in 7: Provider-independent client contract — ready

- [x] Every client now returns the same validated Wrd result model.
- [x] The Datamuse adapter owns Datamuse tag and definition-prefix decoding.
- [x] The old client `entry_maker`/`previewer` picker path is removed.
- [x] Missing and conflicting ranks receive stable provider-order fallbacks.
- [x] POS controls are inferred from normalized metadata and omitted when a
  provider cannot support them.
- [x] Directly configured custom clients are covered through the picker
  orchestration boundary without using Datamuse-shaped fields.
- [x] Client and result errors identify the provider and malformed record.

Automated verification:

```sh
./scripts/test
```

Expected result: 72 successful tests, 0 failures, and 0 errors.

Manual verification uses the local, network-free custom client from the
check-in instructions. It should show three ranked words with definitions,
support numeric navigation and selection, and omit the POS filter from help.
Restart Neovim afterward to restore the normal Datamuse configuration.

This is the stopping point before density work. The next plan item is to
measure and maximize the native Telescope layout before deciding whether to
build the opt-in multi-column prototype.

### Check-in 8: Opt-in grid prototype — ready for live evaluation

- [x] `picker.presentation = "grid"` enables the prototype without changing
  the default native list.
- [x] Results pack down adaptive columns in relevance order.
- [x] Fuzzy matching filters individual words before repacking.
- [x] Horizontal cell movement updates the selected result and preview.
- [x] Numeric ranks locate cells rather than only Telescope rows.
- [x] POS filtering rebuilds the eligible grid without clearing the prompt.
- [x] Resize handling recalculates the column count.
- [x] Capabilities help documents the configured cell-navigation keys.

Automated verification:

```sh
./scripts/test
```

Expected result: 82 successful tests, 0 failures, and 0 errors.

Manual evaluation should compare the prototype with the default list, paying
particular attention to Ctrl-Left/Right terminal compatibility, selection and
preview synchronization, the incomplete final row, fuzzy repacking, POS
filtering, rank jumps, scrolling, and resizing across the preview cutoff.

Do not make the grid the default until this interaction passes manual review
and its Telescope-internal dependencies have been assessed.

### Check-in 9: Picker and presentation boundaries — ready

- [x] `wrd.pickers` is a small compatibility facade over focused word and
  method picker modules.
- [x] List and grid behavior implement one presentation interface.
- [x] Filtering refreshes through that interface rather than branching on the
  presentation type.
- [x] Help, grid, filters, presentation, and context state share one
  picker-local controller boundary.
- [x] Unsupported presentation names fail with an actionable error.

Automated verification:

```sh
./scripts/test
```

Expected result: 86 successful tests, 0 failures, and 0 errors.

Manual verification should repeat the standard `:Wrd cheese` smoke test in
both list and grid modes. No visible behavior is intended to change in this
checkpoint. The following checkpoint removes full runtime option tables from
entries and routes follow/method/change-word actions through an explicit
session.

### Check-in 10: Explicit picker session — ready

- [x] A picker session owns the current query word, method, client, and captured
  insertion target.
- [x] Follow, method switching, and direct query changes dispatch through the
  session rather than importing the public `wrd` module from picker actions.
- [x] Selection applies through the session's captured insertion target.
- [x] List and grid entries contain result identity only; they no longer carry
  the complete runtime options table.
- [x] Each follow-up operation receives a fresh options table, leaving the
  original session context unchanged.
- [x] Cancelling or submitting an unchanged direct-query prompt restores the
  Telescope prompt window and its previous insert/normal interaction mode.

Automated verification:

```sh
./scripts/test
```

Expected result: 89 successful tests, 0 failures, and 0 errors.

Manual verification should exercise selection, follow (`/`), method switching
(`<Tab>`), and direct query changes in both list and grid modes. Each operation
should retain the original insertion target; only follow changes the query to
the highlighted result.

### Check-in 11: Shared public workflow — ready

- [x] `wrd.init` exposes setup, word search, and method selection without owning
  their internal lifecycle.
- [x] One workflow prepares configuration, client, mappings, navigation,
  presentation, and insertion-target state.
- [x] Choosing a method returns to the same word-query workflow rather than a
  separate partially duplicated path.
- [x] `:Wrd`, direct Lua calls, and Telescope extension exports retain their
  existing public entry points and converge on that workflow.
- [x] Caller option tables are copied before runtime defaults and capabilities
  are attached.

Automated verification:

```sh
./scripts/test
```

Expected result: 87 successful tests, 0 failures, and 0 errors.

Manual verification should open a query through `:Wrd`, `require('wrd').run`,
and `require('telescope').extensions.wrd.run`, then open method selection via
both `<Tab>` and `require('wrd').run_methods`. Each route should produce the
same picker behavior and preserve the buffer location where the flow began.

### Check-in 12: Configuration validation — ready

- [x] Validate top-level configuration and the nested rank-navigation, picker,
  grid, and mapping containers before activating new settings.
- [x] Report invalid values with their complete configuration paths.
- [x] Preserve the last valid configuration when a later setup call fails.
- [x] Permit disabled mappings and provider/Telescope-specific action values.
- [x] Document validation behavior and normalize error-message prefixes.

Automated verification:

```sh
./scripts/test
```

Expected result: 90 successful tests, 0 failures, and 0 errors.

Manual verification should call `setup()` with an unsupported presentation or
invalid grid column count, confirm the path-specific error, and then run
`:Wrd cheese` to confirm the preceding valid configuration remains active.

### Check-in 13: Explicit query outcomes — ready

- [x] Query execution returns distinct `ok`, `cancelled`, `empty`, `unusable`,
  and `failed` outcomes.
- [x] Cancellation remains silent and does not open a picker.
- [x] Empty and unusable normalized responses receive distinct informational
  messages.
- [x] Provider and normalization failures use error-level notifications rather
  than being reported as empty result sets.
- [x] Invalid methods and client contracts remain developer-facing errors.
- [x] Keep the existing primary query synchronous, but require optional query
  definition work to be asynchronous or lazy.

Automated verification:

```sh
./scripts/test
```

Expected result: 93 successful tests, 0 failures, and 0 errors.

Manual verification should confirm a normal live query still opens as before.
Provider failure and malformed-result branches are covered with offline fakes
because they should not be induced against the live Datamuse service.

### Check-in 14: Transactional picker transitions — ready

- [x] Keep the active word picker alive while follow, method, and direct-word
  replacement queries are prepared.
- [x] Close the old picker only after usable replacement results are ready.
- [x] Restore the old picker after cancellation, empty or unusable results, and
  provider or normalization failures.
- [x] Snapshot and close the word picker before method selection because
  Telescope closes existing pickers; reconstruct it when method selection is
  cancelled or cannot produce replacement results.
- [x] Preserve fuzzy text, filter, selection, preview, and insertion-target
  state when a transition cannot replace the picker.

Automated verification:

```sh
./scripts/test
```

Expected result: 98 successful tests, 0 failures, and 0 errors.

Manual verification should use a known-empty transition: open
`:Wrd parmesan`, press `<Tab>`, and select Synonym. The informational empty
result message should appear and the original parmesan picker should remain
usable with its previous state. Cancelling the method picker should likewise
return to the original prompt. A successful method selection should replace it.

### Check-in 15: Asynchronous current-query definition — ready

- [x] Add an optional asynchronous `describe` client capability using normalized
  Wrd results rather than provider-specific preview data.
- [x] Use Datamuse's query-echo spelling lookup and require an exact normalized
  word match.
- [x] Open the picker before starting the secondary request and refresh only
  the preview when it completes.
- [x] Cache exact definitions and misses by client instance and normalized word,
  coalescing duplicate in-flight requests and retrying failures.
- [x] Store definition state on the picker session so list and grid share one
  preview formatter.
- [x] Limit the query section independently while leaving all selected-result
  definitions visible.
- [x] Hide empty, failed, unsupported, and approximate query definitions without
  affecting the selected-result preview.

Automated verification:

```sh
./scripts/test
```

Expected result: 110 successful tests, 0 failures, and 0 errors.

Manual verification should open `:Wrd cheese` in list and grid modes. The
preview should initially show a short loading section, then `Query · cheese`
with up to two definitions above the independently changing selected result.
Changing methods should reuse the cached query definition; `/` and `<C-e>`
should request context for their new query words. Disabling
`picker.query_definition.enabled` should restore the selected-only preview.

### Check-in 16: Semantic preview colors — ready

- [x] Apply shared semantic highlights to list and grid previews.
- [x] Distinguish headings, words, ranks, bullets, part-of-speech labels,
  definition bodies, dividers, and muted status text.
- [x] Link Wrd groups to standard colorscheme groups without replacing explicit
  user customizations.
- [x] Document each public highlight group and provide an override example.
- [x] Test highlight spans, including multibyte definition bullets.

Automated verification:

```sh
./scripts/test
```

Expected result: 112 successful tests, 0 failures, and 0 errors.

Manual verification should open `:Wrd cheese` and compare the query and selected
sections. Words, part-of-speech labels, definition bodies, ranks, bullets, and
the divider should be visually distinguishable according to the active
colorscheme. Repeat in grid mode, then override `WrdPreviewWord` to confirm a
user-defined highlight wins over Wrd's default link.

### Check-in 17: Public-boundary characterization — ready

- [x] Verify Telescope extension registration exposes setup, direct run, and
  method selection through the public Wrd functions.
- [x] Verify the word picker sends all 100 ranked results through the shared
  presentation boundary without truncating or renumbering them.
- [x] Reconcile completed architecture and current-query milestones in this
  checklist.
- [x] Record that OneLook's popover footer is not part of the requested preview.

Automated verification:

```sh
./scripts/test
```

Expected result: 114 successful tests, 0 failures, and 0 errors.

This checkpoint has no intended UI change. For an optional public-interface
smoke test, load the Telescope extension and invoke both `run` and `methods`;
they should open the same word and method pickers as `:Wrd`.

### Check-in 18: Repeatable local quality checks — ready

- [x] Add a checked-in StyLua policy for every Lua source and test file.
- [x] Apply the policy repository-wide as a behavior-neutral mechanical change.
- [x] Add `./scripts/check` to validate formatting before running the full
  offline test suite.
- [x] Document the combined contributor check.
- [x] Verify locally with Neovim 0.13 nightly, Telescope 0.2.2, Plenary
  0.1.4+, and StyLua 2.5.2.

Automated verification:

```sh
./scripts/check
```

Expected result: clean formatting and 114 successful tests, with 0 failures
and 0 errors. This checkpoint is mechanical and has no intended UI change.

## Acceptance criteria

- With `cheese` and an empty prompt, the picker shows up to 100 numbered words
  in deterministic relevance order.
- Moving selection updates a wrapped definition preview.
- The preview presents the selected word and each definition as a distinct,
  readable item rather than exposing raw Datamuse prefixes or table values.
- The preview remains focused on definitions rather than reproducing OneLook's
  surrounding popover and metadata footer.
- Filtering to nouns, adjectives, verbs, or adverbs preserves relative rank and
  does not repeat the network request.
- Returning to All restores the complete ranked set and existing fuzzy prompt.
- Numeric navigation changes selection without inserting digits into the prompt
  or hiding unrelated results.
- Capabilities/help is available through a configurable picker mapping and
  accurately describes the actions enabled for that picker.
- Closing help restores the same fuzzy prompt, POS filter, selected word, and
  definition preview.
- The picker remains functional in narrow and wide terminals.
- Public clients can be adapted through a documented contract rather than
  depending on Datamuse-specific fields.
- Tests cover result shaping and picker state without accessing the network.

## Decision log

- 2026-09-20: Telescope v0.2.0 and Neovim v0.10.4 are the compatibility
  baseline.
- 2026-09-20: Treat 100 results as an explicit configurable default rather than
  relying on the Datamuse service default.
- 2026-09-20: Preserve rank outside Telescope's fuzzy `ordinal`; number
  navigation must not mutate the search prompt.
- 2026-09-20: Deliver a dense native Telescope list before deciding whether a
  custom multi-column grid is maintainable.
- 2026-09-20: Add behavior-preserving tests and refactor boundaries before
  implementing stateful filters or grid navigation.
- 2026-09-20: Treat Wrd capabilities/help as a bindable action with dynamic
  content derived from effective mappings and enabled picker features.
- 2026-09-20: Keep the help model renderer-independent and evaluate native
  floating windows against `plenary.popup`; avoid a nested picker unless it is
  demonstrably better at preserving state.
- 2026-09-20: `/` follows the highlighted result and makes it the new query
  word; `<Tab>` changes the method while retaining the current query word.
- 2026-09-20: Direct digits select original result ranks through a debounced
  picker-local buffer. Numeric navigation changes selection only; it never
  filters results or mutates the Telescope prompt.
- 2026-09-20: Use "side-by-side" for the current picker panes. Telescope calls
  this layout strategy `horizontal`, but the independently selectable word
  grid requested for density remains a separate prototype.
- 2026-09-20: POS filtering is local picker state. `<C-j>` cycles available
  categories, untagged entries appear only in All, refresh retains the fuzzy
  prompt, and original ranks remain navigation identities.
- 2026-09-20: Use `<F1>` for Wrd-specific capabilities and retain Telescope's
  generic mapping help separately. Render with native `nvim_open_win`; Plenary's
  wrappers do not simplify this focused, disposable window.
- 2026-09-20: Enter writes to a target captured before Telescope opens and also
  fills the unnamed and clipboard registers. `<C-y>` copies without editing;
  ambiguous blockwise replacement is intentionally copy-only.
- 2026-09-20: Harden a public Client v2 and normalized-result contract before
  grid work. Keep Datamuse decoding in its adapter, remove the unused legacy
  picker-client path, and prove portability with a fake provider that contains
  no Datamuse-shaped fields.
- 2026-09-27: Keep the primary result request synchronous for the current
  release. Any query-definition lookup must be asynchronous or lazy and must
  not delay the initial picker; revisit the primary transport separately.
- 2026-09-27: Treat OneLook's popover as a reference for readable definitions,
  not as a requirement to reproduce its source, origin, or concept footer.

## Research notes

- Reference page: <https://www.onelook.com/thesaurus/?s=cheese>
- OneLook returned 100 numbered "Most similar" results in five visual columns
  for the reference query.
- OneLook's `curd` popover shows six separate definitions, identifies
  Wiktionary as the definition source, links to word origin, and associates the
  word with the `Cheese making` concept cluster.
- The Datamuse response exposes `score`, `tags`, and `defs`; definitions encode
  part of speech as a prefix such as `n\t` or `adj\t`.
- The existing client already requests `dprf` metadata, including definitions
  and part-of-speech tags, but does not normalize or display most of it.
- Live verification on 2026-09-20 returned 100 `means_like` results and 47
  `sounds_like` results for `parmesan`; `synonym` legitimately returned none.
  Empty means/sounds-like pickers were therefore traced to picker transition
  state rather than the Datamuse service.
- Telescope's native model is one selectable entry per result row. A true word
  grid is an interaction change, not merely a display-format change.
- Plenary does not expose a debounce helper; its async sleep ultimately wraps
  `vim.defer_fn` and would add coroutine machinery without simplifying rank
  input. Its popup/window helpers were also evaluated for capabilities help;
  native `nvim_open_win` is smaller for this focused disposable window.
