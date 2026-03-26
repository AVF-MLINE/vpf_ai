# frozen_string_literal: true

module VpfAi
  class FieldDefinition
    attr_reader :group, :source_path, :normalized_key, :code, :type, :required, :units, :allowed_values

    def initialize(attributes)
      @group = attributes.fetch("group", "general").to_s
      @source_path = attributes.fetch("source_path").to_s
      @normalized_key = attributes.fetch("normalized_key").to_s
      @code = attributes.fetch("code").to_s
      @type = attributes.fetch("type", "string").to_s
      @required = !!attributes.fetch("required", false)
      @units = attributes["units"]
      @allowed_values = canonicalize_allowed_values(attributes.fetch("enum_values", {}))
    end

    def required?
      required
    end

    def extract_from(source_hash)
      raw_value = dig_value(source_hash, source_path)
      normalize(raw_value)
    end

    def mapping_row
      {
        "group" => group,
        "source_path" => source_path,
        "normalized_key" => normalized_key,
        "code" => code,
        "type" => type,
        "required" => required?,
        "units" => units,
        "enum_values" => allowed_values
      }
    end

    private

    def normalize(value)
      return nil if empty_value?(value)

      case type
      when "integer"
        Integer(value)
      when "float"
        round_float(value)
      when "enum"
        normalize_enum(value)
      when "string"
        value.to_s.strip
      else
        value
      end
    rescue ArgumentError, TypeError
      nil
    end

    def normalize_enum(value)
      canonical_input = canonical_scalar(value)
      return canonical_input if allowed_values.key?(canonical_input)

      match = allowed_values.find do |_key, label|
        label.to_s.strip.casecmp?(value.to_s.strip)
      end

      return match.first if match
      return "1" if value == true && allowed_values.key?("1")
      return "0" if value == false && allowed_values.key?("0")

      nil
    end

    def dig_value(data, path)
      path.split(".").reduce(data) do |current, segment|
        break nil unless current.is_a?(Hash)

        current[segment] || current[segment.to_sym]
      end
    end

    def canonicalize_allowed_values(values)
      values.each_with_object({}) do |(key, label), result|
        result[canonical_scalar(key)] = label.to_s
      end
    end

    def canonical_scalar(value)
      case value
      when Integer
        value.to_s
      when Float
        format("%.3f", value).sub(/\.?0+$/, "")
      else
        value.to_s.strip
      end
    end

    def round_float(value)
      Float(value).round(3)
    end

    def empty_value?(value)
      value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end
  end
end
