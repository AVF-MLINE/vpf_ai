# frozen_string_literal: true

require_relative "test_helper"

class MetricsReportTest < Minitest::Test
  def test_generates_overall_and_factor_metrics
    rows = [
      { factor_code: "vbo", expected_group: "III", predicted_group: "III", status: "completed", latency_ms: 1200, cost_usd: 0.01 },
      { factor_code: "vbo", expected_group: "IV", predicted_group: "III", status: "completed", latency_ms: 1400, cost_usd: 0.01 },
      { factor_code: "hobl", expected_group: "II", predicted_group: "II", status: "completed", latency_ms: 900, cost_usd: 0.02 },
      { factor_code: "hobl", expected_group: "III", predicted_group: nil, status: "insufficient_data", latency_ms: 0, cost_usd: 0.0 }
    ]

    report = VpfAi::MetricsReport.generate(rows)

    assert_equal 4, report["overall"]["total_cases"]
    assert_equal 0.75, report["overall"]["coverage"]
    assert_equal 0.6667, report["overall"]["exact_match"]
    assert_equal 1.0, report["overall"]["one_step_error_rate"]
    assert_equal 10.0, report["overall"]["estimated_cost_per_1000_cases_usd"]
    assert_equal 1, report["by_factor"]["vbo"]["confusion_matrix"]["IV"]["III"]
  end
end
