# frozen_string_literal: true

require_relative 'coverage/plan'

module OpenapiFirst
  # The Coverage module is about tracking request and response validation
  # to assess if all parts of the API description have been tested.
  # Currently it does not care about unknown requests that are not part of any API description.
  module Coverage
    class NotRegisteredError < StandardError; end

    @registry = Hash.new do |_, filepath|
      raise NotRegisteredError,
                            "API description '#{filepath}' was not registered." \
                            "Please call OpenapiFirst::Coverage.register('path/to/myopenapi.yaml') once before OpenapiFirst::Coverage.start and running tests. Registered descriptions are: #{plans.keys.inspect}."
    end

    class << self
      attr_reader :registry
    end

    def self.start
      OpenapiFirst.configure do |config|
        config.after_request_validation do |validated_request, oad|
          track_request(validated_request, oad)
        end
        config.after_response_validation do |validated_response, request, oad|
          track_response(validated_response, request, oad)
        end
      end
    end

    def self.register(filepath, storage=Storage::DEFAULT)
      oad = OpenapiFirst.load(filepath)
      registry[oad.filepath] = Coverage::Plan.new(oad)
    end

    def self.track_request(request, oad)
      registry[oad.filepath].track_request(request)
    end

    def self.track_response(response, request, oad)
      registry[oad.filepath].track_response(response, request)
    end

    def self.report
      print
      reset
    end

    def self.to_h
      plans.transform_values(&:to_h)
    end

    def self.print
      registry.each do |filepath, plan|
        all = plan.data
        dones = plan.dones
        puts "API test coverage for #{File.basename(filepath)}: #{dones.length.zero? ? 0 : (all.length / dones.length * 100)}%"
        puts "#{dones.length} of #{all.length} routes are fully covered"
        plan.data.values.each do |request|
          puts "#{request[:name]}:#{" – Not requested!" unless request[:requested]}"
          next unless request[:requested]
          request[:responses].each do |_, response|
            if response[:responded]
              puts "  #{response[:name]} ✓"
            else
              puts "  #{response[:name]} ❌"
            end
          end
        end
      end
    end

    def self.reset
      registry.clear
    end
  end
end
