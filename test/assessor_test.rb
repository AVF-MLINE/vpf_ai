# frozen_string_literal: true

require_relative "test_helper"

class AssessorTest < Minitest::Test
  class FlakyClient
    def initialize
      @calls = 0
    end

    def classify(schema:, encoded_payload:)
      @calls += 1
      raise VpfAi::RetriableError, "temporary" if @calls == 1

      VpfAi::YandexClassifierClient::Prediction.new(
        label: "IV",
        confidence: 0.91,
        model_version: "classifier-v2",
        raw_response: { "payload" => encoded_payload, "schema" => schema.code }
      )
    end
  end

  def test_returns_insufficient_data_when_required_fields_are_missing
    assessor = VpfAi::Assessor.new(
      factor_registry: VpfAi::FactorRegistry.new,
      client: FlakyClient.new,
      configuration: configured_configuration
    )

    result = assessor.assess(:nst, "worker" => { "contact_years" => 12 })

    assert_equal "insufficient_data", result.status
    assert_equal "insufficient_data", result.error_code
    assert_nil result.ai_group
  end

  def test_retries_and_completes
    sleeps = []
    assessor = VpfAi::Assessor.new(
      factor_registry: VpfAi::FactorRegistry.new,
      client: FlakyClient.new,
      configuration: configured_configuration,
      sleeper: ->(seconds) { sleeps << seconds }
    )

    result = assessor.assess(
      :hobl,
      "worker" => { "contact_years" => 14 },
      "work_conditions" => { "harm_class" => "3.2" },
      "anamnesis_respiratories" => { "smoke_idx" => 1, "crises_by_year" => 1 },
      "index_mmrcs" => { "degree" => 1, "cat_points" => 1 },
      "external_breathings" => { "spirometry" => 1, "spirometry_dynamics" => 0.5 }
    )

    assert_equal "completed", result.status
    assert_equal "IV", result.ai_group
    assert_equal [0.5], sleeps
  end

  private

  def configured_configuration
    VpfAi::Configuration.new.tap do |config|
      config.api_key = "test-key"
      config.folder_id = "folder-1"
      config.max_retries = 2
      config.retry_base_interval = 0.5
    end
  end
end
