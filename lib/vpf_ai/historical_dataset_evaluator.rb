# frozen_string_literal: true

module VpfAi
  class HistoricalDatasetEvaluator
    def initialize(metrics_report: MetricsReport)
      @metrics_report = metrics_report
    end

    def evaluate_file(path)
      @metrics_report.generate(load_rows(path))
    end

    private

    def load_rows(path)
      content = File.read(path)
      return JSON.parse(content, symbolize_names: true) if content.lstrip.start_with?("[")

      content.each_line.filter_map do |line|
        stripped = line.strip
        next if stripped.empty?

        JSON.parse(stripped, symbolize_names: true)
      end
    end
  end
end
