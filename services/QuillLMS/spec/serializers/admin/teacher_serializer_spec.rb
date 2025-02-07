# frozen_string_literal: true

require 'rails_helper'

describe Admin::TeacherSerializer do
  it_behaves_like 'serializer' do
    let!(:teacher) { create(:teacher) }
    let(:record_instance) { TeachersData.run([teacher.id])[0] }
    let(:result_key) { 'teacher' }

    let(:expected_serialized_keys) do
      %w{
        id
        name
        email
        last_sign_in
        schools
        number_of_students
        has_valid_subscription
        admin_info
      }
    end
  end

  describe 'serializer properties' do
    let!(:school1) { create(:school) }
    let!(:school2) { create(:school) }
    let!(:classroom) { create(:classroom_with_a_couple_students) }
    let!(:teacher) { classroom.owner }
    let!(:student1) { classroom.students.first }
    let!(:student2) { classroom.students.last }
    let!(:school_users1) { create(:schools_users, user: teacher, school: school2) }
    let!(:schools_users2) { create(:schools_users, user: classroom.students.first, school: school2) }
    let!(:schools_users3) { create(:schools_users, user: classroom.students.last, school: school2) }
    let!(:schools_admins1) { create(:schools_admins, user: teacher, school: school1) }
    let!(:schools_admins2) { create(:schools_admins, user: teacher, school: school2) }
    let!(:unit) { create(:unit, user_id: teacher.id) }
    let!(:time2) { Time.current }
    let!(:time1) { time2 - (10.minutes) }
    let!(:classroom_unit) { create(:classroom_unit, classroom_id: classroom.id, unit: unit, assigned_student_ids: classroom.students.ids) }
    let!(:activity_session1) { create(:activity_session_without_concept_results, user: student1, state: 'finished', started_at: time1, completed_at: time2, classroom_unit: classroom_unit) }
    let!(:activity_session2) { create(:activity_session_without_concept_results, user: student1, state: 'finished', started_at: time1, completed_at: time2, classroom_unit: classroom_unit) }
    let!(:activity_session3) { create(:activity_session_without_concept_results, user: student2, state: 'finished', started_at: time1, completed_at: time2, classroom_unit: classroom_unit) }
    let!(:activity_session4) { create(:activity_session_without_concept_results, user: student2, state: 'started', started_at: time1, completed_at: nil, classroom_unit: classroom_unit) }
    let!(:record_instance) { TeachersData.run([teacher.id])[0] }

    subject { described_class.new(record_instance) }

    it 'returns the expected payload' do
      expect(subject.schools.count).to eq(2)
      expect(subject.number_of_students).to eq(classroom.students.count)
    end

    describe 'role value' do
      it 'returns the user who does have a school admin record with an Admin role' do
        expect(subject.schools[0][:role]).to eq('Admin')
      end

      it 'returns the user who does not have a school admin record with a Teacher role' do
        user_with_admin_role = create(:admin)
        create(:schools_users, user: user_with_admin_role, school: school2)

        record_for_user_with_admin_role = TeachersData.run([user_with_admin_role.id])[0]
        expect(described_class.new(record_for_user_with_admin_role).schools[0][:role]).to eq('Teacher')
      end
    end
  end
end
