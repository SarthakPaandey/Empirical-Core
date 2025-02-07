# frozen_string_literal: true

class Teachers::ProgressReports::DiagnosticReportsController < Teachers::ProgressReportsController
  include PublicProgressReports
  include LessonsRecommendations
  include DiagnosticReports

  before_action :authorize_teacher!,
    only: [
      :growth_results_summary,
      :lesson_recommendations_for_classroom,
      :previously_assigned_recommendations,
      :student_ids_for_previously_assigned_activity_pack,
      :assign_post_test,
      :question_view,
      :recommendations_for_classroom,
      :results_summary,
      :students_by_classroom
    ]

  def show
    set_banner_variables
    @classroom_id = current_user.classrooms_i_teach&.last&.id || nil
    @report = params[:report] || 'question'
  end

  def question_view
    set_activity_sessions_and_assigned_students_for_activity_classroom_and_unit(params[:activity_id], params[:classroom_id], params[:unit_id])
    activity = Activity.includes(:classification)
      .find(params[:activity_id])
    render json: { data: results_by_question(params[:activity_id]),
                   classification: activity.classification.key }.to_json
  end

  def students_by_classroom
    classroom = Classroom.find(params[:classroom_id])
    cache_groups = {
      activity_id: params[:activity_id],
      unit_id: params[:unit_id]
    }
    response = current_user.classroom_cache(classroom, key: 'teachers.progress_reports.diagnostic_reports.student_by_classroom', groups: cache_groups) do
      results_for_classroom(params[:unit_id], params[:activity_id], params[:classroom_id])
    end
    render json: response
  end

  def finished_activity_sessions_for_student
    classroom = Classroom.find(params[:classroom_id])

    cache_groups = {
      activity_id: params[:activity_id],
      unit_id: params[:unit_id],
      student_id: params[:student_id]
    }
    response = current_user.classroom_cache(classroom, key: 'teachers.progress_reports.diagnostic_reports.finished_activity_sessions_for_student', groups: cache_groups) do
      finished_activity_sessions_for_unit_activity_classroom_and_student(params[:unit_id], params[:activity_id], params[:classroom_id], params[:student_id])
    end
    render json: { activity_sessions: response }
  end

  def individual_student_diagnostic_responses
    data = fetch_individual_student_diagnostic_responses_cache

    return render json: data, status: 404 if data.empty?

    render json: data
  end

  private def fetch_individual_student_diagnostic_responses_cache
    activity_id = individual_student_diagnostic_responses_params[:activity_id]
    classroom_id = individual_student_diagnostic_responses_params[:classroom_id]
    unit_id = individual_student_diagnostic_responses_params[:unit_id]
    student_id = individual_student_diagnostic_responses_params[:student_id]

    cache_groups = {
      student_id: student_id
    }

    current_user.classroom_unit_by_ids_cache(
      classroom_id: classroom_id,
      unit_id: unit_id,
      activity_id: activity_id,
      key: 'diagnostic_reports.individual_student_diagnostic_responses',
      groups: cache_groups
    ) do
      activity_session = find_activity_session_for_student_activity_and_classroom(student_id, activity_id, classroom_id, unit_id)

      if !activity_session
        return {}
      end

      student = User.find_by_id(student_id)
      skill_groups = activity_session.activity.skill_groups
      pre_test = Activity.find_by_follow_up_activity_id(activity_id)
      pre_test_activity_session = pre_test && find_activity_session_for_student_activity_and_classroom(student_id, pre_test.id, classroom_id, nil)

      if pre_test && pre_test_activity_session
        pre_questions = format_concept_results(pre_test_activity_session, pre_test_activity_session.concept_results.order('question_number::int'))
        post_questions = format_concept_results(activity_session, activity_session.concept_results.order('question_number::int'))
        concept_results = {
          pre: { questions: pre_questions },
          post: { questions: post_questions }
        }
        skill_group_results = GrowthResultsSummary.skill_groups_for_session(skill_groups, activity_session, pre_test_activity_session, student.name)
      else
        concept_results = { questions: format_concept_results(activity_session, activity_session.concept_results.order('question_number::int')) }
        skill_group_results = ResultsSummary.skill_groups_for_session(skill_groups, activity_session.concept_results, student.name)
      end
      { concept_results: concept_results, skill_group_results: skill_group_results, name: student.name }
    end
  end

  def classrooms_with_students
    render json: fetch_classrooms_with_students_cache
  end

  private def fetch_classrooms_with_students_cache
    cache_groups = {
      unit_id: params[:unit_id],
      activity_id: params[:activity_id]
    }

    current_user.all_classrooms_cache(key: 'teachers.progress_reports.diagnostic_reports.classrooms_with_students', groups: cache_groups) do
      classrooms_with_students_for_report(params[:unit_id], params[:activity_id]).to_json
    end
  end

  def recommendations_for_classroom
    render json: generate_recommendations_for_classroom(current_user, params[:unit_id], params[:classroom_id], params[:activity_id])
  end

  def lesson_recommendations_for_classroom
    lesson_recs = current_user.classroom_unit_by_ids_cache(
      classroom_id: params[:classroom_id],
      unit_id: params[:unit_id],
      activity_id: params[:activity_id],
      key: 'diagnostic_reports.lesson_recommendations_for_classroom'
    ) do
      get_recommended_lessons(current_user, params[:unit_id], params[:classroom_id], params[:activity_id])
    end

    render json: { lessonsRecommendations: lesson_recs }
  end

  def diagnostic_activity_ids
    render json: { diagnosticActivityIds: Activity.diagnostic_activity_ids }
  end

  def activity_with_recommendations_ids
    render json: { activityWithRecommendationsIds: Activity.activity_with_recommendations_ids }
  end

  def previously_assigned_recommendations
    render json: get_previously_assigned_recommendations_by_classroom(params[:classroom_id], params[:activity_id])
  end

  def student_ids_for_previously_assigned_activity_pack
    classroom = Classroom.find(params[:classroom_id])
    teacher_id = classroom.owner.id

    units = Units::AssignmentHelpers.find_units_from_unit_template_and_teacher(params[:activity_pack_id], teacher_id)

    render json: { student_ids: assigned_student_ids_for_classroom_and_units(classroom, units) }
  end

  def redirect_to_report_for_most_recent_activity_session_associated_with_activity_and_unit
    params.permit(:unit_id, :activity_id)
    unit_id = params[:unit_id]
    activity_id = params[:activity_id]
    classroom_units = ClassroomUnit.where(unit_id: unit_id, classroom_id: current_user.classrooms_i_teach.map(&:id))
    last_activity_session = ActivitySession.where(classroom_unit: classroom_units, activity_id: activity_id, is_final_score: true).order(updated_at: :desc).limit(1)&.first
    classroom_id = last_activity_session&.classroom_unit&.classroom_id

    if !classroom_id
      return render json: {}, status: 404
    elsif Activity.diagnostic_activity_ids.include?(activity_id.to_i)
      activity_is_a_post_test = Activity.find_by(follow_up_activity_id: activity_id).present?
      unit_query_string = "?unit=#{unit_id}"
      render json: { url: "/teachers/progress_reports/diagnostic_reports#/diagnostics/#{activity_id}/classroom/#{classroom_id}/responses#{unit_query_string}" }
    else
      render json: { url: "/teachers/progress_reports/diagnostic_reports#/u/#{unit_id}/a/#{activity_id}/c/#{classroom_id}/students" }
    end
  end

  def assign_post_test
    Units::AssignmentHelpers.assign_unit_to_one_class(params[:classroom_id], params[:unit_template_id], params[:student_ids], false)

    render json: {}
  end

  def assign_independent_practice_packs
    IndependentPracticePacksAssigner.run(
      assigning_all_recommended_packs: params[:assigning_all_recommended_packs],
      classroom_id: params[:classroom_id],
      diagnostic_activity_id: params[:diagnostic_activity_id],
      release_method: params[:release_method],
      selections: params[:selections],
      user: current_user
    )

    render json: {}
  rescue IndependentPracticePacksAssigner::TeacherNotAssociatedWithClassroomError => e
    render json: { error: e.message }, status: 401
  end

  def assign_whole_class_instruction_packs
    return render json: {}, status: 401 unless params[:classroom_id].to_i.in?(current_user.classrooms_i_teach.pluck(:id))

    set_lesson_diagnostic_recommendations_start_time
    last_recommendation_index = params[:unit_template_ids].length - 1

    params[:unit_template_ids].each_with_index do |unit_template_id, index|
      AssignRecommendationsWorker.perform_async(
        {
          'assign_on_join' => true,
          'classroom_id' => params[:classroom_id],
          'is_last_recommendation' => (index == last_recommendation_index),
          'lesson' => true,
          'student_ids' => [],
          'unit_template_id' => unit_template_id
        }
      )
    end

    render json: {}
  end

  def default_diagnostic_report
    redirect_to default_diagnostic_url
  end

  def report_from_classroom_unit_and_activity
    activity = Activity.find_by_id_or_uid(params[:activity_id])
    url = classroom_report_url(params[:classroom_unit_id].to_i, activity.id)

    redirect_to url || teachers_progress_reports_landing_page_path
  end

  def report_from_classroom_unit_and_activity_and_user
    classroom_unit = ClassroomUnit.find(params[:classroom_unit_id])
    unit_id = classroom_unit.unit_id
    classroom_id = classroom_unit.classroom_id
    act_sesh_report = activity_session_report(unit_id, classroom_id, params[:user_id].to_i, params[:activity_id].to_i)
    respond_to do |format|
      format.html { redirect_to act_sesh_report[:url] }
      format.json { render json: act_sesh_report.to_json }
    end
  end

  def report_from_classroom_and_unit_and_activity_and_user
    act_sesh_report = activity_session_report(params[:unit_id], params[:classroom_id], params[:user_id].to_i, params[:activity_id].to_i)
    respond_to do |format|
      format.html { redirect_to act_sesh_report[:url] }
      format.json { render json: act_sesh_report.to_json }
    end
  end

  def diagnostic_status
    cas = RawSqlRunner.execute(
      <<-SQL
        SELECT activity_sessions.state
        FROM classrooms_teachers
        JOIN classrooms
          ON  classrooms_teachers.classroom_id = classrooms.id
          AND classrooms.visible = true
        JOIN classroom_units
          ON  classrooms.id = classroom_units.classroom_id
          AND classroom_units.visible = true
        JOIN unit_activities
          ON classroom_units.unit_id = unit_activities.unit_id
          AND unit_activities.visible = true
          AND unit_activities.activity_id IN (#{Activity.diagnostic_activity_ids.join(', ')})
        LEFT JOIN activity_sessions
          ON  classroom_units.id = activity_sessions.classroom_unit_id
          AND unit_activities.activity_id = activity_sessions.activity_id
          AND activity_sessions.state = 'finished'
          AND activity_sessions.visible = true
        WHERE classrooms_teachers.user_id = #{current_user.id}
      SQL
    ).to_a

    if cas.include?('finished')
      diagnostic_status = 'completed'
    elsif cas.any?
      diagnostic_status = 'assigned'
    else
      diagnostic_status = 'unassigned'
    end
    render json: { diagnosticStatus: diagnostic_status }
  end

  def diagnostic_results_summary
    render json: fetch_diagnostic_results_summary_cache
  end

  def diagnostic_growth_results_summary
    pre_test = Activity.find_by(follow_up_activity_id: results_summary_params[:activity_id])
    render json: GrowthResultsSummary.growth_results_summary(pre_test.id, results_summary_params[:activity_id], results_summary_params[:classroom_id])
  end

  private def fetch_diagnostic_results_summary_cache
    groups = { activity_id: params[:activity_id] }
    current_user.classroom_unit_by_ids_cache(
      classroom_id: params[:classroom_id],
      unit_id: params[:unit_id],
      activity_id: params[:activity_id],
      key: 'teachers.progress_reports.diagnostic_reports.diagnostic_results_summary',
      groups: groups
    ) do
      ResultsSummary.results_summary(results_summary_params[:activity_id], results_summary_params[:classroom_id], results_summary_params[:unit_id])
    end
  end

  private def authorize_teacher!
    classroom_teacher!(params[:classroom_id])
  end

  private def results_summary_params
    params.permit(:classroom_id, :activity_id, :unit_id)
  end

  private def individual_student_diagnostic_responses_params
    params.permit(:student_id, :classroom_id, :activity_id, :unit_id)
  end

  private def find_activity_session_for_student_activity_and_classroom(student_id, activity_id, classroom_id, unit_id)
    if unit_id
      classroom_unit = ClassroomUnit.find_by(unit_id: unit_id, classroom_id: classroom_id)
      activity_session = ActivitySession.find_by(classroom_unit: classroom_unit, state: 'finished', user_id: student_id)
    else
      classroom_units = ClassroomUnit.where(classroom_id: classroom_id).joins(:unit, :unit_activities).where(unit: { unit_activities: { activity_id: activity_id } })
      activity_session = ActivitySession.where(activity_id: activity_id, classroom_unit_id: classroom_units.ids, state: 'finished', user_id: student_id).order(completed_at: :desc).first
    end
  end

  private def set_banner_variables
    acknowledge_lessons_banner_milestone = Milestone.find_by_name(Milestone::TYPES[:acknowledge_lessons_banner])
    @show_lessons_banner = !UserMilestone.find_by(milestone_id: acknowledge_lessons_banner_milestone&.id, user_id: current_user&.id) && current_user&.classroom_unit_activity_states&.where(completed: true)&.none?
  end

  private def set_lesson_diagnostic_recommendations_start_time
    $redis.set("user_id:#{current_user.id}_lesson_diagnostic_recommendations_start_time", Time.current)
  end
end
