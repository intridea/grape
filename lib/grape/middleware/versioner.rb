# frozen_string_literal: true

# Versioners set env['api.version'] when a version is defined on an API and
# on the requests. The current methods for determining version are:
#
#   :header - version from HTTP Accept header.
#   :path   - version from uri. e.g. /v1/resource
#   :param  - version from uri query string, e.g. /v1/resource?apiver=v1
#
# See individual classes for details.
module Grape
  module Middleware
    module Versioner
      module_function

      # @param strategy [Symbol] :path, :header, :accept_version_header or :param
      # @return a middleware class based on strategy
      def using(strategy)
        Grape::Middleware::Versioner.const_get(:"#{strategy.to_s.classify}")
      rescue NameError
        raise Grape::Exceptions::InvalidVersionerOption.new(strategy)
      end
    end
  end
end
