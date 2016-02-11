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

    it 'should have mocks that work like we think' do
      mock = double('a mock')
      expect(mock).to receive(:frob).with('yo')
      mock.frob('yo')
    end

    it 'should request the correct URL' do
      uri = URI('http://example.com/echo/foo')
      expect(@http).to receive(:get).with(uri)
      @subject.validate(@contract)
    end

    describe 'When the service returns a 200 response' do
      describe 'With the expected data' do
        before do
          response = Net::HTTPResponse.new(1.0, 200, 'OK')
          response.body = "{'thing': 'foo'}"
          allow(@http).to receive(:get).and_return(response)
        end

        it 'should succeed' do
          result = @subject.validate(@contract)
          expect(result).to eq(true)
        end
      end
    end
  end

  # TODO:
  # Handle error responses
  # Handle non-response error conditions
  # Actually validate the JSON
  # Handle non-JSON responses
end
