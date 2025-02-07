# frozen_string_literal: true

module VitallyIntegration
  class PreviousYearTeacherDatum
    include VitallyTeacherStats
    include VitallySharedFunctions

    def initialize(user, year)
      @user = user
      @vitally_entity = user
      @school_year_start = Date.new(year, 7, 1)
      @school_year_end = school_year_start + 1.year
    end

    def calculate_data
      raise 'Cannot calculate data for a school year that is still ongoing.' if school_year_end > Time.current

      active_students = active_students_query.where('activity_sessions.completed_at >= ? and activity_sessions.completed_at < ?', school_year_start, school_year_end).count
      activities_assigned = activities_assigned_in_year_count
      activities_finished = activities_finished_query.where('activity_sessions.completed_at >= ? and activity_sessions.completed_at < ?', school_year_start, school_year_end).count
      diagnostics_assigned_this_year = diagnostics_assigned_in_year_count
      diagnostics_finished_this_year = diagnostics_finished.where('activity_sessions.completed_at >=? and activity_sessions.completed_at < ?', school_year_start, school_year_end).count
      evidence_activities_assigned_this_year = evidence_assigned_in_year_count
      evidence_activities_completed_this_year = evidence_completed_in_year_count
      completed_evidence_activities_per_student_this_year = activities_per_student(active_students, evidence_activities_completed_this_year)
      {
        total_students: total_students_in_year,
        active_students: active_students,
        activities_assigned: activities_assigned,
        completed_activities: activities_finished,
        completed_activities_per_student: activities_per_student(active_students, activities_finished),
        percent_completed_activities: activities_assigned > 0 ? (activities_finished.to_f / activities_assigned).round(2) : 'N/A',
        diagnostics_assigned: diagnostics_assigned_this_year,
        diagnostics_finished: diagnostics_finished_this_year,
        evidence_activities_assigned: evidence_activities_assigned_this_year,
        evidence_activities_completed: evidence_activities_completed_this_year,
        completed_evidence_activities_per_student: completed_evidence_activities_per_student_this_year,
        percent_completed_diagnostics: diagnostics_assigned_this_year > 0 ? (diagnostics_finished_this_year.to_f / diagnostics_assigned_this_year).round(2) : 'N/A'
      }
    end
  end
end
