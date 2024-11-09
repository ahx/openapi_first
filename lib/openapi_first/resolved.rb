module OpenapiFirst
  # This is here to give easy access to resolved $refs
  # @visibility private
  class Resolved
    def initialize(value, context: value)
      @value = value
      @context = context
    end

    def [](key)
      value = @value.fetch(key) do
        resolve_ref(@value['$ref']).fetch(key)
      end

      self.class.new(value, context:)
    end

    def each
      resolved.each do |key, value|
        yield key, value
      end
    end

    def resolved
      if value.is_a?(Hash) && value.key?('$ref')
        return resolve_ref(value['$ref'])
      elsif value.is_a?(Array)
        return value.map do |item|
          break item.resolved if item.is_a?(Resolved)
          item
        end
      end
      value
    end

    private

    private attr_accessor :value
    private attr_accessor :context


    def resolve_ref(pointer)
      value = Hana::Pointer.new(pointer[1..]).eval(context)
      raise "Unknown reference #{pointer} in #{context}" unless value
      value
    end
  end
end
