# frozen_string_literal: true

module VpfAi
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class SchemaError < Error; end
  class ResponseError < Error; end
  class PermanentError < ResponseError; end
  class RetriableError < ResponseError; end
end
