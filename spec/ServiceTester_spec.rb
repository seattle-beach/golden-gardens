require './lib/golden-gardens/ServiceTester'
require 'faraday'

describe 'ServiceTester' do
  before do
    @subject = ServiceTester.new('http://localhost')
  end

  describe 'For a contract with no dependencies and a hardcoded response' do
    before do
      @contract = {
        'request' => {
          'method' => 'get',
          'path' => '/echo/foo'
        },
        'response' => {
          'type' => 'literal-json',
          'data' => {
            'thing' => 'foo'
          }
        }
      }
    end

    def response_with_code(code)
      response = Net::HTTPResponse.new(1.0, code, 'OK')
      response.body = "{'thing': 'foo'}"
      response.content_type=('application/json')
      response
    end

    def valid_response
      response_with_code(200)
    end

    it 'should use the correct base URL' do
      expect(@subject.connection.url_prefix).to eq(URI('http://localhost/'))
    end

    describe 'When the service returns a 200 response' do
      describe 'With the expected data' do
        before do
          @subject.configure do |builder|
            builder.adapter :test do |stub|
              stub.get('/echo/foo') { |env| [200, {'content-type': 'application/json'}, "{'thing': 'foo'}"]}
            end
          end
        end

        it 'should succeed' do
          result = @subject.validate(@contract)
          expect(result.ok?).to eq(true)
        end
      end
    end

    describe 'When the service returns a non-200 response' do
      before do
        @subject.configure do |builder|
          builder.adapter :test do |stub|
            stub.get('/echo/foo') { |env| [500, {'content-type': 'application/json'}, "{'thing': 'foo'}"]}
          end
        end
      end

      it 'should fail' do
        result = @subject.validate(@contract)
        expect(result.ok?).to eq(false)
        expect(result.errors).to eq(['Expected 200 status code but got 500'])
      end
    end

    describe 'When there is a non-response connection error' do
      before do
        @subject.configure do |builder|
          builder.adapter :test do |stub|
            stub.get('/echo/foo') { |env| raise Faraday::ConnectionFailed.new('Connection failed')}
          end
        end
      end

      it 'should fail' do
        result = @subject.validate(@contract)
        expect(result.ok?).to eq(false)
        expect(result.errors).to eq(['Connection failed'])
      end
    end

    describe 'When the content type is not JSON' do
      before do
        @subject.configure do |builder|
          builder.adapter :test do |stub|
            stub.get('/echo/foo') { |env| [200, {'content-type': 'text/html'}, "{'thing': 'foo'}"]}
          end
        end
      end

      it 'should fail' do
        result = @subject.validate(@contract)
        expect(result.ok?).to eq(false)
        expect(result.errors).to eq(['Expected application/json but got text/html'])
      end
    end
  end

  # TODO:
  # Actually validate the JSON
  # Handle non-JSON responses
end
