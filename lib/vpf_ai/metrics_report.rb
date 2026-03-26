# frozen_string_literal: true

module VpfAi
  class MetricsReport
    RISK_ORDER = %w[I II III IV V].freeze

    def self.generate(rows)
      rows = Array(rows)

      {
        "overall" => calculate(rows),
        "by_factor" => rows.group_by { |row| row[:factor_code].to_s }.transform_values { |subset| calculate(subset) }
      }
    end

    def self.calculate(rows)
      rows = Array(rows)
      total_cases = rows.size
      completed = rows.select { |row| row[:status].to_s == "completed" && present?(row[:predicted_group]) }
      expected_cases = rows.select { |row| present?(row[:expected_group]) }

      {
        "total_cases" => total_cases,
        "completed_cases" => completed.size,
        "coverage" => ratio(completed.size, expected_cases.size),
        "exact_match" => exact_match(completed),
        "one_step_error_rate" => one_step_error_rate(completed),
        "average_latency_ms" => average(completed.map { |row| row[:latency_ms] }),
        "estimated_cost_per_1000_cases_usd" => average_cost_per_1000(rows),
        "confusion_matrix" => confusion_matrix(completed)
      }
    end

    def self.exact_match(rows)
      comparable = rows.select { |row| present?(row[:expected_group]) }
      matches = comparable.count { |row| row[:expected_group].to_s == row[:predicted_group].to_s }
      ratio(matches, comparable.size)
    end

    def self.one_step_error_rate(rows)
      comparable = rows.select { |row| present?(row[:expected_group]) }
      within_one_step = comparable.count do |row|
        distance = risk_distance(row[:expected_group], row[:predicted_group])
        !distance.nil? && distance <= 1
      end
      ratio(within_one_step, comparable.size)
    end

    def self.confusion_matrix(rows)
      labels = (rows.flat_map { |row| [row[:expected_group], row[:predicted_group]] }.compact.map(&:to_s).uniq)
      labels = labels.sort_by { |label| RISK_ORDER.index(label) || RISK_ORDER.length + label.ord }

      labels.each_with_object({}) do |expected_group, matrix|
        matrix[expected_group] = labels.each_with_object({}) do |predicted_group, row|
          row[predicted_group] = rows.count do |sample|
            sample[:expected_group].to_s == expected_group && sample[:predicted_group].to_s == predicted_group
          end
        end
      end
    end

    def self.average(values)
      values = values.compact.map(&:to_f)
      return 0.0 if values.empty?

      (values.sum / values.size).round(2)
    end

    def self.average_cost_per_1000(rows)
      costs = rows.map { |row| row[:cost_usd] }.compact.map(&:to_f)
      return 0.0 if costs.empty?

      ((costs.sum / costs.size) * 1000).round(4)
    end

    def self.ratio(numerator, denominator)
      return 0.0 if denominator.to_i <= 0

      (numerator.to_f / denominator).round(4)
    end

    def self.risk_distance(left, right)
      left_index = RISK_ORDER.index(left.to_s)
      right_index = RISK_ORDER.index(right.to_s)
      return nil if left_index.nil? || right_index.nil?

      (left_index - right_index).abs
    end

    def self.present?(value)
      !value.nil? && !value.to_s.strip.empty?
    end

    private_class_method :exact_match, :one_step_error_rate, :confusion_matrix, :average, :average_cost_per_1000, :ratio, :risk_distance, :present?
  end
end
