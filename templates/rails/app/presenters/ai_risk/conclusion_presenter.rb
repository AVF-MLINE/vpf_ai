# frozen_string_literal: true

module AiRisk
  class ConclusionPresenter
    FACTOR_ORDER = %w[vbo vbl nst hobl].freeze

    def initialize(conclusion)
      @conclusion = conclusion
    end

    def as_json(*)
      FACTOR_ORDER.each_with_object({}) do |factor_code, result|
        assessment = assessments_by_factor[factor_code]
        result[factor_code] = {
          ai_risk_group: assessment&.display_group,
          ai_risk_status: assessment&.status || "pending"
        }
      end
    end

    private

    def assessments_by_factor
      @assessments_by_factor ||= @conclusion.ai_risk_assessments.index_by(&:factor_code)
    end
  end
end
