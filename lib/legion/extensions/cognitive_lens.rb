# frozen_string_literal: true

require 'securerandom'

require_relative 'cognitive_lens/version'
require_relative 'cognitive_lens/helpers/constants'
require_relative 'cognitive_lens/helpers/lens'
require_relative 'cognitive_lens/helpers/lens_stack'
require_relative 'cognitive_lens/helpers/lens_engine'
require_relative 'cognitive_lens/runners/cognitive_lens'
require_relative 'cognitive_lens/client'

module Legion
  module Extensions
    module CognitiveLens
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
