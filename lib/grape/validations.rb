# frozen_string_literal: true

module Grape
  module Validations
    extend Grape::Util::Registry

    module_function

    def require_validator(short_name)
      raise Grape::Exceptions::UnknownValidator, short_name unless registry.key?(short_name)

      registry[short_name]
    end
  end
end
