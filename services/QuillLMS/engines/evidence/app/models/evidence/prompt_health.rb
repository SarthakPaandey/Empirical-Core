# frozen_string_literal: true

# == Schema Information
#
# Table name: evidence_prompt_healths
#
#  id                                  :bigint           not null, primary key
#  activity_short_name                 :string           not null
#  avg_attempts                        :float
#  avg_time_spent_per_prompt           :integer
#  confidence                          :float
#  current_version                     :integer          not null
#  final_attempt_optimal               :integer
#  first_attempt_optimal               :integer
#  percent_automl                      :integer
#  percent_automl_consecutive_repeated :integer
#  percent_grammar                     :integer
#  percent_opinion                     :integer
#  percent_plagiarism                  :integer
#  percent_spelling                    :integer
#  text                                :string           not null
#  version_responses                   :integer          not null
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  evidence_activity_health_id         :bigint
#  prompt_id                           :integer          not null
#
# Indexes
#
#  index_evidence_prompt_healths_on_evidence_activity_health_id  (evidence_activity_health_id)
#
# Foreign Keys
#
#  fk_rails_...  (evidence_activity_health_id => evidence_activity_healths.id) ON DELETE => cascade
#
module Evidence
  class PromptHealth < ApplicationRecord
    FIRST_ATTEMPT_OPTIMAL_CUTOFF = 25
    FINAL_ATTEMPT_OPTIMAL_CUTFF = 75
    CONFIDENCE_CUTOFF = 0.9
    PERCENT_AUTOML_CONSECUTIVE_REPEATED_CUTOFF = 30

    belongs_to :activity_health, foreign_key: 'evidence_activity_health_id'

    validates :current_version, numericality: { greater_than_or_equal_to: 1, allow_nil: true }
    validates :version_responses, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
    validates :first_attempt_optimal, inclusion: { in: 0..100, allow_nil: true }
    validates :final_attempt_optimal, inclusion: { in: 0..100, allow_nil: true }
    validates :avg_attempts, inclusion: { in: 0..5, allow_nil: true }
    validates :confidence, inclusion: { in: 0..1, allow_nil: true }
    validates :percent_automl_consecutive_repeated, inclusion: { in: 0..100, allow_nil: true }
    validates :percent_automl, inclusion: { in: 0..100, allow_nil: true }
    validates :percent_plagiarism, inclusion: { in: 0..100, allow_nil: true }
    validates :percent_opinion, inclusion: { in: 0..100, allow_nil: true }
    validates :percent_grammar, inclusion: { in: 0..100, allow_nil: true }
    validates :percent_spelling, inclusion: { in: 0..100, allow_nil: true }

    def serializable_hash(options = nil)
      options ||= {}

      super(options.reverse_merge(
        only:
          %i(
            id
            current_version
            version_responses
            first_attempt_optimal
            final_attempt_optimal
            avg_attempts
            confidence
            percent_automl_consecutive_repeated
            percent_automl
            percent_plagiarism
            percent_opinion
            percent_grammar
            percent_spelling
            text
            avg_time_spent_per_prompt
            prompt_id
            activity_short_name
          ),
        methods:
          %i(
            conjunction
            activity_id
            flag
            poor_health_flag
          )
      ))
    end

    def poor_health_flag
      (
        failed_cutoff(first_attempt_optimal, FIRST_ATTEMPT_OPTIMAL_CUTOFF) ||
        failed_cutoff(final_attempt_optimal, FINAL_ATTEMPT_OPTIMAL_CUTFF) ||
        failed_cutoff(confidence, CONFIDENCE_CUTOFF) ||
        (percent_automl_consecutive_repeated && percent_automl_consecutive_repeated > PERCENT_AUTOML_CONSECUTIVE_REPEATED_CUTOFF)
      )
    end

    def conjunction
      prompt && prompt.conjunction
    end

    def activity_id
      prompt && prompt.activity_id
    end

    def flag
      prompt && prompt.activity.flag
    end

    private def prompt
      @prompt ||= Prompt.find(prompt_id)
    end

    private def failed_cutoff(number, cutoff)
      number && number < cutoff
    end
  end
end
