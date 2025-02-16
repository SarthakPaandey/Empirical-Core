# frozen_string_literal: true

require 'rails_helper'

module GoogleIntegration
  RSpec.describe ClassroomCreator do
    subject { described_class.run(data) }

    let(:teacher_id) { create(:teacher).id }

    let(:data) do
      {
        classroom_external_id: classroom_external_id,
        grade: grade,
        name: name,
        teacher_id: teacher_id
      }
    end

    let(:grade) { 2 }
    let(:classroom_external_id) { 123456 }

    context 'name present' do
      let(:name) { 'google classroom name' }

      it 'creates a new classroom object with synced_name attr initially set to name' do
        expect(::ClassroomsTeacher.count).to eq 0
        expect(subject.classroom_external_id).to eq classroom_external_id
        expect(subject.name).to eq name
        expect(subject.synced_name).to eq name
        expect(subject.classrooms_teachers.count).to eq 1
      end
    end

    context 'blank name' do
      let(:name) { nil }

      it 'creates a new classroom object with synced_name attr initially set to name' do
        expect(subject.classroom_external_id).to eq classroom_external_id
        expect(subject.name).to eq "Classroom #{classroom_external_id}"
        expect(subject.synced_name).to eq nil
      end
    end

    context "teacher owns another classroom with name #{name}" do
      let(:name) { 'google classroom name' }
      let(:classroom1) { create(:classroom, :from_google, :with_no_teacher, name: name) }

      before { create(:classrooms_teacher, user_id: teacher_id, classroom: classroom1) }

      it { expect(subject.classroom_external_id).to eq classroom_external_id }
      it { expect(subject.name).to eq "#{name}_1" }
      it { expect(subject.synced_name).to eq name }

      it { expect { subject }.to change(ClassroomsTeacher, :count).from(1).to(2) }

      context "teacher owns other classrooms with names #{name}_1, ... #{name}_max" do
        let(:max) { ::ValidNameBuilder::MAX_BEFORE_RANDOMIZED }

        before do
          2.upto(max) do |n|
            classroom = create(:classroom, :from_google, :with_no_teacher, name: "name_#{n}")
            create(:classrooms_teacher, user_id: teacher_id, classroom: classroom)
          end
        end

        it 'stops naming duplicates at max and then starts using random values' do
          expect(subject.name).not_to eq "#{name}_11"
        end

        it { expect { subject }.to change(ClassroomsTeacher, :count).from(max).to(11) }
      end
    end
  end
end
