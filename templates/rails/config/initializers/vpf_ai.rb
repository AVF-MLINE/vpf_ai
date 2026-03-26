# frozen_string_literal: true

require Rails.root.join("lib", "vpf_ai").to_s

VpfAi.configure do |config|
  config.api_key = ENV["YANDEX_AI_API_KEY"]
  config.iam_token = ENV["YANDEX_AI_IAM_TOKEN"]
  config.folder_id = ENV["YANDEX_AI_FOLDER_ID"]
  config.disable_data_logging = true
  config.max_retries = 3
  config.retry_base_interval = 0.5
  config.open_timeout = 5
  config.read_timeout = 20
end
