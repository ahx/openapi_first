module OpenapiFirst
  class Validation
    attr_reader :errors

    def initialize(errors)
      @errors = errors.to_a.each { |error| error.delete('root_schema') }
    end

    def errors?
      !errors.empty?
    end
  end
end
