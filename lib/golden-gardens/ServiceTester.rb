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

    if response.code != 200
      return ContractValidationResult.new(["Expected 200 status code but got #{response.code}"])
    end

    if response.content_type != 'application/json'
      return ContractValidationResult.new(["Expected application/json but got #{response.content_type}"])
    end

    ContractValidationResult.new([])
  end

  @private
  def result_for_error(e)
    ContractValidationResult.new([e.message])
  end
end
