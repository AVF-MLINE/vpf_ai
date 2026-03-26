# frozen_string_literal: true

module AiRisk
  module ConclusionSource
    extend ActiveSupport::Concern

    included do
      has_many :ai_risk_assessments, dependent: :destroy
      after_commit :enqueue_ai_risk_refresh, on: %i[create update]
    end

    def to_ai_risk_inputs
      raise NotImplementedError, "Map conclusion fields to the VpfAi payload contract"
    end

    private

    def enqueue_ai_risk_refresh
      AiRisk::RefreshConclusionJob.perform_later(id)
    end
  end
end
