# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class LengthValidator < Base
        def initialize(attrs, options, required, scope, **opts)
          @min = options[:min]
          @max = options[:max]

          super

          raise ArgumentError, "min #{@min} cannot be greater than max #{@max}" if !@min.nil? && !@max.nil? && @min > @max
        end

        def validate_param!(attr_name, params)
          param = params[attr_name]
          param = param.compact if param.respond_to?(:compact)

          return unless param.respond_to?(:length)
          return unless (!@min.nil? && param.length < @min) || (!@max.nil? && param.length > @max)

          raise Grape::Exceptions::Validation.new(params: [@scope.full_name(attr_name)], message: build_message)
        end

        def build_message
          if options_key?(:message)
            @option[:message]
          elsif @min && @max
            format I18n.t(:length, scope: 'grape.errors.messages'), min: @min, max: @max
          elsif @min
            format I18n.t(:length_min, scope: 'grape.errors.messages'), min: @min
          else
            format I18n.t(:length_max, scope: 'grape.errors.messages'), max: @max
          end
        end
      end
    end
  end
end
