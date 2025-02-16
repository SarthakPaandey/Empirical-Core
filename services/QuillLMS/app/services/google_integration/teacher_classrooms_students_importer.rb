# frozen_string_literal: true

module GoogleIntegration
  class TeacherClassroomsStudentsImporter < ApplicationService
    attr_reader :teacher, :selected_classroom_ids

    def initialize(teacher, selected_classroom_ids)
      @teacher = teacher
      @selected_classroom_ids = selected_classroom_ids
    end

    def run
      import_classrooms_students
    end

    private def client
      @client ||= ClientFetcher.run(teacher)
    end

    private def classrooms
      selected_classroom_ids ? ::Classroom.where(id: selected_classroom_ids) : teacher.google_classrooms
    end

    private def classrooms_students_data
      classrooms.map { |classroom| ClassroomStudentsData.new(classroom, client) }
    end

    private def import_classrooms_students
      classrooms_students_data.each { |classroom_students_data| ClassroomStudentsImporter.run(classroom_students_data) }
    end
  end
end
