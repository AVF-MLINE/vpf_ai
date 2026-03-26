# frozen_string_literal: true

module VpfAi
  class YandexClassifierClient
    Prediction = Struct.new(:label, :confidence, :model_version, :raw_response, keyword_init: true)

    def initialize(configuration: VpfAi.configuration, transport: nil)
      @configuration = configuration
      @transport = transport || configuration.transport || HttpTransport.new
    end

    def classify(schema:, encoded_payload:)
      @configuration.validate!

      response = @transport.post_json(
        @configuration.endpoint,
        body: request_body(schema, encoded_payload),
        headers: request_headers,
        open_timeout: @configuration.open_timeout,
        read_timeout: @configuration.read_timeout
      )

      handle_response(schema, response)
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, Errno::ETIMEDOUT => e
      raise RetriableError, e.message
    rescue SocketError => e
      raise RetriableError, e.message
    end

    private

    def request_body(schema, encoded_payload)
      {
        "modelUri" => schema.model_uri_for(@configuration),
        "taskDescription" => schema.task_description,
        "labels" => schema.labels,
        "text" => encoded_payload,
        "samples" => schema.samples
      }
    end

    def request_headers
      headers = {
        "Authorization" => @configuration.authorization_header,
        "Content-Type" => "application/json",
        "X-Request-Id" => @configuration.request_id
      }
      headers["X-Data-Logging-Enabled"] = "false" if @configuration.disable_data_logging
      headers
    end

    def handle_response(schema, response)
      status = response.status.to_i
      body = response.body

      raise RetriableError, "Yandex AI Studio temporary failure: HTTP #{status}" if retriable_status?(status)
      raise PermanentError, "Yandex AI Studio rejected request: HTTP #{status}" unless status.between?(200, 299)

      prediction = parse_prediction(schema, body)
      raise PermanentError, "Yandex AI Studio returned unsupported label: #{prediction.label}" unless schema.labels.include?(prediction.label)

      prediction
    end

    def parse_prediction(schema, body)
      candidates = extract_candidates(body)
      raise PermanentError, "Yandex AI Studio response does not contain predictions" if candidates.empty?

      best = candidates.max_by { |candidate| candidate[:confidence] || -1.0 }

      Prediction.new(
        label: best[:label].to_s,
        confidence: (best[:confidence] || 0.0).to_f.round(5),
        model_version: extract_model_version(body, schema),
        raw_response: body
      )
    end

    def extract_candidates(node)
      return [] unless node.is_a?(Hash)

      direct_predictions = Array(node["predictions"]).map do |prediction|
        build_candidate(prediction)
      end.compact
      return direct_predictions unless direct_predictions.empty?

      single_prediction = build_candidate(node)
      return [single_prediction] if single_prediction

      %w[result classification response].each do |key|
        nested = node[key]
        next unless nested.is_a?(Hash)

        nested_candidates = extract_candidates(nested)
        return nested_candidates unless nested_candidates.empty?
      end

      []
    end

    def build_candidate(candidate)
      return unless candidate.is_a?(Hash)

      label = candidate["label"] || candidate["class"] || candidate["prediction"] || candidate["target"]
      return if label.nil?

      confidence = candidate["confidence"] || candidate["probability"] || candidate["score"]
      { label: label.to_s, confidence: confidence&.to_f }
    end

    def extract_model_version(body, schema)
      body["modelVersion"] ||
        body["model_version"] ||
        body.dig("result", "modelVersion") ||
        schema.model_uri
    end

    def retriable_status?(status)
      status == 408 || status == 429 || status >= 500
    end
  end
end
