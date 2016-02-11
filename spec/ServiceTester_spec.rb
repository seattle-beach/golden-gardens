require './lib/golden-gardens/ServiceTester'

describe 'ServiceTester' do
  before do
    @http = double('HTTP wrapper')
    @subject = ServiceTester.new('http://example.com', @http)
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

    it 'should request the correct URL' do
      uri = URI('http://example.com/echo/foo')
      response = valid_response
      expect(@http).to receive(:get).with(uri).and_return(response)
      @subject.validate(@contract)
    end

    describe 'When the service returns a 200 response' do
      describe 'With the expected data' do
        before do
          allow(@http).to receive(:get).and_return(valid_response)
        end

        it 'should succeed' do
          result = @subject.validate(@contract)
          expect(result.ok?).to eq(true)
        end
      end
    end

    describe 'When the service returns a non-200 response' do
      before do
        response = response_with_code(500)
        allow(@http).to receive(:get).and_return(response)
      end

      it 'should fail' do
        result = @subject.validate(@contract)
        expect(result.ok?).to eq(false)
        expect(result.errors).to eq(['Expected 200 status code but got 500'])
      end
    end

    describe 'When there is a non-response connection error' do
      before do
        msg = 'connect(2) for "example.com" port 80 (Errno::ECONNREFUSED)'
        allow(@http).to receive(:get).and_raise(Errno::ECONNREFUSED.new(msg))
      end

      it 'should fail' do
        result = @subject.validate(@contract)
        expect(result.ok?).to eq(false)
        expect(result.errors).to eq(['Connection refused - connect(2) for "example.com" port 80 (Errno::ECONNREFUSED)'])
      end
    end

    describe 'When the content type is not JSON' do
      before do
        response = valid_response
        response.content_type=('text/html')
        allow(@http).to receive(:get).and_return(response)
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
