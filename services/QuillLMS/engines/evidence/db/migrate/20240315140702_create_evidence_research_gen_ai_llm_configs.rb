# frozen_string_literal: true

class CreateEvidenceResearchGenAILLMConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :evidence_research_gen_ai_llm_configs do |t|
      t.string :vendor, null: false
      t.string :version, null: false

      t.timestamps
    end
  end
end
