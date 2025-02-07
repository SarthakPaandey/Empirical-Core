# frozen_string_literal: true

class CreateEvidenceResearchGenAIPassages < ActiveRecord::Migration[7.0]
  def change
    create_table :evidence_research_gen_ai_passages do |t|
      t.text :contents, null: false
      t.string :name, null: false

      t.timestamps
    end
  end
end
