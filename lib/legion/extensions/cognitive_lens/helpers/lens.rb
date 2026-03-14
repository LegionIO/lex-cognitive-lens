# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveLens
      module Helpers
        class Lens
          include Constants

          attr_reader :id, :lens_type, :magnification, :clarity, :distortion, :aperture,
                      :focus_target, :created_at

          def initialize(lens_type:, magnification: nil, clarity: 1.0, distortion: nil, aperture: nil)
            raise ArgumentError, "unknown lens_type: #{lens_type}" unless Constants::LENS_TYPES.include?(lens_type)

            defaults = Constants::LENS_DEFAULTS.fetch(lens_type)

            @id            = SecureRandom.uuid
            @lens_type     = lens_type
            @magnification = (magnification || defaults[:magnification]).clamp(0.1, 10.0).round(10)
            @clarity       = clarity.clamp(0.0, 1.0).round(10)
            @distortion    = (distortion || defaults[:distortion]).clamp(0.0, 1.0).round(10)
            @aperture      = (aperture || defaults[:aperture]).clamp(0.0, 1.0).round(10)
            @focus_target  = nil
            @created_at    = Time.now.utc
          end

          def focus!(target)
            @focus_target = target
            self
          end

          def defocus!
            @focus_target = nil
            self
          end

          def smudge!(rate = Constants::SMUDGE_RATE_DEFAULT)
            @clarity = (@clarity - rate.clamp(0.0, 1.0)).clamp(0.0, 1.0).round(10)
            self
          end

          def clean!(boost = Constants::CLEAN_BOOST_DEFAULT)
            @clarity = (@clarity + boost.clamp(0.0, 1.0)).clamp(0.0, 1.0).round(10)
            self
          end

          def sharp?
            @clarity >= Constants::CLARITY_SHARP_THRESHOLD
          end

          def blurry?
            @clarity <= Constants::CLARITY_BLURRY_THRESHOLD
          end

          def clarity_label
            Constants::CLARITY_LABELS.find { |range, _| range.cover?(@clarity) }&.last || :crystal
          end

          def magnification_label
            Constants::MAGNIFICATION_LABELS.find { |range, _| range.cover?(@magnification) }&.last || :extreme
          end

          def focused?
            !@focus_target.nil?
          end

          def depth_of_field
            # Larger aperture = shallower depth of field; higher magnification = shallower
            base = 1.0 - @aperture
            mag_factor = 1.0 / [magnification, 0.1].max
            ((base * 0.6) + (mag_factor * 0.4)).clamp(0.0, 1.0).round(10)
          end

          def to_h
            {
              id:                  @id,
              lens_type:           @lens_type,
              magnification:       @magnification,
              clarity:             @clarity,
              distortion:          @distortion,
              aperture:            @aperture,
              focus_target:        @focus_target,
              sharp:               sharp?,
              blurry:              blurry?,
              clarity_label:       clarity_label,
              magnification_label: magnification_label,
              depth_of_field:      depth_of_field
            }
          end
        end
      end
    end
  end
end
