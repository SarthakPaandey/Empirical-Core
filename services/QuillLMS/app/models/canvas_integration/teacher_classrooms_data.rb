# frozen_string_literal: true

module CanvasIntegration
  class TeacherClassroomsData
    include Enumerable

    attr_reader :user, :serialized_classrooms_data

    def initialize(user, serialized_classrooms_data)
      @user = user
      @serialized_classrooms_data = serialized_classrooms_data
    end

    def each(&block)
      classrooms_data.each(&block)
    end

    private def classrooms_data
      JSON
        .parse(serialized_classrooms_data)
        .map(&:deep_symbolize_keys)
        .map { |data| data.merge(teacher_id: user.id) }
    end
  end
end
