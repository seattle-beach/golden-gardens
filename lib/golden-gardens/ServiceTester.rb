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
    unless is_valid_content_type(content_type)
      return ContractValidationResult.new(["Expected application/json but got #{content_type}"])
    end

    data = JSON.parse(response.body)

    if data == contract['response']['data']
      ContractValidationResult.new([])
    else
      ContractValidationResult.new(['nope!'])
    end
  end

  @private
  def is_valid_content_type(content_type)
    content_type == 'application/json' || content_type.start_with?('application/json;')
  end

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
