# frozen_string_literal: true

class PromptFeedbackHistory
  def self.run(activity_id:, start_date: nil, end_date: nil, activity_version: nil)
    serialize_results prompt_health_query(activity_id: activity_id, start_date: start_date, end_date: end_date, activity_version: activity_version)
  end

  def self.prompt_health_query(activity_id:, start_date: nil, end_date: nil, activity_version: nil)
    query = FeedbackHistory.select(<<~SELECT
      prompt_id,
      COUNT(DISTINCT feedback_histories.id) AS total_responses,
      COUNT(DISTINCT feedback_histories.feedback_session_uid) AS session_count,
      comprehension_prompts.text AS display_name,
      COUNT(DISTINCT CASE WHEN optimal = true THEN feedback_histories.feedback_session_uid END) AS num_final_attempt_optimal,
      COUNT(DISTINCT CASE WHEN attempt = 5 AND optimal = false THEN feedback_histories.feedback_session_uid END) AS num_final_attempt_not_optimal,
      1.0 * COUNT(feedback_histories.attempt) / COUNT(DISTINCT feedback_histories.feedback_session_uid) AS avg_attempts,
      COUNT(DISTINCT CASE WHEN flag = 'repeated-consecutive' THEN feedback_histories.feedback_session_uid END) AS num_sessions_consecutive_repeated,
      COUNT(DISTINCT CASE WHEN flag = 'repeated-non-consecutive' THEN feedback_histories.feedback_session_uid END) AS num_sessions_non_consecutive_repeated,
      COUNT(DISTINCT CASE WHEN attempt = 1 AND optimal = true THEN feedback_histories.feedback_session_uid END) AS num_first_attempt_optimal,
      COUNT(DISTINCT CASE WHEN attempt = 1 AND optimal = false THEN feedback_histories.feedback_session_uid END) AS num_first_attempt_not_optimal,
      AVG(CAST((feedback_histories.metadata->>'api')::json->>'confidence' AS float)) AS avg_confidence
    SELECT
                                  )
      .joins('JOIN comprehension_prompts ON feedback_histories.prompt_id = comprehension_prompts.id')
      .joins('LEFT JOIN feedback_history_flags ON feedback_histories.id = feedback_history_flags.feedback_history_id')
      .joins('LEFT JOIN feedback_sessions ON feedback_histories.feedback_session_uid = feedback_sessions.uid')
      .joins('LEFT JOIN activity_sessions ON feedback_sessions.activity_session_uid = activity_sessions.uid')
      .where(used: true)
      .where('comprehension_prompts.activity_id = ?', activity_id)
      .group('feedback_histories.prompt_id, comprehension_prompts.text')
    query = query.where('feedback_histories.activity_version = ?', activity_version) if activity_version
    query = query.where('feedback_histories.created_at >= ?', start_date) if start_date
    query = query.where('feedback_histories.created_at <= ?', end_date) if end_date
    query
  end

  def self.average_time_spent_query(prompt_id:, start_date: nil, end_date: nil, activity_version: nil)
    inner_query = ActivitySession.unscoped.select(<<~SELECT
      CAST(CASE
        WHEN comprehension_prompts.conjunction = 'because' THEN (activity_sessions.data->>'time_tracking')::json->>'because'
        WHEN comprehension_prompts.conjunction = 'but' THEN (activity_sessions.data->>'time_tracking')::json->>'but'
        WHEN comprehension_prompts.conjunction = 'so' THEN (activity_sessions.data->>'time_tracking')::json->>'so'
        ELSE '0'
      END AS int) AS time_spent
    SELECT
                                                 )
      .joins('RIGHT JOIN feedback_sessions ON feedback_sessions.activity_session_uid = activity_sessions.uid')
      .joins('RIGHT JOIN feedback_histories ON feedback_histories.feedback_session_uid = feedback_sessions.uid')
      .joins('RIGHT JOIN comprehension_prompts ON feedback_histories.prompt_id = comprehension_prompts.id')
      .where('feedback_histories.used = true')
      .where('feedback_histories.prompt_id = ?', prompt_id)
      .group('activity_sessions.id, comprehension_prompts.conjunction')

    inner_query = inner_query.where('feedback_histories.activity_version = ?', activity_version) if activity_version
    inner_query = inner_query.where('feedback_histories.created_at >= ?', start_date) if start_date
    inner_query = inner_query.where('feedback_histories.created_at <= ?', end_date) if end_date
    inner_query = inner_query.to_sql

    time_spent = ActivitySession.unscoped.select('avg(time_spent) agg_sessions').from(
      "(#{inner_query}) as agg_sessions"
    ).to_a

    time_spent[0]['agg_sessions']
  end

  def self.serialize_results(results, start_date: nil, end_date: nil, activity_version: nil)
    results.to_h { |result|
      [result.prompt_id, ResultSerializer.new(result, average_time_spent_query(prompt_id: result.prompt_id, start_date: start_date, end_date: end_date, activity_version: activity_version)).run]
    }
  end

  class ResultSerializer
    SERIALIZED_ATTRIBUTES = [
      :avg_attempts,
      :avg_confidence,
      :avg_time_spent,
      :display_name,
      :num_final_attempt_not_optimal,
      :num_final_attempt_optimal,
      :num_first_attempt_not_optimal,
      :num_first_attempt_optimal,
      :prompt_id,
      :session_count,
      :total_responses
    ]

    attr_reader :payload, :result, :time_spent

    def initialize(result, time_spent)
      @result = result
      @time_spent = time_spent
      @payload = result.serializable_hash(only: SERIALIZED_ATTRIBUTES, include: [])
    end

    def run
      payload.merge(
        'avg_attempts' => avg_attempts,
        'avg_confidence' => avg_confidence,
        'num_sessions_with_consecutive_repeated_rule' => result.num_sessions_consecutive_repeated,
        'num_sessions_with_non_consecutive_repeated_rule' => result.num_sessions_non_consecutive_repeated,
        'avg_time_spent' => time_spent && Utils::Numeric.seconds_to_human_readable_time(time_spent)
      )
    end

    def avg_attempts
      payload['avg_attempts']&.round(2)&.to_f || 0
    end

    def avg_confidence
      payload['avg_confidence'] ? payload['avg_confidence'].round(2) * 100 : 0
    end
  end
end
