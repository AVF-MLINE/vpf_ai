# frozen_string_literal: true

module VpfAi
  class PayloadBuilder
    def initialize(encoder: PayloadEncoder.new)
      @encoder = encoder
    end

    def build(schema, raw_input)
      normalized = schema.normalize(raw_input)
      encoded_payload = @encoder.encode(normalized)

      PayloadBuildResult.new(
        factor_code: normalized.fetch(:factor_code),
        title: normalized.fetch(:title),
        metadata: normalized.fetch(:metadata),
        features: normalized.fetch(:features),
        missing_required_fields: normalized.fetch(:missing_required_fields),
        encoded_payload: encoded_payload,
        payload_snapshot: build_snapshot(normalized, encoded_payload)
      )
    end

    private

    def build_snapshot(normalized, encoded_payload)
      {
        "factor_code" => normalized.fetch(:factor_code),
        "title" => normalized.fetch(:title),
        "metadata" => normalized.fetch(:metadata),
        "features" => normalized.fetch(:features),
        "missing_required_fields" => normalized.fetch(:missing_required_fields),
        "encoded_payload" => encoded_payload
      }
    end
  end
end
