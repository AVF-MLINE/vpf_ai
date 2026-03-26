# frozen_string_literal: true

module VpfAi
  class AssessmentResult
    STATUSES = %w[pending completed error insufficient_data].freeze

    attr_reader :factor_code,
                :ai_group,
                :confidence,
                :status,
                :classifier_version,
                :payload_snapshot,
                :requested_at,
                :completed_at,
                :error_code,
                :error_message,
                :latency_ms,
                :raw_response

    def initialize(attributes)
      @factor_code = attributes.fetch(:factor_code)
      @ai_group = attributes[:ai_group]
      @confidence = attributes[:confidence]
      @status = attributes.fetch(:status)
      @classifier_version = attributes[:classifier_version]
      @payload_snapshot = attributes.fetch(:payload_snapshot)
      @requested_at = attributes.fetch(:requested_at)
      @completed_at = attributes[:completed_at]
      @error_code = attributes[:error_code]
      @error_message = attributes[:error_message]
      @latency_ms = attributes[:latency_ms]
      @raw_response = attributes[:raw_response]
    end

    def to_h
      {
        factor_code: factor_code,
        ai_group: ai_group,
        confidence: confidence,
        status: status,
        classifier_version: classifier_version,
        payload_snapshot_json: payload_snapshot,
        requested_at: requested_at,
        completed_at: completed_at,
        error_code: error_code,
        error_message: error_message,
        latency_ms: latency_ms
      }
    end

    def self.completed(factor_code:, ai_group:, confidence:, classifier_version:, payload_snapshot:, requested_at:, completed_at:, raw_response:)
      new(
        factor_code: factor_code,
        ai_group: ai_group,
        confidence: confidence,
        status: "completed",
        classifier_version: classifier_version,
        payload_snapshot: payload_snapshot,
        requested_at: requested_at,
        completed_at: completed_at,
        latency_ms: ((completed_at - requested_at) * 1000).round,
        raw_response: raw_response
      )
    end

    def self.error(factor_code:, payload_snapshot:, requested_at:, completed_at:, error_code:, error_message:)
      new(
        factor_code: factor_code,
        status: "error",
        payload_snapshot: payload_snapshot,
        requested_at: requested_at,
        completed_at: completed_at,
        error_code: error_code,
        error_message: error_message,
        latency_ms: ((completed_at - requested_at) * 1000).round
      )
    end

    def self.insufficient_data(factor_code:, payload_snapshot:, requested_at:, missing_fields:)
      snapshot = payload_snapshot.merge("missing_required_fields" => Array(missing_fields))

      new(
        factor_code: factor_code,
        status: "insufficient_data",
        payload_snapshot: snapshot,
        requested_at: requested_at,
        completed_at: requested_at,
        error_code: "insufficient_data",
        error_message: "Missing required fields: #{Array(missing_fields).join(', ')}",
        latency_ms: 0
      )
    end
  end
end
