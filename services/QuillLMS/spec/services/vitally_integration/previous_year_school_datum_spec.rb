# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VitallyIntegration::PreviousYearSchoolDatum, type: :model do
  context '#calculate_data' do
    let!(:evidence) { create(:evidence) }
    let!(:year) { 2016 }
    let!(:student) { create(:user, last_sign_in: Date.new(year, 10, 2)) }
    let!(:student2) { create(:user, last_sign_in: Date.new(year, 10, 2)) }
    let!(:current_student) { create(:user, last_sign_in: Date.new(2021, 10, 2)) }
    let!(:teacher) { create(:user, role: 'teacher') }
    let!(:relevent_classroom) { create(:classroom, created_at: Date.new(year, 10, 1), visible: true) }
    let!(:current_classroom) { create(:classroom, created_at: Date.new(2021, 10, 1)) }
    let!(:school) { create(:school) }
    let!(:unit) { create(:unit, user_id: teacher.id) }
    let!(:evidence_activity) { create(:evidence_lms_activity) }
    let!(:classroom_unit1) { create(:classroom_unit, unit: unit, classroom: relevent_classroom, created_at: Date.new(year, 10, 1), assigned_student_ids: [student.id, student2.id]) }

    before do
      create(:unit_activity, unit: unit, activity: evidence_activity, created_at: Date.new(year, 10, 1))
      create(:classrooms_teacher, user: teacher, classroom: relevent_classroom)
      create(:classrooms_teacher, user: teacher, classroom: current_classroom)
      create(:students_classrooms, student: student, classroom: relevent_classroom)
      create(:students_classrooms, student: student2, classroom: relevent_classroom)
      create(:students_classrooms, student: current_student, classroom: current_classroom)
      create(:schools_users, user: teacher, school: school)
      create(:activity_session,
        user: student,
        classroom_unit: classroom_unit1,
        state: 'finished',
        completed_at: Date.new(year, 10, 2),
        updated_at: Date.new(year, 10, 2),
        activity: evidence_activity)
    end

    it 'should raise error if the year is the current year' do
      expect { described_class.new(school, Date.current.year).calculate_data }.to raise_error('Cannot calculate data for a school year that is still ongoing.')
    end

    it 'should calculate active students' do
      expected_data = {
        total_students: 2,
        active_students: 1,
        activities_finished: 1,
        activities_per_student: 1.0,
        completed_evidence_activities_per_student: 1,
        evidence_activities_assigned: 2,
        evidence_activities_completed: 1
      }
      teacher_data = described_class.new(school, year).calculate_data
      expect(teacher_data).to eq(expected_data)
    end
  end
end
