# frozen_string_literal: true

module AiRisk
  class RefreshConclusionAssessments
    def initialize(conclusion:, assessor: VpfAi::Assessor.new)
      @conclusion = conclusion
      @assessor = assessor
    end

    def call
      inputs = normalized_inputs
      mark_pending!(inputs.keys)
      results = @assessor.assess_all(inputs)
      persist!(results)
      results
    end

    private

    def normalized_inputs
      @conclusion.to_ai_risk_inputs.transform_keys(&:to_s).slice(*AiRiskAssessment::FACTOR_CODES)
    end

    def mark_pending!(factor_codes)
      factor_codes.each do |factor_code|
        assessment = @conclusion.ai_risk_assessments.find_or_initialize_by(factor_code: factor_code)
        assessment.update!(
          status: "pending",
          ai_group: nil,
          confidence: nil,
          classifier_version: nil,
          payload_snapshot_json: {},
          requested_at: Time.current,
          completed_at: nil,
          error_code: nil,
          error_message: nil,
          latency_ms: nil
        )
      end
    end

    def persist!(results)
      results.each do |result|
        assessment = @conclusion.ai_risk_assessments.find_or_initialize_by(factor_code: result.factor_code.to_s)
        assessment.update!(
          ai_group: result.ai_group,
          confidence: result.confidence,
          status: result.status,
          classifier_version: result.classifier_version,
          payload_snapshot_json: result.payload_snapshot,
          requested_at: result.requested_at,
          completed_at: result.completed_at,
          error_code: result.error_code,
          error_message: result.error_message,
          latency_ms: result.latency_ms
        )
      end
    end
  end
end
