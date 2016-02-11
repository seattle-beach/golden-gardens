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
    response = @http.get(uri)
    errors = []

    if response.code != 200
      errors.push("Expected 200 status code but got #{response.code}")
    end

    ContractValidationResult.new(errors)
  end
end
