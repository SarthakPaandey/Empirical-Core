# frozen_string_literal: true

require 'rails_helper'

module GoogleIntegration
  RSpec.describe ImportTeacherClassroomsStudentsWorker do
    subject { described_class.new }

    let(:teacher) { create(:teacher, :signed_up_with_google) }
    let(:selected_classroom_ids) { [123, 456] }

    it 'should report an error with nil teacher_id' do
      expect(ErrorNotifier).to receive(:report).with(ActiveRecord::RecordNotFound)
      subject.perform(nil)
    end

    it 'should report an error with not bad teacher_id' do
      expect(ErrorNotifier).to receive(:report).with(ActiveRecord::RecordNotFound)
      subject.perform(0)
    end

    it 'should not run importer when teacher is unauthorized' do
      expect(TeacherClassroomsStudentsImporter).to_not receive(:run)
      subject.perform(teacher.id)
    end

    context 'teacher is google authorized' do
      before { create(:google_auth_credential, user: teacher) }

      it 'should run importing with valid teacher id and no selected_classroom_ids' do
        expect(TeacherClassroomsStudentsImporter).to receive(:run).with(teacher, nil)
        subject.perform(teacher.id)
      end

      it 'should run importing with valid teacher id and selected_classroom_ids' do
        expect(TeacherClassroomsStudentsImporter).to receive(:run).with(teacher, selected_classroom_ids)
        subject.perform(teacher.id, selected_classroom_ids)
      end
    end
  end
end
