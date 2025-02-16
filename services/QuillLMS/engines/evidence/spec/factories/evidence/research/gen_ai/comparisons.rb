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
      FactoryBot.define do
        factory :evidence_research_gen_ai_comparison, class: 'Evidence::Research::GenAI::Comparison' do
          dataset { association :evidence_research_gen_ai_dataset }
        end
      end
    end
  end
end
