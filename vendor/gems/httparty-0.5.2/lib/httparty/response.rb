module HTTParty
  class Response < HTTParty::BasicObject #:nodoc:
    
    class HeaderHash < Hash
      def [](key)
        self.fetch(key.downcase)
      end
    end
    
    attr_accessor :body, :code, :message
    attr_reader :delegate

    def initialize(delegate, body, code, message, headers={})
      @delegate = delegate
      @body = body
      @code = code.to_i
      @message = message
      self.headers = headers
    end
    
    def headers
      @headers
    end
    
    def headers=(_headers)
      @headers = HeaderHash.new
      _headers.each_pair do |key,value|
        @headers[key] = value
      end
    end

    def method_missing(name, *args, &block)
      @delegate.send(name, *args, &block)
    end
  end
end
