# frozen_string_literal: true

module VpfAi
  class PayloadBuildResult
    attr_reader :factor_code, :title, :metadata, :features, :missing_required_fields, :encoded_payload, :payload_snapshot

    def initialize(attributes)
      @factor_code = attributes.fetch(:factor_code)
      @title = attributes.fetch(:title)
      @metadata = attributes.fetch(:metadata)
      @features = attributes.fetch(:features)
      @missing_required_fields = attributes.fetch(:missing_required_fields)
      @encoded_payload = attributes.fetch(:encoded_payload)
      @payload_snapshot = attributes.fetch(:payload_snapshot)
    end
  end
end
