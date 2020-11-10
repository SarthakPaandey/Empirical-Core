class ProgressReports::Standards::AllClassroomsStandard
  def initialize(teacher)
    @teacher = teacher
    @proficiency_cutoff = ProficiencyEvaluator.proficiency_cutoff
  end

  def results(classroom_id, student_id)
    ActiveRecord::Base.connection.execute("WITH final_activity_sessions AS
     (SELECT activity_sessions.*, activities.standard_id FROM activity_sessions
          JOIN classroom_units ON activity_sessions.classroom_unit_id = classroom_units.id
          JOIN activities ON activity_sessions.activity_id = activities.id
          LEFT JOIN standards ON standards.id = activities.standard_id
          #{classroom_joins(classroom_id)}
          WHERE activity_sessions.is_final_score
          #{student_condition(student_id)}
          #{classroom_condition(classroom_id)}
          AND activity_sessions.visible
          AND classroom_units.visible)
      SELECT standards.id,
        standards.name,
        standard_levels.name as standard_level_name,
        COUNT(DISTINCT(final_activity_sessions.activity_id)) as total_activity_count,
        COUNT(DISTINCT(final_activity_sessions.user_id)) as total_student_count,
        COUNT(DISTINCT(avg_score_for_standard_by_user.user_id)) as proficient_count
        FROM standards
          JOIN standard_levels ON standard_levels.id = standards.standard_level_id
          JOIN final_activity_sessions ON final_activity_sessions.standard_id = standards.id
          LEFT JOIN (select standard_id, user_id, AVG(percentage) as avg_score
          FROM final_activity_sessions
          GROUP BY final_activity_sessions.standard_id, final_activity_sessions.user_id
          HAVING AVG(percentage) >= 0.8
          ) as avg_score_for_standard_by_user ON avg_score_for_standard_by_user.standard_id = standards.id
        GROUP BY standards.id, standard_levels.name
        ORDER BY standards.name asc").to_a
  end

  def classroom_joins(classroom_id)
    if !classroom_id
      "JOIN classrooms ON classroom_units.classroom_id = classrooms.id JOIN classrooms_teachers ON classrooms.id = classrooms_teachers.classroom_id AND classrooms_teachers.user_id = #{@teacher.id} AND classrooms.visible = true"
    end
  end

  def classroom_condition(classroom_id)
    if classroom_id
      "AND classroom_units.classroom_id = #{classroom_id}"
    end
  end

  def student_condition(student_id)
    if student_id
      "AND activity_sessions.user_id = #{student_id}"
    end
  end
end