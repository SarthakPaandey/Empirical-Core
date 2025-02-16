# frozen_string_literal: true

# == Schema Information
#
# Table name: evidence_research_gen_ai_llms
#
#  id         :bigint           not null, primary key
#  vendor     :string           not null
#  version    :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

module Evidence
  module Research
    module GenAI
      FactoryBot.define do
        factory :evidence_research_gen_ai_llm, class: 'Evidence::Research::GenAI::LLM' do
          vendor { VENDOR_COMPLETION_MAP.keys.sample }
          version { 'v1.0' }

          trait(:google) { vendor { GOOGLE } }
          trait(:open_ai) { vendor { OPEN_AI } }
        end
      end
    end
  end
end
