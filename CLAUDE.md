# lex-cognitive-lens

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Optical lens metaphor for cognitive perspective filtering. Individual lenses each have a type (magnifying, wide-angle, fish-eye, polarized, telescopic, microscopic), magnification factor, aperture, distortion level, and clarity. Lenses are stacked in a `LensStack`; viewing content through the stack applies sequential magnification, distortion blending, and clarity decay to produce a filtered view.

## Gem Info

- **Gem name**: `lex-cognitive-lens`
- **Module**: `Legion::Extensions::CognitiveLens`
- **Version**: `0.1.0`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/cognitive_lens/
  version.rb
  client.rb
  helpers/
    constants.rb
    lens.rb
    lens_stack.rb
    lens_engine.rb
  runners/
    cognitive_lens.rb
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `LENS_TYPES` | `%i[magnifying wide_angle fish_eye polarized telescopic microscopic]` | Valid lens types |
| `DISTORTION_TYPES` | symbol array | Valid distortion types |
| `MAX_LENSES` | `8` | Maximum lenses in a stack |
| `LENS_DEFAULTS` | hash keyed by type | Per-type default magnification/aperture/distortion values |
| `SMUDGE_RATE_DEFAULT` | `0.05` | Default clarity reduction per smudge |
| `CLEAN_BOOST_DEFAULT` | `0.1` | Default clarity boost per clean |
| `STACK_MAGNIFICATION_EXPONENT` | `0.8` | Exponent for combined magnification diminishing returns |
| `STACK_DISTORTION_BLEND` | `0.6` | Weight for blending distortions in stack |
| `STACK_CLARITY_DECAY` | `0.9` | Per-lens clarity multiplier when stacking |
| `CLARITY_LABELS` | range hash | From `:opaque` to `:crystal_clear` |
| `MAGNIFICATION_LABELS` | range hash | From `:unity` to `:extreme` |

## Helpers

### `Helpers::Lens`
Individual lens with `id`, `lens_type`, `magnification`, `aperture`, `distortion`, and `clarity`.

- `focus!` — reduces distortion (improves resolution)
- `defocus!` — increases distortion
- `smudge!(rate)` — reduces clarity
- `clean!(boost)` — increases clarity
- `sharp?` — distortion below threshold
- `blurry?` — distortion above threshold
- `clarity_label` / `magnification_label`
- `focused?` — aperture above threshold
- `depth_of_field` — computed from aperture
- `to_h`

### `Helpers::LensStack`
Ordered stack of lenses (up to `MAX_LENSES`).

- `push_lens(lens)` — appends lens to stack
- `pop_lens` — removes and returns last lens
- `combined_magnification` — product of all lens magnifications with `STACK_MAGNIFICATION_EXPONENT` diminishing returns
- `combined_distortion` — weighted blend of all lens distortions using `STACK_DISTORTION_BLEND`
- `stack_clarity` — product of all lens clarities decayed by `STACK_CLARITY_DECAY` per lens
- `view_through(content)` — applies magnification → distortion → clarity pipeline, returns structured result hash

### `Helpers::LensEngine`
Top-level store for lenses and stacks.

- `create_lens(lens_type:, magnification:, aperture:, distortion:, clarity:)` → lens
- `stack_lenses(lens_ids:)` → `LensStack` built from specified IDs
- `view_through_stack(lens_ids:, content:)` → filtered view result
- `degrade_all!(rate:)` → smudges all lenses
- `clearest_lenses(limit:)` → top N by clarity
- `most_distorted(limit:)` → top N by distortion
- `lens_report` → aggregate stats

## Runners

Module: `Runners::CognitiveLens`

| Runner Method | Description |
|---|---|
| `create_lens(lens_type:, ...)` | Register a new lens |
| `stack_lenses(lens_ids:)` | Build a stack from existing lenses |
| `view_through_stack(lens_ids:, content:)` | Apply lens stack to content |
| `degrade_all(rate:)` | Smudge all lenses |
| `lens_report` | Aggregate lens statistics |
| `clearest_lenses(limit:)` | Top N clearest lenses |
| `most_distorted(limit:)` | Top N most distorted lenses |

All runners return `{success: true/false, ...}` hashes.

## Integration Points

- No direct dependencies on other agentic LEX gems
- Can integrate with `lex-tick` `action_selection` phase to apply perspective filtering before decisions
- Lens stacks can model different cognitive modes (zoomed-in analysis vs wide-angle overview)
- Clarity scores can inform `lex-emotion` arousal when clarity drops below a threshold

## Development Notes

- `Client` instantiates `@lens_engine = Helpers::LensEngine.new`
- `MAX_LENSES = 8` is a hard cap on stack depth; attempts to push beyond this return an error
- `LENS_DEFAULTS` provides per-type starting values so different lens types behave differently at creation
- `view_through` returns a hash including `:magnified_content`, `:distortion_applied`, `:clarity_score`, and `:filtered_view`
- Clarity decay compounds multiplicatively through a stack (`0.9^n` for n lenses)
