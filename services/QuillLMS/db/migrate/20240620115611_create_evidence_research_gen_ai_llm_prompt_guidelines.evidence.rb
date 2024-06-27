# frozen_string_literal: true

# This migration comes from evidence (originally 20240620115506)
class CreateEvidenceResearchGenAILLMPromptGuidelines < ActiveRecord::Migration[7.0]
  def change
    create_table :evidence_research_gen_ai_llm_prompt_guidelines do |t|
      t.integer :llm_prompt_id, null: false
      t.integer :guideline_id, null: false

      t.timestamps
    end
  end
end