# frozen_string_literal: true

require_relative "test_helper"

class PayloadBuilderTest < Minitest::Test
  def setup
    @registry = VpfAi::FactorRegistry.new
    @builder = VpfAi::PayloadBuilder.new
  end

  def test_builds_compact_payload_for_vbo
    schema = @registry.fetch(:vbo)
    raw_input = {
      "worker" => { "contact_years" => 12, "age" => 48, "sex" => "m" },
      "work_conditions" => { "harm_class" => "3.2", "exposure_score" => 2.5 },
      "general_neurological_examinations" => {
        "brush_color" => 2,
        "foot_color" => 1,
        "pain_syndrome_h" => 1,
        "complaint_h" => 1,
        "hyperhidrosis_foot" => 1
      }
    }

    result = @builder.build(schema, raw_input)

    assert_empty result.missing_required_fields
    assert_equal "f=vbo|age=48|cty=12|exp=2.5|sx=m|whc=3.2|bcl=2|cph=1|fcl=1|hhf=1|psh=1", result.encoded_payload
    assert_equal "2", result.payload_snapshot["features"]["bcl"]
  end

  def test_reports_missing_required_fields
    schema = @registry.fetch(:nst)
    raw_input = {
      "worker" => { "contact_years" => 8 },
      "work_conditions" => { "harm_class" => "3.1" },
      "audiometry" => { "right_250" => 5, "right_500" => 5 }
    }

    result = @builder.build(schema, raw_input)

    assert_includes result.missing_required_fields, "right_1000"
    assert_includes result.missing_required_fields, "left_6000"
  end
end
