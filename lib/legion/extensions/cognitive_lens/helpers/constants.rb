# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveLens
      module Helpers
        module Constants
          LENS_TYPES = %i[magnifying wide_angle fish_eye polarized telescopic microscopic].freeze

          DISTORTION_TYPES = %i[none barrel pincushion mustache wave spiral].freeze

          MAX_LENSES = 8

          CLARITY_LABELS = [
            [0.0..0.2,  :opaque],
            [0.2..0.4,  :foggy],
            [0.4..0.6,  :hazy],
            [0.6..0.8,  :clear],
            [0.8..1.0,  :crystal]
          ].freeze

          MAGNIFICATION_LABELS = [
            [0.1..0.5,  :micro],
            [0.5..1.0,  :normal],
            [1.0..2.0,  :zoom],
            [2.0..5.0,  :telephoto],
            [5.0..10.0, :extreme]
          ].freeze

          # Default optical properties per lens type
          LENS_DEFAULTS = {
            magnifying:  { magnification: 2.0, aperture: 0.6, distortion: 0.1 },
            wide_angle:  { magnification: 0.5, aperture: 0.9, distortion: 0.2 },
            fish_eye:    { magnification: 0.3, aperture: 1.0, distortion: 0.8 },
            polarized:   { magnification: 1.0, aperture: 0.4, distortion: 0.0 },
            telescopic:  { magnification: 8.0, aperture: 0.3, distortion: 0.15 },
            microscopic: { magnification: 9.0, aperture: 0.5, distortion: 0.05 }
          }.freeze

          # Smudge degrades clarity; clean restores it
          SMUDGE_RATE_DEFAULT    = 0.05
          CLEAN_BOOST_DEFAULT    = 0.1
          CLARITY_SHARP_THRESHOLD = 0.7
          CLARITY_BLURRY_THRESHOLD = 0.35

          # Stack combination weights
          STACK_MAGNIFICATION_EXPONENT = 0.8 # sub-linear compounding prevents extremes
          STACK_DISTORTION_BLEND        = 0.6  # weight toward worst distortion
          STACK_CLARITY_DECAY           = 0.9  # each additional lens costs 10% clarity
        end
      end
    end
  end
end
