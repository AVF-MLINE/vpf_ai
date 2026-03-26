# frozen_string_literal: true

module VpfAi
  class FactorSchema
    attr_reader :code, :title, :labels, :task_description, :model_uri, :metadata_fields, :fields, :samples

    def initialize(code, attributes)
      @code = code.to_s
      @title = attributes.fetch("title").to_s
      @labels = Array(attributes.fetch("labels")).map(&:to_s).freeze
      @task_description = attributes.fetch("task_description").to_s.strip
      @model_uri = attributes["model_uri"]
      @metadata_fields = build_fields(attributes.fetch("metadata_fields", []))
      @fields = build_fields(attributes.fetch("fields", []))
      @samples = Array(attributes.fetch("samples", [])).map do |sample|
        { "text" => sample.fetch("text").to_s, "label" => sample.fetch("label").to_s }
      end.freeze
    end

    def normalize(raw_input)
      metadata = {}
      features = {}
      missing_required_fields = []

      metadata_fields.each do |field|
        extract_field(field, raw_input, metadata, missing_required_fields)
      end

      fields.each do |field|
        extract_field(field, raw_input, features, missing_required_fields)
      end

      {
        factor_code: code,
        title: title,
        metadata: metadata,
        features: features,
        missing_required_fields: missing_required_fields.uniq
      }
    end

    def mapping_rows
      (metadata_fields + fields).map(&:mapping_row)
    end

    def model_uri_for(configuration)
      model_uri || configuration.default_model_uri
    end

    private

    def build_fields(field_attributes)
      Array(field_attributes).map { |field| FieldDefinition.new(field) }.freeze
    end

    def extract_field(field, raw_input, target, missing_required_fields)
      value = field.extract_from(raw_input)

      if value.nil?
        missing_required_fields << field.normalized_key if field.required?
        return
      end

      target[field.code] = value
    end
  end
end
