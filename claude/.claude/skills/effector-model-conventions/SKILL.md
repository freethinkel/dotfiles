---
name: effector-model-conventions
description: Use when writing, reviewing, or refactoring Effector state management code (stores, events, effects, sample) - covers naming, sample-only data flow, api/model/component layering, useUnit binding, and fork-based testing.
---

# Effector Model Conventions

## Naming
- Stores: `$storeName` — Events: `eventName` — Effects: `eventNameFx` — Gates: `createGate()`

## Data flow: `sample` only
- NEVER `.on()` or `.watch()`. Use `sample({ clock, source, filter, fn, target })` (keep this key order).
- `.watch()` only as a documented last resort for logging/debugging.
- NEVER `store.getState()` — not in a component, not in a `sample`, not inside an effect either.
  State reaches an effect as a **parameter**: `attach({ source: $store, effect })` when the effect
  is called with its own params, `sample({ clock, source, fn, target })` when it's triggered.
  (`scope.getState($store)` in fork-based tests is the one exception — see Testing.)
- NO `forward()` / `guard()` — use `sample`.

```typescript
// ❌
$teams.on(teamDeleteFx.done, (teams, { params }) => teams.filter(t => t.id !== params))

// ✅
sample({
  clock: teamDeleteFx.done,
  source: $teams,
  fn: (teams, { params }) => teams.filter(t => t.id !== params),
  target: $teams
})
```

```typescript
// ❌ — the effect reaches back into the store
const renameFx = createEffect((name: string) => {
  const { user } = $profile.getState()
  ...
})

// ✅ — the store is a source, the effect just gets both halves as arguments
const renameFx = attach({
  source: $profile,
  effect({ user }, name: string) { ... },
})
sample({ clock: renameRequested, target: renameFx })
```

## Layering
- `*.api.ts` — ONLY `createEffect`, no business logic. Export as namespace: `export * as fooApi from "./foo.api"`.
- `*.model.ts` — stores, events, `sample` wiring. Import API as a namespace; `attach()` its effects if params/mapping are needed. Export the model as a namespace too.
- `*.integrations.ts` — cross-cutting side effects.
- Model/api/integrations files are side-effect modules — don't rely on explicit imports for their side effects to run (relevant for bundlers that tree-shake).

## File structure of `*.model.ts`
Top to bottom, in this order:
1. **Stores** — all `createStore` declarations.
2. **Events** — all `createEvent` declarations.
3. **Effects** — all `createEffect`/`attach` declarations (if any).
4. **Business logic** — every `sample` and `reset` call (see below).

Don't interleave a store's own wiring right after its declaration — group by kind first, wire
everything at the bottom. This keeps the top of the file a flat, scannable list of the model's
shape, and the bottom as the single place that explains behavior.

## Resetting stores: `reset()` from patronum, not `.reset()` chained on `createStore`
- `createStore(...).reset(clock)` puts a piece of business logic at the top of the file, next to
  the store shape, instead of at the bottom with the rest of the wiring.
- Use patronum's `reset({ clock, target })` instead of the store's own `.reset(...)` method — same
  shape as `sample`, so resets read like the rest of the business-logic section instead of a
  one-off store method. Declare the store bare at the top; call `reset({ clock, target: $store })`
  at the bottom, with the `sample`s.

```typescript
// ❌
const $error = createStore<string | null>(null).reset(formSubmitted)

// ❌ — also avoid, same reason: wiring stuck at the store declaration
const $error = createStore<string | null>(null)
$error.reset(formSubmitted)

// ✅ — top: stores
import { reset } from 'patronum'
const $error = createStore<string | null>(null)
// ...events, effects...
// ✅ — bottom: business logic
reset({ clock: formSubmitted, target: $error })
```

## Don't extract a helper used by only one `createEffect`
- A standalone `function`/`const` declared solely so a single `createEffect` right after it can
  call it adds a name and a jump without adding reuse — inline its body straight into the effect.
- Applies regardless of call count *inside that one effect*: called once → unroll it at the call
  site; called more than once within the same effect → keep it as a small function declared
  *inside* the effect callback, not at module scope.
