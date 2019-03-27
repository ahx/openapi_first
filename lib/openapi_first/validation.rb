module OpenapiFirst
  class Validation
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end

    def errors?
      !errors.empty?
    end
  end
end
