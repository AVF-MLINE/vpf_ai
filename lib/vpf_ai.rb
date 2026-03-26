# frozen_string_literal: true

require "json"
require "net/http"
require "securerandom"
require "time"
require "uri"
require "yaml"

module VpfAi
  def self.root
    File.expand_path("..", __dir__)
  end
end

require_relative "vpf_ai/configuration"
require_relative "vpf_ai/errors"
require_relative "vpf_ai/field_definition"
require_relative "vpf_ai/factor_schema"
require_relative "vpf_ai/factor_registry"
require_relative "vpf_ai/payload_build_result"
require_relative "vpf_ai/payload_encoder"
require_relative "vpf_ai/payload_builder"
require_relative "vpf_ai/http_transport"
require_relative "vpf_ai/yandex_classifier_client"
require_relative "vpf_ai/assessment_result"
require_relative "vpf_ai/assessor"
require_relative "vpf_ai/metrics_report"
require_relative "vpf_ai/historical_dataset_evaluator"

module VpfAi
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