- Doesn't apply to helpers that are: reused by more than one effect or exported for tests/other
  modules (keep those at module scope), recursive tree-walkers or anything carrying its own
  substantial "why"-comment worth reading as a standalone named unit (extraction earns its keep
  there — the name and doc comment are the point, not a smell).

```typescript
// ❌ — queueAccent exists only to be handed straight to accentFx
function queueAccent(face: Face, color: string | null) {
  const flagged = color ? accentFlaggedResources(face) : null
  return runQueued(face, flagged, color)
}
const accentFx = createEffect(({ face, color }: Params) => queueAccent(face, color))

// ✅ — inlined; no wrapper, no extra name to chase
const accentFx = createEffect(({ face, color }: Params) => {
  const flagged = color ? accentFlaggedResources(face) : null
  return runQueued(face, flagged, color)
})

// ✅ — called twice within the same effect: local function, still not module-scoped
const addWidgetFx = createEffect(async ({ kind, files }: Params) => {
  const metaWith = (id: number, max: number) => { /* ... */ }
  // ...uses metaWith(...) twice below...
})
```

## Binding in components (`useUnit`)
- Every store gets its own `useUnit` call: `const value = useUnit($value)`.
- ALL events/effects are grouped into one `actions` object: `const actions = useUnit({ handleChange, submit: submitFx })`, called as `actions.x(...)`.
- Never call a raw event/effect directly in JSX (`onClick={submitFx}` ❌).
- Never bundle stores into the same `useUnit` object as events.

```typescript
// ❌
onClick={submitFx}
const { $value, handleChange } = useUnit({ $value, handleChange })

// ✅
const value = useUnit($value)
const actions = useUnit({ handleChange })
```

## Components/UI layer never call effects
- `createEffect` results (`xxxFx`) are an implementation detail of the model. Components — and any
  UI-layer code, framework-agnostic (React, Svelte, Vue, ...) — never import or invoke an effect
  directly, not even wrapped in `useUnit`'s `actions` object.
- A component only dispatches a plain event describing user intent (`loginRequested(payload)`,
  `saveRequested()`). The model decides which effect that triggers via `sample({ clock: event,
  target: xxxFx })` (add `filter`/`fn`/`source` as needed) — that's also where multiple effects,
  extra state reads, or conditional dispatch belong, invisible to the component.
- `.pending` is the one exception: components read `xxxFx.pending` (via `useUnit`/`$store`
  subscription) for busy state — that's a store read, not an invocation.
- Rationale: keeps the "which side effect runs" decision entirely in the model (testable via
  `fork`/`allSettled` on the event, no component involved) and stops effects from leaking into the
  view layer as a second, uncontrolled way to trigger business logic alongside events.

```typescript
// ❌ — model/auth.model.ts
export const loginFx = createEffect(...)

// component
const actions = useUnit({ login: loginFx }) // or Svelte: const { loginFx } = authModel
actions.login({ email, password })

// ✅ — model/auth.model.ts
const loginRequested = createEvent<{ email: string; password: string }>()
const loginFx = createEffect(...) // not exported
sample({ clock: loginRequested, target: loginFx })
export { loginRequested }

// component
const actions = useUnit({ login: loginRequested }) // or Svelte: const { loginRequested } = authModel
actions.login({ email, password })
```

## Components never call `.watch()` either
- `.watch()`/`.subscribe()` on an event or store from inside a component is the same problem as
  calling an effect directly: it's business logic — "when X happens, do Y" — leaking into the view
  layer instead of living in the model. This includes the common `$effect(() => event.watch(...))`
  (Svelte) / `useEffect` + manual `.watch()` (React) pattern for one-shot reactions like navigating
  away, closing a dialog, or forwarding an error into another store.
- Move the reaction into the model as `sample`s, and have the component either:
  - dispatch a request event and stop caring what happens next (the model owns the follow-up), or
  - read a plain store the model already derived (`$dialogOpen`, `$rightPanel`, ...) via normal
    store subscription (`useUnit`/`$store`) — never via `.watch()`.
