# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveLens
      module Runners
        module CognitiveLens
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def create_lens(lens_type:, magnification: nil, clarity: 1.0, distortion: nil, aperture: nil,
                          engine: nil, **)
            raise ArgumentError, "unknown lens_type: #{lens_type}" unless Helpers::Constants::LENS_TYPES.include?(lens_type)

            eng  = engine || lens_engine
            lens = eng.create_lens(
              lens_type:     lens_type,
              magnification: magnification,
              clarity:       clarity,
              distortion:    distortion,
              aperture:      aperture
            )
            Legion::Logging.debug "[cognitive_lens] created lens id=#{lens.id} type=#{lens_type} " \
                                  "mag=#{lens.magnification.round(2)} clarity=#{lens.clarity.round(2)}"
            { success: true, lens: lens.to_h }
          rescue ArgumentError => e
            Legion::Logging.warn "[cognitive_lens] create_lens failed: #{e.message}"
            { success: false, error: e.message }
          end

          def stack_lenses(lens_ids:, stack_id: nil, engine: nil, **)
            raise ArgumentError, 'lens_ids must be an array' unless lens_ids.is_a?(Array)

            eng    = engine || lens_engine
            result = eng.stack_lenses(lens_ids: lens_ids, stack_id: stack_id)
            Legion::Logging.debug "[cognitive_lens] stacked #{lens_ids.size} lenses stack_id=#{result[:stack_id]}"
            { success: true, stack_id: result[:stack_id], stack: result[:stack].to_h }
          rescue ArgumentError => e
            Legion::Logging.warn "[cognitive_lens] stack_lenses failed: #{e.message}"
            { success: false, error: e.message }
          end

          def view_through_stack(stack_id:, content:, engine: nil, **)
            eng    = engine || lens_engine
            result = eng.view_through_stack(stack_id: stack_id, content: content)
            { success: true, **result }
          rescue ArgumentError => e
            Legion::Logging.warn "[cognitive_lens] view_through_stack failed: #{e.message}"
            { success: false, error: e.message }
          end

          def degrade_all(rate: Helpers::Constants::SMUDGE_RATE_DEFAULT, engine: nil, **)
            eng    = engine || lens_engine
            result = eng.degrade_all!(rate: rate)
            Legion::Logging.debug "[cognitive_lens] degraded #{result[:degraded]} lenses at rate=#{rate}"
            { success: true, **result }
          end

          def lens_report(engine: nil, **)
            eng    = engine || lens_engine
            report = eng.lens_report
            { success: true, **report }
          end

          def clearest_lenses(limit: 3, engine: nil, **)
            eng = engine || lens_engine
            lenses = eng.clearest_lenses(limit: limit)
            { success: true, lenses: lenses }
          end

          def most_distorted(limit: 3, engine: nil, **)
            eng = engine || lens_engine
            lenses = eng.most_distorted(limit: limit)
            { success: true, lenses: lenses }
          end

          private

          def lens_engine
            @lens_engine ||= Helpers::LensEngine.new
          end
        end
      end
    end
  end
end
