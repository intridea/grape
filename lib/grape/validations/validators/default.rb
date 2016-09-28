module Grape
  module Validations
    class DefaultValidator < Base
      def initialize(attrs, options, required, fail_fast, scope)
        @default = options
        super
      end

      def validate_param!(attr_name, params)
        return if params.key? attr_name
        params[attr_name] = if @default.is_a? Proc
                              @default.call
                            elsif @default.frozen? || !duplicatable?(@default)
                              @default
                            else
                              duplicate(@default)
                            end
      end

      def validate!(params)
        attrs = AttributesIterator.new(self, @scope, params)
        attrs.each do |resource_params, attr_name|
          if resource_params.is_a?(Hash) && resource_params[attr_name].nil?
            validate_param!(attr_name, resource_params)
          end
        end
      end

      private

      # return true if we might be able to dup this object
      def duplicatable?(obj)
        !obj.nil? &&
          obj != true &&
          obj != false &&
          !obj.is_a?(Symbol) &&
          !obj.is_a?(Numeric)
      end

      # make a best effort to dup the object
      def duplicate(obj)
        obj.dup
      rescue TypeError
        obj
      end
    end
  end
end
