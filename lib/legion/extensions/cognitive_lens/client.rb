# frozen_string_literal: true

require 'legion/extensions/cognitive_lens/helpers/constants'
require 'legion/extensions/cognitive_lens/helpers/lens'
require 'legion/extensions/cognitive_lens/helpers/lens_stack'
require 'legion/extensions/cognitive_lens/helpers/lens_engine'
require 'legion/extensions/cognitive_lens/runners/cognitive_lens'

module Legion
  module Extensions
    module CognitiveLens
      class Client
        include Runners::CognitiveLens

        def initialize(**)
          @lens_engine = Helpers::LensEngine.new
        end

        private

        attr_reader :lens_engine
      end
    end
  end
end
