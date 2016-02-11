require 'net/http'
require_relative 'HttpWrapper'

class ServiceTester
  def initialize(endpoint, http = nil)
    @http = http || HttpWrapper.new
    @endpoint = endpoint
  end

  def validate(contract)
    path = contract['request']['path']
    uri = URI("#{@endpoint}#{path}")
    response = @http.get(uri)
    p response
    true
  end
end
