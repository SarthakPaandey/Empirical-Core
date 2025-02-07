# frozen_string_literal: true

require 'rails_helper'

module AdminDiagnosticReports
  describe DiagnosticRecommendationsQuery do
    include_context 'Admin Diagnostic Aggregate CTE'

    context 'big_query_snapshot', :big_query_snapshot do
      let(:recommended_activity) { create(:activity) }
      let(:recommended_unit_template) { create(:unit_template, activities: [recommended_activity]) }
      let(:recommended_unit_templates) { [recommended_unit_template] }

      let(:units) { recommended_unit_templates.map { |ut| create(:unit, unit_template: ut) } }
      let(:recommendations) { recommended_unit_templates.map { |ut| create(:recommendation, activity: pre_diagnostic, unit_template: ut, category: 0) } }
      let(:classroom_units) do
        classrooms.map do |classroom|
          units.map { |unit| create(:classroom_unit, classroom: classroom, unit: unit) }
        end.flatten
      end

      let(:timespent) { 100 }

      let(:activity_sessions) { classroom_units.map { |classroom_unit| create(:activity_session, :finished, classroom_unit: classroom_unit, activity: recommended_activity, timespent: timespent) } }

      let(:students) { activity_sessions.map(&:user) }
      let(:grade_names) { classrooms.map(&:grade).uniq.map { |g| g.to_i > 0 ? "Grade #{g}" : g } }

      let(:pre_diagnostic_classroom_units) { classrooms.map { |classroom| create(:classroom_unit, classroom:, assigned_student_ids: students.pluck(:id)) } }
      let(:pre_diagnostic_activity_sessions) do
        pre_diagnostic_classroom_units.map do |classroom_unit|
          students.map do |student|
            create(:activity_session, :finished, user: student, classroom_unit: classroom_unit, activity: pre_diagnostic, completed_at: DateTime.current - 1.day)
          end
        end
      end

      # Some of our tests include activity_sessions having NULL in its timestamps so we need a version that has timestamps with datetime data in them so that WITH in the CTE understands the data type expected
      let(:reference_activity_session) { create(:activity_session, :finished) }

      let(:cte_records) do
        [
          classrooms,
          teachers,
          classrooms_teachers,
          schools,
          schools_users,
          classroom_units,
          pre_diagnostic,
          recommended_activity,
          recommended_unit_templates,
          units,
          recommendations,
          activity_sessions,
          students,
          pre_diagnostic_classroom_units,
          pre_diagnostic_activity_sessions,
          reference_activity_session
        ]
      end

      let(:students_completed_practice_results) { results.first[:students_completed_practice] }
      let(:average_time_spent_seconds_results) { results.first[:average_time_spent_seconds] }
      let(:average_practice_activities_count_results) { results.first[:average_practice_activities_count] }

      it { expect(results.first[:diagnostic_name]).to eq(pre_diagnostic.name) }
      it { expect(results.first[:aggregate_rows].map { |row| row[:name] }).to match_array(grade_names) }
      it { expect(students_completed_practice_results).to eq(students.length) }
      it { expect(average_time_spent_seconds_results).to eq(activity_sessions.map(&:timespent).sum / students.length) }
      it { expect(average_practice_activities_count_results).to eq(activity_sessions.length / students.length) }

      context 'no recommendations assigned' do
        let(:activity_sessions) { [] }

        it { expect(results).to eq([]) }
      end

      context 'recommendations assigned but not completed' do
        let(:activity_sessions) { classroom_units.map { |classroom_unit| create(:activity_session, :unstarted, classroom_unit: classroom_unit, activity: recommended_activity, timespent: timespent) } }

        it { expect(results).to eq([]) }
      end

      context 'no visible activity sessions' do
        let(:activity_sessions) { classroom_units.map { |classroom_unit| create(:activity_session, :finished, classroom_unit: classroom_unit, activity: recommended_activity, visible: false) } }

        it { expect(results).to eq([]) }
      end

      context 'a mix of completed and incomplete recommendations' do
        let(:complete_activity_sessions) { [create(:activity_session, :finished, classroom_unit: classroom_units.first, activity: recommended_activity, timespent: timespent)] }
        let(:incomplete_activity_sessions) { [create(:activity_session, :unstarted, classroom_unit: classroom_units.first, activity: recommended_activity, timespent: timespent)] }
        let(:activity_sessions) { [complete_activity_sessions, incomplete_activity_sessions].flatten }

        let(:expected_students_completed) { complete_activity_sessions.map(&:user_id).uniq.length }

        it { expect(students_completed_practice_results).to eq(expected_students_completed) }
        it { expect(average_time_spent_seconds_results).to eq(complete_activity_sessions.map(&:timespent).sum / expected_students_completed) }
        it { expect(average_practice_activities_count_results).to eq(complete_activity_sessions.length / expected_students_completed) }
      end

      context 'one student with many recommendations' do
        let(:time_spent_results) { [10, 20, 30, 40, 50] }
        let(:student) { create(:student) }
        let(:students) { [student] }
        let(:activity_sessions) { time_spent_results.map { |timespent| create(:activity_session, :finished, classroom_unit: classroom_units.first, activity: recommended_activity, timespent: timespent, user: student) } }

        it { expect(students_completed_practice_results).to eq(students.length) }
        it { expect(average_time_spent_seconds_results).to eq(time_spent_results.sum / students.length) }
        it { expect(average_practice_activities_count_results).to eq(activity_sessions.length / students.length) }
      end

      context 'one student in multiple classrooms' do
        let(:timespent) { 10 }
        let(:num_classrooms) { 2 }
        let(:classrooms) { create_list(:classroom, num_classrooms, grade: 9) }
        let(:student) { create(:student, classrooms: classrooms) }
        let(:students) { [student] }
        let(:activity_sessions) do
          classroom_units.map do |classroom_unit|
            create(:activity_session, :finished, classroom_unit: classroom_unit, activity: recommended_activity, timespent: timespent, user: student)
          end
        end
        let(:students_classrooms_count) { students.map(&:classrooms).flatten.length }

        it { expect(students_completed_practice_results).to eq(students_classrooms_count) }
        it { expect(average_time_spent_seconds_results).to eq(timespent) }
        it { expect(average_practice_activities_count_results).to eq(activity_sessions.length / students_classrooms_count) }
      end

      context 'student who has been assigned recommendation activities indepenedently via the library, but has not done the pre diagnostic' do
        let(:pre_diagnostic_activity_sessions) { [] }

        it { expect(results).to eq([]) }
      end
    end
  end
end
