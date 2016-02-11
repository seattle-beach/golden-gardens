require 'faraday'
require_relative 'ContractValidationResult'

class ServiceTester
  def initialize(endpoint)
    @endpoint = endpoint
  end

  def connection=(conn)
    @connection = conn
  end

  def connection
    @connection ||= connect
  end

  def configure(&configurator)
    @configurator = configurator
  end

  def validate(contract)
    path = contract['request']['path']
    uri = URI("#{@endpoint}#{path}")

    begin
      response = connection.get(uri)
    rescue Faraday::ClientError => e
      return result_for_error(e)
    end

    if response.status != 200
      return ContractValidationResult.new(["Expected 200 status code but got #{response.status}"])
    end

    content_type = response.headers['content-type']
    if content_type != 'application/json'
      return ContractValidationResult.new(["Expected application/json but got #{content_type}"])
    end

    ContractValidationResult.new([])
  end

  @private
  def result_for_error(e)
    ContractValidationResult.new([e.message])
  end

  def connect
    if @configurator
      Faraday.new(:url => @endpoint) do |builder|
        @configurator.call(builder)
      end
    else
      Faraday.new(:url => @endpoint)
    end
  end
end
