# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RuleFeedbackHistory, type: :model do
  before do
    # This is for CircleCI. Note that this refresh is NOT concurrent.
    ActiveRecord::Base.refresh_materialized_view('feedback_histories_grouped_by_rule_uid', concurrently: false)
  end

  describe '#generate_report' do
    it 'should format' do
      activity1 = create(:evidence_activity, title: 'Title 1', parent_activity_id: 1, target_level: 1, notes: 'an_activity_1')

      so_prompt1 = create(:evidence_prompt, activity: activity1, conjunction: 'so', text: 'Some feedback text', max_attempts_feedback: 'Feedback')
      because_prompt1 = create(:evidence_prompt, activity: activity1, conjunction: 'because', text: 'Some feedback text', max_attempts_feedback: 'Feedback')

      so_rule1 = create(:evidence_rule, name: 'so_rule1', rule_type: 'autoML')

      prompt_rule = create(:evidence_prompts_rule, prompt: so_prompt1, rule: so_rule1)

      so_feedback1 = create(:evidence_feedback, rule: so_rule1)
      so_feedback2 = create(:evidence_feedback, rule: so_rule1, order: 2)

      first_confidence_level = 0.9599
      second_confidence_level = 0.8523
      average_confidence_level = (((first_confidence_level + second_confidence_level) / 2) * 100).round

      f_h1 = create(:feedback_history, prompt: so_prompt1, rule_uid: so_rule1.uid, entry: 'f_h1 lorem', metadata: { api: { confidence: first_confidence_level } })
      f_h2 = create(:feedback_history, prompt: so_prompt1, rule_uid: so_rule1.uid, entry: 'f_h2 ipsum', metadata: { api: { confidence: second_confidence_level } })

      user1 = create(:user)
      user2 = create(:user)

      f_rating_1a = FeedbackHistoryRating.create!(feedback_history_id: f_h1.id, user_id: user1.id, rating: true)
      f_rating_1b = FeedbackHistoryRating.create!(feedback_history_id: f_h1.id, user_id: user2.id, rating: false)
      f_rating_2a = FeedbackHistoryRating.create!(feedback_history_id: f_h2.id, user_id: user1.id, rating: true)
      f_rating_2b = FeedbackHistoryRating.create!(feedback_history_id: f_h2.id, user_id: user2.id, rating: nil)

      flag_consecutive = create(:feedback_history_flag, feedback_history_id: f_h1.id, flag: FeedbackHistoryFlag::FLAG_REPEATED_RULE_CONSECUTIVE)
      flag_non_consecutive = create(:feedback_history_flag, feedback_history_id: f_h1.id, flag: FeedbackHistoryFlag::FLAG_REPEATED_RULE_NON_CONSECUTIVE)

      report = RuleFeedbackHistory.generate_report(conjunction: 'so', activity_id: activity1.id, start_date: nil, end_date: nil)

      expected = {
        api_name: so_rule1.rule_type,
        rule_order: so_rule1.suborder,
        first_feedback: so_feedback1.text,
        second_feedback: so_feedback2.text,
        avg_confidence: average_confidence_level,
        rule_name: so_rule1.name,
        rule_note: so_rule1.note,
        rule_uid: so_rule1.uid,
        strong_responses: 2,
        total_responses: 2,
        weak_responses: 1,
        repeated_consecutive_responses: 1,
        repeated_non_consecutive_responses: 1,
      }

      expect(report.first).to eq(expected)
    end
  end

  describe '#exec_query' do
    it 'should aggregate feedbacks for a given rule' do
      activity1 = create(:evidence_activity, title: 'Title 1', parent_activity_id: 1, target_level: 1, notes: 'an_activity_1')

      so_prompt1 = create(:evidence_prompt, activity: activity1, conjunction: 'so', text: 'Some feedback text', max_attempts_feedback: 'Feedback')
      because_prompt1 = create(:evidence_prompt, activity: activity1, conjunction: 'because', text: 'Some feedback text', max_attempts_feedback: 'Feedback')

      so_rule1 = create(:evidence_rule, name: 'so_rule1', rule_type: 'autoML')
      so_rule2 = create(:evidence_rule, name: 'so_rule2', rule_type: 'autoML')
      so_rule3 = create(:evidence_rule, name: 'so_rule3', rule_type: 'autoML')
      so_rule4 = create(:evidence_rule, name: 'so_rule4', rule_type: 'autoML')

      prompt_rule = create(:evidence_prompts_rule, prompt: so_prompt1, rule: so_rule1)
      prompt_rule = create(:evidence_prompts_rule, prompt: so_prompt1, rule: so_rule2)
      prompt_rule = create(:evidence_prompts_rule, prompt: so_prompt1, rule: so_rule3)
      prompt_rule = create(:evidence_prompts_rule, prompt: so_prompt1, rule: so_rule4)

      activity_session = create(:activity_session)

      create(:feedback_history, prompt: so_prompt1, rule_uid: so_rule2.uid, time: '2021-04-07T19:02:54.814Z', feedback_session_uid: 'def')
      create(:feedback_history, prompt: so_prompt1, rule_uid: so_rule3.uid, time: '2021-05-07T19:02:54.814Z', feedback_session_uid: 'ghi')
      create(:feedback_history, prompt: so_prompt1, rule_uid: so_rule4.uid, time: '2021-06-07T19:02:54.814Z', feedback_session_uid: 'abc')

      sql_result = RuleFeedbackHistory.exec_query(conjunction: 'so', activity_id: activity1.id, start_date: '2021-03-06T19:02:54.814Z', end_date: '2021-04-10T19:02:54.814Z')
      expect(sql_result.all.length).to eq 1
      expect(sql_result[0].rule_type).to eq 'autoML'
    end

    it 'should filter by activity_version if specified' do
      activity1 = create(:evidence_activity, title: 'Title 1', parent_activity_id: 1, target_level: 1, notes: 'an_activity_1')

      so_prompt1 = create(:evidence_prompt, activity: activity1, conjunction: 'so', text: 'Some feedback text', max_attempts_feedback: 'Feedback')
      because_prompt1 = create(:evidence_prompt, activity: activity1, conjunction: 'because', text: 'Some feedback text', max_attempts_feedback: 'Feedback')

      so_rule1 = create(:evidence_rule, name: 'so_rule1', rule_type: 'autoML')
      so_rule2 = create(:evidence_rule, name: 'so_rule2', rule_type: 'autoML')
      so_rule3 = create(:evidence_rule, name: 'so_rule3', rule_type: 'autoML')
      so_rule4 = create(:evidence_rule, name: 'so_rule4', rule_type: 'autoML')

      prompt_rule = create(:evidence_prompts_rule, prompt: so_prompt1, rule: so_rule1)
      prompt_rule = create(:evidence_prompts_rule, prompt: so_prompt1, rule: so_rule2)
      prompt_rule = create(:evidence_prompts_rule, prompt: so_prompt1, rule: so_rule3)
      prompt_rule = create(:evidence_prompts_rule, prompt: so_prompt1, rule: so_rule4)

      activity_session = create(:activity_session)

      create(:feedback_history, prompt: so_prompt1, rule_uid: so_rule2.uid, time: '2021-04-07T19:02:54.814Z', feedback_session_uid: 'def', activity_version: 2)
      create(:feedback_history, prompt: so_prompt1, rule_uid: so_rule3.uid, time: '2021-04-07T19:02:54.814Z', feedback_session_uid: 'ghi', activity_version: 2)
      create(:feedback_history, prompt: so_prompt1, rule_uid: so_rule4.uid, time: '2021-04-07T19:02:54.814Z', feedback_session_uid: 'abc', activity_version: 1)

      sql_result = RuleFeedbackHistory.exec_query(conjunction: 'so', activity_id: activity1.id, start_date: '2021-03-06T19:02:54.814Z', end_date: '2021-04-10T19:02:54.814Z', activity_version: 2)
      expect(sql_result.all.length).to eq 2
      expect(sql_result.select { |rf| rf['rules_uid'] == so_rule4.uid }.empty?).to be

      expect(sql_result[0].rule_type).to eq 'autoML'
    end
  end

  describe '#generate_rulewise_report' do
    it 'should render feedback histories' do
      so_rule1 = create(:evidence_rule, name: 'so_rule1', rule_type: 'autoML')
      unused_rule = create(:evidence_rule, name: 'unused', rule_type: 'autoML')

      f_h1 = create(:feedback_history, rule_uid: so_rule1.uid, prompt_id: 1)
      f_h2 = create(:feedback_history, rule_uid: so_rule1.uid, prompt_id: 1)
      f_h3 = create(:feedback_history, rule_uid: unused_rule.uid, prompt_id: 1)

      result = RuleFeedbackHistory.generate_rulewise_report(
        rule_uid: so_rule1.uid,
        prompt_id: 1,
        start_date: nil,
        end_date: nil
      )

      expect(result.keys.length).to eq 1
      expect(result.keys.first.to_s).to eq so_rule1.uid

      responses = result[so_rule1.uid.to_sym][:responses]

      response_ids = responses.map { |r| r[:response_id] }
      expect(
        Set[*response_ids] == Set[f_h1.id, f_h2.id]
      ).to be true
    end

    it 'should include rules that have no related FeedbackHistory records' do
      so_rule1 = create(:evidence_rule, name: 'so_rule1', rule_type: 'autoML')

      result = RuleFeedbackHistory.generate_rulewise_report(
        rule_uid: so_rule1.uid,
        prompt_id: 1,
        start_date: nil,
        end_date: nil
      )

      expect(result.keys.length).to eq 1
      expect(result.keys.first.to_s).to eq so_rule1.uid

      responses = result[so_rule1.uid.to_sym][:responses]

      expect(responses.length).to eq(0)
    end

    it 'should filter feedback histories by prompt id, used=true and time params' do
      so_rule1 = create(:evidence_rule, name: 'so_rule1', rule_type: 'autoML')
      unused_rule = create(:evidence_rule, name: 'unused', rule_type: 'autoML')
      activity_session = create(:activity_session)

      f_h1 = create(:feedback_history, rule_uid: so_rule1.uid)
      f_h2 = create(:feedback_history, rule_uid: so_rule1.uid, prompt_id: 1, created_at: '2021-02-07T19:02:54.814Z')
      f_h3 = create(:feedback_history, rule_uid: unused_rule.uid)
      f_h4 = create(:feedback_history, rule_uid: so_rule1.uid, prompt_id: 1, used: false)
      f_h5 = create(:feedback_history, rule_uid: so_rule1.uid, prompt_id: 1, created_at: '2021-03-07T19:02:54.814Z', feedback_session_uid: activity_session.uid)
      f_h6 = create(:feedback_history, rule_uid: so_rule1.uid, prompt_id: 1, created_at: '2021-05-07T19:02:54.814Z', feedback_session_uid: activity_session.uid)

      result = RuleFeedbackHistory.generate_rulewise_report(
        rule_uid: so_rule1.uid,
        prompt_id: 1,
        start_date: '2021-03-07T19:02:54.814Z',
        end_date: '2021-04-07T19:02:54.814Z'
      )

      expect(result.keys.length).to eq 1
      expect(result.keys.first.to_s).to eq so_rule1.uid

      responses = result[so_rule1.uid.to_sym][:responses]

      response_ids = responses.map { |r| r[:response_id] }

      expect(
        Set[*response_ids] == Set[f_h5.id]
      ).to be true
    end

    it 'should display the most recent feedback history rating, if it exists' do
      so_rule1 = create(:evidence_rule, name: 'so_rule1', rule_type: 'autoML')
      unused_rule = create(:evidence_rule, name: 'unused', rule_type: 'autoML')

      user1 = create(:user)
      user2 = create(:user)

      f_h1 = create(:feedback_history, rule_uid: so_rule1.uid, prompt_id: 1)
      f_h2 = create(:feedback_history, rule_uid: so_rule1.uid, prompt_id: 1)
      f_h3 = create(:feedback_history, rule_uid: unused_rule.uid, prompt_id: 1)

      f_h_r1_old = FeedbackHistoryRating.create!(
        feedback_history_id: f_h1.id,
        user_id: user1.id,
        rating: false,
        updated_at: 1.days.ago
      )
      f_h_r1_new = FeedbackHistoryRating.create!(
        feedback_history_id: f_h1.id,
        user_id: user2.id,
        rating: true,
        updated_at: Time.current
      )
      result = RuleFeedbackHistory.generate_rulewise_report(
        rule_uid: so_rule1.uid,
        prompt_id: 1,
        start_date: nil,
        end_date: nil
      )

      expect(result.keys.length).to eq 1
      expect(result.keys.first.to_s).to eq so_rule1.uid

      responses = result[so_rule1.uid.to_sym][:responses]

      rated_response = responses.find { |r| r[:response_id] == f_h1.id }

      expect(rated_response[:strength]).to eq true
    end
  end

  describe '#feedback_history_to_json' do
    it 'should render feedback history to json object' do
      so_rule = create(:evidence_rule, name: 'so_rule', rule_type: 'autoML')
      f_h = create(:feedback_history, rule_uid: so_rule.uid, prompt_id: 1)
      result = RuleFeedbackHistory.feedback_history_to_json(f_h)
      expected = {
        response_id: f_h.id,
        datetime: f_h.updated_at,
        entry: f_h.entry,
        highlight: f_h.metadata.instance_of?(Hash) ? f_h.metadata['highlight'] : '',
        api: {},
        session_uid: f_h.feedback_session_uid,
        strength: f_h.feedback_history_ratings.order(updated_at: :desc).first&.rating
      }
      expect(result).to eq expected
    end
  end
end
