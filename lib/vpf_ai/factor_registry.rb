# frozen_string_literal: true

module VpfAi
  class FactorRegistry
    DEFAULT_PATH = File.join(VpfAi.root, "config", "factor_schemas.yml")

    def initialize(path = DEFAULT_PATH)
      @path = path
      @schemas = load_schemas
    end

    def fetch(code)
      @schemas.fetch(code.to_s) do
        raise SchemaError, "Unknown factor schema: #{code}"
      end
    end

    def all
      @schemas.values
    end

    private

    def load_schemas
      raw = YAML.safe_load(File.read(@path))
      factors = raw.fetch("factors")

      factors.each_with_object({}) do |(code, attributes), result|
        result[code.to_s] = FactorSchema.new(code, attributes)
      end.freeze
    rescue Errno::ENOENT => e
      raise SchemaError, "Schema file not found: #{e.message}"
    rescue KeyError => e
      raise SchemaError, "Invalid schema file: #{e.message}"
    end
  end
end
