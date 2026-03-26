# frozen_string_literal: true

module VpfAi
  class Configuration
    attr_accessor :api_key,
                  :iam_token,
                  :folder_id,
                  :endpoint,
                  :disable_data_logging,
                  :open_timeout,
                  :read_timeout,
                  :max_retries,
                  :retry_base_interval,
                  :model_uri_template,
                  :transport,
                  :request_id_generator

    def initialize
      @endpoint = "https://llm.api.cloud.yandex.net/foundationModels/v1/fewShotTextClassification"
      @disable_data_logging = true
      @open_timeout = 5
      @read_timeout = 20
      @max_retries = 3
      @retry_base_interval = 0.5
      @model_uri_template = "cls://%{folder_id}/yandexgpt/latest"
      @request_id_generator = -> { SecureRandom.uuid }
      @transport = nil
    end

    def authorization_header
      return "Api-Key #{api_key}" unless blank?(api_key)
      return "Bearer #{iam_token}" unless blank?(iam_token)

      raise ConfigurationError, "Set VpfAi.configuration.api_key or iam_token before calling Yandex AI Studio"
    end

    def default_model_uri
      raise ConfigurationError, "Set VpfAi.configuration.folder_id before calling Yandex AI Studio" if blank?(folder_id)

      format(model_uri_template, folder_id: folder_id)
    end

    def request_id
      request_id_generator.call
    end

    def validate!
      authorization_header
      default_model_uri
      true
    end

    private

    def blank?(value)
      value.nil? || value.to_s.strip.empty?
    end
  end
end
