# frozen_string_literal: true

require_relative "test_helper"

class FactorRegistryTest < Minitest::Test
  def test_loads_all_factor_schemas
    registry = VpfAi::FactorRegistry.new

    assert_equal %w[hobl nst vbl vbo], registry.all.map(&:code).sort
    assert_equal "Вибрационная болезнь общая", registry.fetch(:vbo).title
    assert_equal ["I", "II", "III", "IV"], registry.fetch(:nst).labels
  end

  def test_schema_exposes_mapping_rows
    schema = VpfAi::FactorRegistry.new.fetch(:hobl)
    mapping_row = schema.mapping_rows.find { |row| row["code"] == "smk" }

    assert_equal "anamnesis_respiratories.smoke_idx", mapping_row["source_path"]
    assert_equal "smoking_pack_years_score", mapping_row["normalized_key"]
    assert_equal true, mapping_row["required"]
  end
end
