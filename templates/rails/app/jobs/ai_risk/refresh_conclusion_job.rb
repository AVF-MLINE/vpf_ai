# frozen_string_literal: true

module AiRisk
  class RefreshConclusionJob < ApplicationJob
    queue_as :default

    retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 3

    def perform(conclusion_id)
      conclusion = Conclusion.find(conclusion_id)
      RefreshConclusionAssessments.new(conclusion: conclusion).call
    end
  end
end
