module Grape
  module Validations
    class MultipleParamsBase < Base
      attr_reader :scoped_params

      def validate!(params)
        @scoped_params = [@scope.params(params)].flatten
        params
      end

      private

      def scope_requires_params
        @scope.required? || scoped_params.any?(&:any?)
      end

      def keys_in_common(resource_params)
        return [] unless resource_params.is_a?(Hash)
        (all_keys & resource_params.stringify_keys.keys).map(&:to_s)
      end

      def undeclared_keys(resource_params)
        return [] unless resource_params.is_a?(Hash)
        allowed_keys = @scope.declared_params.map do |k|
          k.is_a?(Hash) ? k.keys.first.to_s : k.to_s
        end
        (resource_params.stringify_keys.keys - allowed_keys)
      end

      def all_keys
        attrs.map(&:to_s)
      end
    end
  end
end
