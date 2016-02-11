require 'net/http'

class HttpWrapper
  def get(uri)
    Net::HTTP.get_response(uri)
  end
end
