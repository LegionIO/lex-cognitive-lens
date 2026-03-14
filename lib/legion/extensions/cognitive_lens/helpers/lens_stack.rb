# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveLens
      module Helpers
        class LensStack
          include Constants

          attr_reader :lenses

          def initialize
            @lenses = []
          end

          def push_lens(lens)
            raise ArgumentError, 'expected a Lens instance' unless lens.is_a?(Lens)
            raise ArgumentError, "stack is full (max #{Constants::MAX_LENSES})" if @lenses.size >= Constants::MAX_LENSES

            @lenses << lens
            self
          end

          def pop_lens
            @lenses.pop
          end

          def size
            @lenses.size
          end

          def empty?
            @lenses.empty?
          end

          def combined_magnification
            return 1.0 if @lenses.empty?

            # Sub-linear compounding via exponent to avoid extreme values
            base = @lenses.reduce(1.0) { |acc, l| acc * l.magnification }
            base**Constants::STACK_MAGNIFICATION_EXPONENT
          end

          def combined_distortion
            return 0.0 if @lenses.empty?

            max_dist   = @lenses.map(&:distortion).max
            mean_dist  = @lenses.sum(&:distortion) / @lenses.size
            # Blend toward worst distortion
            ((max_dist * Constants::STACK_DISTORTION_BLEND) +
             (mean_dist * (1.0 - Constants::STACK_DISTORTION_BLEND))).clamp(0.0, 1.0).round(10)
          end

          def stack_clarity
            return 1.0 if @lenses.empty?

            base = @lenses.map(&:clarity).min
            decay = Constants::STACK_CLARITY_DECAY**(@lenses.size - 1)
            (base * decay).clamp(0.0, 1.0).round(10)
          end

          # Apply all lenses to a content value (numeric 0.0-1.0) or hash with :value key
          def view_through(content)
            return content if @lenses.empty?

            raw_value = extract_value(content)
            magnified  = apply_magnification(raw_value)
            distorted  = apply_distortion(magnified)
            filtered   = apply_clarity(distorted)

            {
              original:               raw_value,
              perceived:              filtered.round(10),
              combined_magnification: combined_magnification.round(10),
              combined_distortion:    combined_distortion.round(10),
              stack_clarity:          stack_clarity.round(10),
              lens_count:             @lenses.size,
              focus_active:           @lenses.any?(&:focused?)
            }
          end

          def to_h
            {
              lens_count:             @lenses.size,
              combined_magnification: combined_magnification.round(10),
              combined_distortion:    combined_distortion.round(10),
              stack_clarity:          stack_clarity.round(10),
              lenses:                 @lenses.map(&:to_h)
            }
          end

          private

          def extract_value(content)
            if content.is_a?(Hash)
              content.fetch(:value, 0.5).clamp(0.0, 1.0)
            else
              content.to_f.clamp(0.0, 1.0)
            end
          end

          def apply_magnification(value)
            mag = combined_magnification
            # Magnification centers around 0.5; scale distance from center
            center    = 0.5
            distance  = value - center
            (center + (distance * mag)).clamp(0.0, 1.0)
          end

          def apply_distortion(value)
            dist = combined_distortion
            return value if dist.zero?

            # Barrel distortion pushes values toward extremes
            noise = (value - 0.5).abs * dist * 0.2
            sign  = value >= 0.5 ? 1 : -1
            (value + (sign * noise)).clamp(0.0, 1.0)
          end

          def apply_clarity(value)
            clarity = stack_clarity
            # Low clarity pulls perceived value toward neutral (0.5)
            center = 0.5
            (center + ((value - center) * clarity)).clamp(0.0, 1.0)
          end
        end
      end
    end
  end
end
