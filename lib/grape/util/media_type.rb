# frozen_string_literal: true

module Grape
  module Util
    class MediaType
      attr_reader :type, :subtype,  :vendor, :version, :format

      VENDOR_VERSION_HEADER_REGEX = /\Avnd\.(?<vendor>[a-z0-9.\-_!^]+?)(?:-(?<version>[a-z0-9*.]+))?(?:\+(?<format>[a-z0-9*\-.]+))?\z/.freeze

      def initialize(type:, subtype:)
        @type = type
        @subtype = subtype
        VENDOR_VERSION_HEADER_REGEX.match(subtype) do |m|
          @vendor = m[:vendor]
          @version = m[:version]
          @format = m[:format]
        end
      end

      class << self

        def q_values(header)
          Rack::Utils.q_values(header)
        end

        def from_best_quality_media_type(header, available_media_types)
          parse(best_quality_media_type(header, available_media_types))
        end

        def parse(media_type)
          return if media_type.blank?

          type, subtype = media_type.split('/', 2)
          return if type.blank? && subtype.blank?

          new(type: type, subtype: subtype)
        end

        def match?(media_type)
          return if media_type.blank?

          subtype = media_type.split('/', 2).last
          return if subtype.blank?

          VENDOR_VERSION_HEADER_REGEX.match?(subtype)
        end

        def best_quality_media_type(header, available_media_types)
          header.blank? ? available_media_types.first : Rack::Utils.best_q_match(header, available_media_types)
        end
      end
    end
  end
end
