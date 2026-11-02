# frozen_string_literal: true

module Grape
  module ErrorFormatter
    # Renders an error as an RFC 9457 problem details object, labelled
    # +application/problem+json+:
    #
    #   error_formatter :json, Grape::ErrorFormatter::ProblemJson
    #
    #   error!('Your balance is 30, but that costs 50.', 403)
    #   # {"type":"about:blank","title":"Forbidden","status":403,"detail":"Your balance is 30, but that costs 50."}
    #
    # A String message is the +detail+. A Hash message brings members of its
    # own, a +type+, +title+, +instance+ or any extension, over the defaults.
    # +status+ is always the response's, since RFC 9457 has the body repeat
    # the status the response carries. A validation failure lists its
    # parameters in an +errors+ extension shaped as
    # {Grape::Exceptions::ValidationErrors#as_json}.
    class ProblemJson < Json
      ABOUT_BLANK = 'about:blank'

      class << self
        def content_type = 'application/problem+json'

        def call(error:, env: nil, include_backtrace: false, include_original_exception: false)
          problem = problem_for(error, present(error.message, env))
          problem['backtrace'] = error.backtrace if include_backtrace && error.backtrace.present?
          problem['original_exception'] = error.original_exception.inspect if include_original_exception && error.original_exception
          format_structured_message(problem)
        end

        private

        # +about:blank+ means the problem is what the status says it is, so
        # its title is the status phrase. A status Rack has no phrase for
        # goes without one.
        def problem_for(error, message)
          status = Rack::Utils.status_code(error.status)
          problem = { 'type' => ABOUT_BLANK, 'title' => Rack::Utils::HTTP_STATUS_CODES[status], 'status' => status }.compact
          members(message).each { |name, value| problem[name.to_s] = value }
          problem['status'] = status

          validation_errors = validation_errors(message, error.original_exception)
          problem['errors'] ||= validation_errors.as_json if validation_errors
          problem
        end

        # An error with no message, +error!(nil, 404)+ say, reaches here as an
        # empty String, and leaves +detail+ out rather than empty.
        def members(message)
          return message if message.is_a?(Hash)
          return { 'detail' => message.message } if message.is_a?(Exceptions::ValidationErrors)
          return {} if message.is_a?(String) && message.empty?

          { 'detail' => ensure_utf8(message) }
        end

        # A validation failure Grape answered itself carries its message as a
        # String and the exception as +original_exception+; one a
        # +rescue_from+ handed to +error!+ is the message.
        def validation_errors(message, original_exception)
          return message if message.is_a?(Exceptions::ValidationErrors)

          original_exception if original_exception.is_a?(Exceptions::ValidationErrors)
        end
      end
    end
  end
end
