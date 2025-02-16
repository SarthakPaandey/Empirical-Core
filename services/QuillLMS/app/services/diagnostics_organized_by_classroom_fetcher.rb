# frozen_string_literal: true

class DiagnosticsOrganizedByClassroomFetcher < ApplicationService
  attr_reader :user

  ACTIVITY_IDS_TO_NAMES = {
    Activity::STARTER_DIAGNOSTIC_ACTIVITY_ID => 'Starter Diagnostic',
    Activity::INTERMEDIATE_DIAGNOSTIC_ACTIVITY_ID => 'Intermediate Diagnostic',
    Activity::ADVANCED_DIAGNOSTIC_ACTIVITY_ID => 'Advanced Diagnostic',
    Activity::ELL_STARTER_DIAGNOSTIC_ACTIVITY_ID => 'ELL Starter Diagnostic',
    Activity::ELL_INTERMEDIATE_DIAGNOSTIC_ACTIVITY_ID => 'ELL Intermediate Diagnostic',
    Activity::ELL_ADVANCED_DIAGNOSTIC_ACTIVITY_ID => 'ELL Advanced Diagnostic',
    Activity::OLD_STARTER_DIAGNOSTIC_ACTIVITY_ID => 'Starter Diagnostic - 2023-2024 School Year',
    Activity::OLD_INTERMEDIATE_DIAGNOSTIC_ACTIVITY_ID => 'Intermediate Diagnostic - 2023-2024 School Year',
    Activity::OLD_ADVANCED_DIAGNOSTIC_ACTIVITY_ID => 'Advanced Diagnostic - 2023-2024 School Year',
    Activity::OLD_ELL_STARTER_DIAGNOSTIC_ACTIVITY_ID => 'ELL Starter Diagnostic - 2023-2024 School Year',
    Activity::OLD_ELL_INTERMEDIATE_DIAGNOSTIC_ACTIVITY_ID => 'ELL Intermediate Diagnostic - 2023-2024 School Year',
    Activity::OLD_ELL_ADVANCED_DIAGNOSTIC_ACTIVITY_ID => 'ELL Advanced Diagnostic - 2023-2024 School Year'
  }.freeze

  QUESTION_SCORING_ELIGIBILITY_CUTOFF_DATE = DateTime.new(2023, 7, 19, 0, 0, 0)

  def initialize(user)
    @user = user
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def run
    classrooms = []
    post_test_ids = diagnostic_unit_records.map { |r| r['post_test_id'] }.compact

    diagnostic_unit_records.each do |record|
      next if post_test_ids.include?(record['activity_id'])

      index_of_existing_classroom = classrooms.find_index { |c| c['id'] == record['classroom_id'] }
      name = grouped_name(record)

      next if index_of_existing_classroom &&
              classrooms[index_of_existing_classroom]['diagnostics'].find { |diagnostic| diagnostic[:name] == name }

      grouped_record = {
        name: name,
        pre: record_with_aggregated_activity_sessions(
          record['activity_id'],
          record['classroom_id']
        )
      }

      if record['post_test_id']
        post_test = record_with_aggregated_activity_sessions(
          record['post_test_id'],
          record['classroom_id']
        )

        grouped_record[:post] = post_test || {
          activity_name: Activity.find_by_id(record['post_test_id'])&.name,
          unit_template_id: ActivitiesUnitTemplate.find_by_activity_id(record['post_test_id'])&.unit_template_id
        }
      end

      if index_of_existing_classroom
        classrooms[index_of_existing_classroom]['diagnostics'].push(grouped_record)
        next
      end

      classroom = {
        'name' => record['classroom_name'],
        'id' => record['classroom_id'],
        'diagnostics' => [grouped_record]
      }
      classrooms.push(classroom)
    end
    classrooms.to_json
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  private def diagnostic_unit_records
    @diagnostic_unit_records ||= DiagnosticUnitRecordsFetcher.run(user)
  end

  private def grouped_name(record)
    ACTIVITY_IDS_TO_NAMES[record['activity_id']] || record['activity_name']
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def record_with_aggregated_activity_sessions(activity_id, classroom_id)
    records = diagnostic_unit_records.select do |record|
      record['activity_id'] == activity_id && record['classroom_id'] == classroom_id
    end

    return if records.empty?

    classroom_unit_ids = records.map { |record| record['classroom_unit_id'] }
    assigned_student_ids = records.map { |r| r['assigned_student_ids'] }.flatten.uniq

    activity_sessions = ActivitySession
      .where(activity_id: activity_id, classroom_unit_id: classroom_unit_ids, state: 'finished', user_id: assigned_student_ids)
      .order(completed_at: :desc)
      .uniq { |activity_session| activity_session.user_id }

    record = records[0]
    return if !record

    record['eligible_for_question_scoring'] = activity_sessions.empty? || activity_sessions.last.completed_at > QUESTION_SCORING_ELIGIBILITY_CUTOFF_DATE
    record['completed_count'] = activity_sessions.size
    record['assigned_count'] = assigned_student_ids.size
    record.except('unit_id', 'unit_name', 'classroom_unit_id', 'assigned_student_ids')
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
