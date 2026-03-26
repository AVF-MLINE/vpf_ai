# frozen_string_literal: true

class AiRiskAssessment < ApplicationRecord
  FACTOR_CODES = %w[vbo vbl nst hobl].freeze
  STATUSES = %w[pending completed error insufficient_data].freeze

  belongs_to :conclusion

  validates :factor_code, presence: true, inclusion: { in: FACTOR_CODES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :factor_code, uniqueness: { scope: :conclusion_id }
  validates :ai_group, inclusion: { in: %w[I II III IV V] }, allow_nil: true

  scope :ordered, -> { order(:factor_code) }

  def display_group
    status == "completed" ? ai_group : nil
  end
end
