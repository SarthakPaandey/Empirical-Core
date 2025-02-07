# frozen_string_literal: true

# == Schema Information
#
# Table name: evidence_research_gen_ai_comparisons
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  dataset_id :integer          not null
#

module Evidence
  module Research
    module GenAI
      class Comparison < ApplicationRecord
        belongs_to :dataset

        has_many :trial_comparisons, dependent: :destroy
        has_many :trials, through: :trial_comparisons

        validates :dataset_id, presence: true

        scope :llms, -> { where(independent_variable: LLM).order(id: :desc) }
        scope :llm_prompts, -> { where(independent_variable: LLM_PROMPT).order(id: :desc) }

        store_accessor :results, :accuracy_optimal_sub_optimal, :confusion_matrix

        delegate :stem_and_conjunction, to: :dataset
      end
    end
  end
end
