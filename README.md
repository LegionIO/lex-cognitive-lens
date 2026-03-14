# lex-cognitive-lens

Optical perspective filtering for LegionIO cognitive agents. Models cognitive viewpoints as lenses that can be stacked to produce combined magnification, distortion, and clarity effects on any content.

## What It Does

- Six lens types: `magnifying`, `wide_angle`, `fish_eye`, `polarized`, `telescopic`, `microscopic`
- Each lens has magnification, aperture, distortion, and clarity attributes
- Lenses can be focused/defocused, smudged/cleaned
- Stack multiple lenses: combined effects use diminishing-return magnification and weighted distortion blending
- `view_through_stack` applies the full pipeline to any content string
- `degrade_all` simulates environmental smudging across all lenses

## Usage

```ruby
# Create lenses
mag = runner.create_lens(lens_type: :magnifying, magnification: 2.5, aperture: 0.7,
                          distortion: 0.1, clarity: 0.9)
wide = runner.create_lens(lens_type: :wide_angle, magnification: 0.5, aperture: 0.9,
                           distortion: 0.2, clarity: 0.8)

# View content through a stack
result = runner.view_through_stack(
  lens_ids: [mag[:lens][:id], wide[:lens][:id]],
  content: 'The root cause is a missing validation layer'
)
# => { success: true, magnified_content: ..., distortion_applied: ..., clarity_score: ..., filtered_view: ... }

# Get clearest lenses
runner.clearest_lenses(limit: 3)

# Degrade all lenses over time
runner.degrade_all(rate: 0.05)

# Full report
runner.lens_report
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
