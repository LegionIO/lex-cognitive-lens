# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveLens
      module Helpers
        class LensEngine
          include Constants

          attr_reader :lenses, :stacks

          def initialize
            @lenses = {}
            @stacks = {}
          end

          def create_lens(lens_type:, magnification: nil, clarity: 1.0, distortion: nil, aperture: nil, **)
            lens = Lens.new(
              lens_type:     lens_type,
              magnification: magnification,
              clarity:       clarity,
              distortion:    distortion,
              aperture:      aperture
            )
            @lenses[lens.id] = lens
            lens
          end

          def stack_lenses(lens_ids:, stack_id: nil, **)
            stack_id ||= SecureRandom.uuid
            stack = LensStack.new

            lens_ids.each do |lid|
              lens = @lenses[lid]
              raise ArgumentError, "lens not found: #{lid}" unless lens

              stack.push_lens(lens)
            end

            @stacks[stack_id] = stack
            { stack_id: stack_id, stack: stack }
          end

          def view_through_stack(stack_id:, content:, **)
            stack = @stacks[stack_id]
            raise ArgumentError, "stack not found: #{stack_id}" unless stack

            result = stack.view_through(content)
            Legion::Logging.debug "[cognitive_lens] view_through stack=#{stack_id} " \
                                  "perceived=#{result[:perceived].round(4)} " \
                                  "magnification=#{result[:combined_magnification].round(2)} " \
                                  "distortion=#{result[:combined_distortion].round(2)} " \
                                  "clarity=#{result[:stack_clarity].round(2)}"
            result
          end

          def degrade_all!(rate: Constants::SMUDGE_RATE_DEFAULT)
            @lenses.each_value { |l| l.smudge!(rate) }
            { degraded: @lenses.size, rate: rate }
          end

          def clearest_lenses(limit: 3)
            @lenses.values
                   .sort_by { |l| -l.clarity }
                   .first(limit)
                   .map(&:to_h)
          end

          def most_distorted(limit: 3)
            @lenses.values
                   .sort_by { |l| -l.distortion }
                   .first(limit)
                   .map(&:to_h)
          end

          def lens_report
            return { lens_count: 0, stack_count: 0, lenses: [], stacks: [] } if @lenses.empty?

            avg_clarity    = (@lenses.values.sum(&:clarity) / @lenses.size).round(10)
            avg_distortion = (@lenses.values.sum(&:distortion) / @lenses.size).round(10)

            {
              lens_count:     @lenses.size,
              stack_count:    @stacks.size,
              avg_clarity:    avg_clarity,
              avg_distortion: avg_distortion,
              sharp_count:    @lenses.values.count(&:sharp?),
              blurry_count:   @lenses.values.count(&:blurry?),
              lenses:         @lenses.values.map(&:to_h),
              stacks:         @stacks.transform_values(&:to_h)
            }
          end
        end
      end
    end
  end
end
