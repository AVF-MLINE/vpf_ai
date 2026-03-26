# frozen_string_literal: true

module VpfAi
  class HttpTransport
    Response = Struct.new(:status, :headers, :body, keyword_init: true)

    def post_json(url, body:, headers:, open_timeout:, read_timeout:)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = open_timeout
      http.read_timeout = read_timeout

      request = Net::HTTP::Post.new(uri.request_uri)
      headers.each { |key, value| request[key] = value }
      request.body = JSON.generate(body)

      response = http.request(request)

      Response.new(
        status: response.code.to_i,
        headers: response.each_header.to_h,
        body: parse_body(response.body)
      )
    end

    private

    def parse_body(body)
      return {} if body.nil? || body.strip.empty?

      JSON.parse(body)
    rescue JSON::ParserError
      { "raw_body" => body.to_s }
    end
  end
end
