# frozen_string_literal: true

class CreateAiRiskAssessments < ActiveRecord::Migration[6.1]
  def change
    create_table :ai_risk_assessments do |t|
      t.references :conclusion, null: false, foreign_key: true
      t.string :factor_code, null: false
      t.string :ai_group
      t.decimal :confidence, precision: 6, scale: 5
      t.string :status, null: false, default: "pending"
      t.string :classifier_version
      t.json :payload_snapshot_json, null: false, default: {}
      t.datetime :requested_at
      t.datetime :completed_at
      t.string :error_code
      t.text :error_message
      t.integer :latency_ms
      t.timestamps
    end

    add_index :ai_risk_assessments, [:conclusion_id, :factor_code], unique: true, name: "idx_ai_risk_assessments_on_conclusion_factor"
  end
end
