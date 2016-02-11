require 'net/http'
require_relative 'HttpWrapper'
require_relative 'ContractValidationResult'

class ServiceTester
  def initialize(endpoint, http = nil)
    @http = http || HttpWrapper.new
    @endpoint = endpoint
  end

  def validate(contract)
    path = contract['request']['path']
    uri = URI("#{@endpoint}#{path}")

    begin
      response = @http.get(uri)
    rescue StandardError => e
      return result_for_error(e)
    end

    errors = []

    if response.code != 200
      errors.push("Expected 200 status code but got #{response.code}")
    end

    ContractValidationResult.new(errors)
  end

  @private
  def result_for_error(e)
    ContractValidationResult.new([e.message])
  end
end
