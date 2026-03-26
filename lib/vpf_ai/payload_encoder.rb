# frozen_string_literal: true

module VpfAi
  class PayloadEncoder
    def encode(normalized_payload)
      parts = ["f=#{normalized_payload.fetch(:factor_code)}"]
      parts.concat(encoded_pairs(normalized_payload.fetch(:metadata)))
      parts.concat(encoded_pairs(normalized_payload.fetch(:features)))
      parts.join("|")
    end

    private

    def encoded_pairs(values_hash)
      values_hash.keys.sort.map do |key|
        "#{key}=#{canonical(values_hash[key])}"
      end
    end

    def canonical(value)
      case value
      when Integer
        value.to_s
      when Float
        format("%.3f", value).sub(/\.?0+$/, "")
      else
        value.to_s.strip
      end
    end
  end
end
