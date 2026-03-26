# frozen_string_literal: true

module VpfAi
  class Assessor
    def initialize(factor_registry: FactorRegistry.new,
                   client: nil,
                   payload_builder: PayloadBuilder.new,
                   configuration: VpfAi.configuration,
                   sleeper: ->(seconds) { sleep(seconds) })
      @factor_registry = factor_registry
      @configuration = configuration
      @client = client || YandexClassifierClient.new(configuration: configuration)
      @payload_builder = payload_builder
      @sleeper = sleeper
    end

    def assess(factor_code, raw_input)
      schema = @factor_registry.fetch(factor_code)
      payload = @payload_builder.build(schema, raw_input)
      requested_at = Time.now.utc

      return AssessmentResult.insufficient_data(
        factor_code: schema.code,
        payload_snapshot: payload.payload_snapshot,
        requested_at: requested_at,
        missing_fields: payload.missing_required_fields
      ) unless payload.missing_required_fields.empty?

      attempts = 0

      begin
        attempts += 1
        prediction = @client.classify(schema: schema, encoded_payload: payload.encoded_payload)
        completed_at = Time.now.utc

        return AssessmentResult.completed(
          factor_code: schema.code,
          ai_group: prediction.label,
          confidence: prediction.confidence,
          classifier_version: prediction.model_version,
          payload_snapshot: payload.payload_snapshot,
          requested_at: requested_at,
          completed_at: completed_at,
          raw_response: prediction.raw_response
        )
      rescue RetriableError => e
        retry if retryable_attempt?(attempts, e)

        return AssessmentResult.error(
          factor_code: schema.code,
          payload_snapshot: payload.payload_snapshot,
          requested_at: requested_at,
          completed_at: Time.now.utc,
          error_code: "provider_unavailable",
          error_message: e.message
        )
      rescue PermanentError => e
        return AssessmentResult.error(
          factor_code: schema.code,
          payload_snapshot: payload.payload_snapshot,
          requested_at: requested_at,
          completed_at: Time.now.utc,
          error_code: "provider_invalid_response",
          error_message: e.message
        )
      rescue StandardError => e
        return AssessmentResult.error(
          factor_code: schema.code,
          payload_snapshot: payload.payload_snapshot,
          requested_at: requested_at,
          completed_at: Time.now.utc,
          error_code: "unexpected_error",
          error_message: e.message
        )
      end
    end

    def assess_all(raw_inputs_by_factor)
      raw_inputs_by_factor.each_with_object([]) do |(factor_code, raw_input), results|
        results << assess(factor_code, raw_input)
      end
    end

    private

    def retryable_attempt?(attempts, _error)
      return false if attempts >= @configuration.max_retries

      @sleeper.call(@configuration.retry_base_interval * attempts)
      true
    end
  end
end
