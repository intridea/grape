module Grape
  module Middleware
    class Base
      attr_reader :app, :env, :options

      # @param [Rack Application] app The standard argument for a Rack middleware.
      # @param [Hash] options A hash of options, simply stored for use by subclasses.
      def initialize(app, options = {})
        @app = app
        @options = default_options.merge(options)
      end

      def default_options
        {}
      end

      def call(env)
        dup.call!(env)
      end

      def call!(env)
        @env = env
        before

        @app_response = @app.call(@env)

        # Merge Headers from API into @header
        unless @header.nil?
          if @app_response.is_a?(Array) && @app_response[1].is_a?(Hash)
            @header.merge! @app_response[1]
          elsif @app_response.is_a?(Rack::Response)
            @header.merge! @app_response.headers
          end
        end

        res = after || @app_response

        # Merge Headers from After into return
        unless @header.nil?
          if res.is_a?(Rack::Response)
            @header.each do |k, v| res.headers[k] = v end
          elsif res.is_a?(Array) && res[1].is_a?(Hash)
            res[1].merge!(@header)
          end
        end

        res
      end

      def header(key = nil, val = nil)
        @header ||= {}
        val ? @header[key.to_s] = val : @header.delete(key.to_s)
      end

      def headers
        @header
      end

      # @abstract
      # Called before the application is called in the middleware lifecycle.
      def before
      end

      # @abstract
      # Called after the application is called in the middleware lifecycle.
      # @return [Response, nil] a Rack SPEC response or nil to call the application afterwards.
      def after
      end

      def response
        return @app_response if @app_response.is_a?(Rack::Response)
        Rack::Response.new(@app_response[2], @app_response[0], @app_response[1])
      end

      def content_type_for(format)
        HashWithIndifferentAccess.new(content_types)[format]
      end

      def content_types
        ContentTypes.content_types_for(options[:content_types])
      end

      def content_type
        content_type_for(env['api.format'] || options[:format]) || 'text/html'
      end

      def mime_types
        content_types.each_with_object({}) do |(k, v), types_without_params|
          types_without_params[k] = v.split(';').first
        end.invert
      end
    end
  end
end
