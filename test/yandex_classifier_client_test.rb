# frozen_string_literal: true

require_relative "test_helper"

class YandexClassifierClientTest < Minitest::Test
  class FakeTransport
    attr_reader :requests

    def initialize(response)
      @response = response
      @requests = []
    end

    def post_json(url, body:, headers:, open_timeout:, read_timeout:)
      @requests << {
        url: url,
        body: body,
        headers: headers,
        open_timeout: open_timeout,
        read_timeout: read_timeout
      }
      @response
    end
  end

  def test_sends_expected_request_and_parses_prediction
    configuration = VpfAi::Configuration.new
    configuration.api_key = "test-key"
    configuration.folder_id = "folder-1"

    response = VpfAi::HttpTransport::Response.new(
      status: 200,
      headers: {},
      body: {
        "predictions" => [
          { "label" => "III", "confidence" => 0.82 },
          { "label" => "II", "confidence" => 0.18 }
        ],
        "modelVersion" => "classifier-v1"
      }
    )
    transport = FakeTransport.new(response)
    client = VpfAi::YandexClassifierClient.new(configuration: configuration, transport: transport)
    schema = VpfAi::FactorRegistry.new.fetch(:hobl)

    prediction = client.classify(schema: schema, encoded_payload: "f=hobl|cty=12|whc=3.2|smk=1|cry=1|mmr=1|cat=1|spr=1|spd=0.5")

    assert_equal "III", prediction.label
    assert_equal 0.82, prediction.confidence
    assert_equal "classifier-v1", prediction.model_version
    assert_equal "Api-Key test-key", transport.requests.first[:headers]["Authorization"]
    assert_equal "false", transport.requests.first[:headers]["X-Data-Logging-Enabled"]
    assert_equal schema.labels, transport.requests.first[:body]["labels"]
  end
end
