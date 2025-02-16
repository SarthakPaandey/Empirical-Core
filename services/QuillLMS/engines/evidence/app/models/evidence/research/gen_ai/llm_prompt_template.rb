# frozen_string_literal: true

# == Schema Information
#
# Table name: evidence_research_gen_ai_llm_prompt_templates
#
#  id         :bigint           not null, primary key
#  contents   :text             not null
#  name       :text             not null
#  notes      :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
module Evidence
  module Research
    module GenAI
      class LLMPromptTemplate < ApplicationRecord
        validates :name, presence: true
        validates :contents, presence: true

        attr_readonly :name, :contents

        has_many :llm_prompts, dependent: :destroy

        def num_trials = Trial.where(llm_prompt: llm_prompts).count

        def to_s = name
      end
    end
  end
end