- When two call sites share one effect but need different done/error handling (e.g. a "save draft"
  button and a "publish" dialog both hitting the same `saveFx`), give each its own request event and
  a small `$xKind` store in the model to route `effect.done`/`effect.failData` back to the right
  place — see the worked example below. Without this, a shared reaction fires for every caller, not
  just the one that's relevant (e.g. a dialog closing itself because a *different* button's save
  succeeded).
- Navigation is not a component-only concern — a router's `goto`/`navigate` can be called from a
  plain `.ts` model file (wrapped in its own `createEffect`, wired with `sample` like any other side
  effect) just as well as from a component.

```typescript
// ❌ — component
const { publishRequested, publishSaved, $publishErr } = marketModel
$effect(() => publishSaved.watch(() => { open = false; goto('/market') }))
$effect(() => { if ($publishErr) { showError($publishErr); open = false } })

// ✅ — model/market.model.ts
const $saveKind = createStore<'draft' | 'publish' | null>(null)
sample({ clock: publishRequested, fn: () => 'publish' as const, target: $saveKind })
export const $publishDialogOpen = createStore(false)
sample({ clock: saveFx.done, source: $saveKind, filter: k => k === 'publish', fn: () => false, target: $publishDialogOpen })
sample({ clock: saveFx.failData, source: $saveKind, filter: k => k === 'publish', fn: () => false, target: $publishDialogOpen })
const navigateToMarketFx = createEffect(() => goto('/market'))
sample({ clock: saveFx.done, source: $saveKind, filter: k => k === 'publish', target: navigateToMarketFx })

// component — just reads state and dispatches, no .watch() anywhere
const { publishRequested, $publishDialogOpen } = marketModel
```

## Form state
- Form state lives in Effector stores in the model, not `useState`.
- Events read data from model stores, not from payloads the component passes in.

## Testing (fork API)
- Isolate each test with `fork()`; trigger with `allSettled()`.
- Mock effects via `fork({ handlers: [[apiEffectFx, mockFn]] })` — mock at the API layer, not the model.
- Seed state via `fork({ values: [[$store, value]] })`; assert with `scope.getState($store)`.
- Never create fake stores/events inside a test — import and exercise the real model.
- Don't test that `fork({ values })` echoes back what you set, and don't test default/initial store values — only test logic that transforms state.

```typescript
test("Should filter team on delete", async () => {
  const scope = fork({ values: [[model.$teams, [{ id: 1 }, { id: 2 }]]] })
  await allSettled(model.teamDeleteFx.done, { scope, params: { params: 1 } })
  expect(scope.getState(model.$teams)).toEqual([{ id: 2 }])
})
```

## Common mistakes
| Mistake | Fix |
|---|---|
| `.on()`/`.watch()` for data flow | `sample` |
| `$store.getState()` anywhere (an effect body included) | Pass the state in: `attach({ source: $store, effect })`, or `sample`'s `source` |
| Raw event/effect in JSX | Group into `actions` via `useUnit` |
| Component/UI code calls an effect (`xxxFx(...)`), even via `actions` | Export a plain event instead; wire `sample({ clock: event, target: xxxFx })` in the model |
| Component uses `.watch()`/`.subscribe()` for a one-shot reaction (navigate, close dialog, forward an error) | Move the reaction into the model as `sample`s; component reads a derived store instead |
| Two callers share one effect and need different done/error handling | Separate request events + a small `$xKind` store in the model to route `done`/`failData` per caller |
| Store + events in one `useUnit` call | Separate `useUnit` per store, one for all actions |
| Form data in `useState` | Store in an Effector store, read via `sample`/model |
| Fake stores/events in tests | Import and test the real model with `fork` |
| `.reset()` chained on `createStore` (or called standalone on the store) | Declare store bare; `reset({ clock, target })` from patronum at the bottom with the other wiring |
| Stores/events/effects/samples interleaved in a model file | Group by kind: stores, then events, then effects, then samples |
| Helper function extracted only to be called by one `createEffect` right after it | Inline into the effect callback (or as a local fn inside it if called >1x there) |
