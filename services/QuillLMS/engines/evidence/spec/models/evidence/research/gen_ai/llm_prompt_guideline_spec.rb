# frozen_string_literal: true

# == Schema Information
#
# Table name: evidence_research_gen_ai_llm_prompt_guidelines
#
#  id            :bigint           not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  guideline_id  :integer          not null
#  llm_prompt_id :integer          not null
#
require 'rails_helper'

module Evidence
  module Research
    module GenAI
      RSpec.describe LLMPromptGuideline, type: :model do
        let(:factory) { described_class.model_name.singular.to_sym }

        it { expect(build(factory)).to be_valid }

        it { should belong_to(:llm_prompt) }
        it { should belong_to(:guideline) }

        it { should validate_presence_of(:llm_prompt_id) }
        it { should validate_presence_of(:guideline_id) }

        it { should have_readonly_attribute(:llm_prompt_id) }
        it { should have_readonly_attribute(:guideline_id) }

        describe 'validations' do
          subject { create(factory, llm_prompt:) }

          let(:llm_prompt) { create(:evidence_research_gen_ai_llm_prompt, locked:) }

          context 'locked dataset' do
            let(:locked) { true }

            it { expect { subject }.to raise_error(ActiveRecord::RecordInvalid) }
          end

          context 'unlocked dataset' do
            let(:locked) { false }

            it { expect { subject }.not_to raise_error }
          end
        end
      end
    end
  end
end
