require 'rails_helper'

module Evidence
  module Research
    module GenAI
      RSpec.describe ExperimentsController, type: :controller do
        routes { Evidence::Engine.routes }

        let(:user) { double('User') }

        before do
          allow(controller).to receive(:current_user).and_return(user)
          allow(user).to receive(:staff?).and_return(is_staff)
        end

        describe 'POST #create' do
          let(:llm_configs) { create_list(:evidence_research_gen_ai_llm_config, num_llm_configs) }
          let(:llm_config_ids) { llm_configs.map(&:id) }
          let(:num_llm_configs) { rand(1..3) }

          let(:llm_prompt_templates) { create_list(:evidence_research_gen_ai_llm_prompt_template, num_llm_prompt_templates) }
          let(:llm_prompt_template_ids) { llm_prompt_templates.map(&:id) }
          let(:num_llm_prompt_templates) { rand(1..3) }

          let(:passage_prompts) { create_list(:evidence_research_gen_ai_passage_prompt, num_passage_prompts) }
          let(:passage_prompt_ids) { passage_prompts.map(&:id) }
          let(:num_passage_prompts) { rand(1..3) }

          let(:num_examples) { rand(1..3) }

          let(:llm_prompt) { create(:evidence_research_gen_ai_llm_prompt) }

          subject do
            post :create, params: {
              research_gen_ai_experiment: {
                llm_config_ids:,
                llm_prompt_template_ids:,
                passage_prompt_ids:,
                num_examples:
              }
            }
          end

          context 'as not staff' do
            let(:is_staff) { false }

            it { expect { subject }.not_to change(Experiment, :count) }
            it { expect(subject).to redirect_to '/' }
          end

          context 'as staff' do
            let(:is_staff) { true }

            before { allow(LLMPromptBuilder).to receive(:run).and_return(llm_prompt) }

            context 'with valid parameters' do
              let(:total_combinations) { num_llm_configs * num_llm_prompt_templates * num_passage_prompts }

              before { allow(RunExperimentWorker).to receive(:perform_async) }

              it { expect { subject }.to change(Experiment, :count).by(total_combinations) }

              it 'enqueues a worker for each combination and redirects' do
                expect(RunExperimentWorker).to receive(:perform_async).exactly(total_combinations).times
                subject
                expect(response).to redirect_to(research_gen_ai_experiments_path)
              end
            end

            context 'with invalid parameters' do
              let(:llm_config_ids) { [nil] }

              it { expect { subject }.not_to change(Experiment, :count) }

              it 'does not enqueue a worker' do
                expect(RunExperimentWorker).not_to receive(:perform_async)
                subject
              end
            end
          end
        end
      end
    end
  end
end