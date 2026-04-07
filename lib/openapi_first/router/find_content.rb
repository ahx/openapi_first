# frozen_string_literal: true

module OpenapiFirst
  class Router
    # @visibility private
    module FindContent
      def self.call(contents, content_type)
        return contents[nil] if content_type.nil? || content_type.empty?

        contents.fetch(content_type) do
          semi = content_type.index(';')
          type = semi ? content_type[0, semi] : content_type
          slash = type.index('/') || type.length
          contents[type] || contents["#{type[0, slash]}/*"] || contents['*/*'] || contents[nil]
        end
      end
    end
  end
end
