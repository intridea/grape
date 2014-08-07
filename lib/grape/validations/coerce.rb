module Grape
  class API
    Boolean = Virtus::Attribute::Boolean # rubocop:disable ConstantName
  end

  module Validations
    class CoerceValidator < SingleOptionValidator
      def validate_param!(attr_name, params)
        raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message_key: :coerce unless params.is_a? Hash

        # If the parameter is required and no such key was passed in, do
        # nothing here since the "required" validator will mark it as invalid later on.
        # Note that his does not apply if type == 'Array', since that would mess with array_name[key] errors downstream
        return if params['route_info'] &&
                  (params['route_info'].options[:params][attr_name.to_s][:required] == true) &&
                  (params['route_info'].options[:params][attr_name.to_s][:type] != 'Array') &&
                  (!params.has_key?(attr_name))

        new_value = coerce_value(@option, params[attr_name])
        if valid_type?(new_value)
          params[attr_name] = new_value
        else
          raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message_key: :coerce
        end
      end

      class InvalidValue; end

      private

      def _valid_array_type?(type, values)
        values.all? do |val|
          _valid_single_type?(type, val)
        end
      end

      def _valid_single_type?(klass, val)
        # no longer allowing nil as a valid type if a different type specified
        return false if val.nil?
        if klass == Virtus::Attribute::Boolean
          val.is_a?(TrueClass) || val.is_a?(FalseClass)
        elsif klass == Rack::Multipart::UploadedFile
          val.is_a?(Hashie::Mash) && val.key?(:tempfile)
        else
          val.is_a?(klass)
        end
      end

      def valid_type?(val)
        if @option.is_a?(Array)
          _valid_array_type?(@option[0], val)
        else
          _valid_single_type?(@option, val)
        end
      end

      def coerce_value(type, val)
        # Don't coerce things other than nil to Arrays or Hashes
        return val || [] if type == Array
        return val || {} if type == Hash

        converter = Virtus::Attribute.build(type)
        converter.coerce(val)

      # not the prettiest but some invalid coercion can currently trigger
      # errors in Virtus (see coerce_spec.rb:75)
      rescue
        InvalidValue.new
      end
    end
  end
end
