module Grape
  module Validations
    class PresenceValidator < Base
      def validate_param!(attr_name, params)
        return if params.respond_to?(:key?) && !params[attr_name].nil?
        raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: message(:presence)
      end
    end
  end
end
