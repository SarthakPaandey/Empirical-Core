# frozen_string_literal: true

class SnapshotsController < ApplicationController
  ADMIN_DIAGNOSTIC_REPORT = '/diagnostic_growth_report'
  CACHE_REPORT_NAME = 'admin-snapshot'
  GRADE_OPTIONS = [
    { value: 'Kindergarten', name: 'Kindergarten' },
    { value: '1', name: '1st' },
    { value: '2', name: '2nd' },
    { value: '3', name: '3rd' },
    { value: '4', name: '4th' },
    { value: '5', name: '5th' },
    { value: '6', name: '6th' },
    { value: '7', name: '7th' },
    { value: '8', name: '8th' },
    { value: '9', name: '9th' },
    { value: '10', name: '10th' },
    { value: '11', name: '11th' },
    { value: '12', name: '12th' },
    { value: 'University', name: 'University' },
    { value: 'Other', name: 'Other' },
    { value: 'null', name: 'No grade set' }
  ]

  WORKERS_FOR_ACTIONS = {
    'count' => Snapshots::CacheSnapshotCountWorker,
    'top_x' => Snapshots::CacheSnapshotTopXWorker,
    'data_export' => Snapshots::CachePremiumReportsWorker,
    'create_csv_report_download' => Snapshots::PremiumDownloadReportsWorker
  }

  before_action :set_query, only: [:count, :top_x, :data_export, :create_csv_report_download]
  before_action :validate_request, only: [:count, :top_x, :data_export, :create_csv_report_download]
  before_action :authorize_request, only: [:count, :top_x, :data_export, :create_csv_report_download]

  def count
    render json: retrieve_cache_or_enqueue_worker(WORKERS_FOR_ACTIONS[action_name])
  end

  def top_x
    render json: retrieve_cache_or_enqueue_worker(WORKERS_FOR_ACTIONS[action_name])
  end

  def create_csv_report_download
    timeframe_start, timeframe_end = Snapshots::Timeframes.calculate_timeframes(snapshot_params[:timeframe],
      custom_start: snapshot_params[:timeframe_custom_start],
      custom_end: snapshot_params[:timeframe_custom_end],
      previous_timeframe: snapshot_params[:previous_timeframe])

    worker_params = [
      @query,
      current_user.id,
      {
        name: snapshot_params[:timeframe],
        timeframe_start: timeframe_start,
        timeframe_end: timeframe_end
      },
      snapshot_params[:school_ids],
      snapshot_params[:headers_to_display],
      {
        grades: snapshot_params[:grades],
        teacher_ids: snapshot_params[:teacher_ids],
        classroom_ids: snapshot_params[:classroom_ids]
      }

    ]
    WORKERS_FOR_ACTIONS[action_name].perform_async(*worker_params)

    render json: { message: 'Generating report' }
  end

  def data_export
    render json: retrieve_cache_or_enqueue_worker(WORKERS_FOR_ACTIONS[action_name])
  end

  def options
    render json: build_options_hash
  end

  private def build_options_hash
    {
      timeframes:,
      schools: format_option_list(school_options),
      grades: GRADE_OPTIONS,
      teachers: format_option_list(sorted_teacher_options),
      classrooms: format_option_list(classroom_options)
    }.merge(initial_load_options)
  end

  private def timeframes
    return admin_diagnostic_growth_report_timeframes if report == ADMIN_DIAGNOSTIC_REPORT

    all_timeframes
  end

  private def all_timeframes = Snapshots::Timeframes.frontend_options

  private def admin_diagnostic_growth_report_timeframes
    Snapshots::Timeframes.frontend_options.filter do |timeframe|
      ['this-school-year', 'last-school-year'].include?(timeframe[:value])
    end
  end

  private def initial_load_options
    return {} unless initial_load?

    {
      all_classrooms: format_option_list(all_classroom_options),
      all_teachers: format_option_list(all_sorted_teacher_options),
      all_schools: format_option_list(school_options)
    }
  end

  private def format_option_list(models)
    models.pluck(:id, :name).map { |id, name| { id: id, name: name } }
  end

  private def school_options
    current_user.administered_premium_schools
  end

  private def filtered_schools
    school_ids = option_params[:school_ids]

    return school_options.where(id: school_ids) if school_ids.present?

    school_options
  end

  private def teacher_options
    grades = option_params[:grades]&.map { |i| Utils::String.parse_null_to_nil(i) }

    teachers = User.teachers_in_schools(filtered_schools.pluck(:id))
      .where(classrooms_teachers: { role: [nil, ClassroomsTeacher::ROLE_TYPES[:owner]] })

    return teachers.where(classrooms: { grade: grades }) if grades.present?

    teachers
  end

  private def all_sorted_teacher_options
    User
      .teachers_in_schools(school_options.pluck(:id))
      .where(classrooms_teachers: { role: [nil, ClassroomsTeacher::ROLE_TYPES[:owner]] })
      .sort_by(&:last_name)
  end

  private def all_classroom_options
    Classroom.unscoped
      .distinct
      .joins(:classrooms_teachers)
      .where(classrooms_teachers: { user_id: all_sorted_teacher_options.pluck(:id) })
      .order(:name)
  end

  private def sorted_teacher_options
    # We sort these in Ruby because we want to sort by last name which is a value derived from the database rather than stored in it
    teacher_options.sort_by(&:last_name)
  end

  private def filtered_teachers
    teacher_ids = option_params[:teacher_ids]

    return teacher_options.where(id: teacher_ids) if teacher_ids.present?

    teacher_options
  end

  private def classroom_options
    Classroom.unscoped
      .distinct
      .joins(:classrooms_teachers)
      .where(classrooms_teachers: { user_id: filtered_teachers.pluck(:id) })
      .order(:name)
  end

  private def set_query
    @query = snapshot_params[:query]
  end

  private def validate_request
    return render json: { error: 'timeframe must be present and valid' }, status: 400 unless timeframe_param_valid?

    return render json: { error: 'school_ids are required' }, status: 400 unless school_ids_param_valid?

    return render json: { error: 'unrecognized query type for this endpoint' }, status: 400 unless WORKERS_FOR_ACTIONS[action_name]::QUERIES.keys.include?(@query)
  end

  private def timeframe_param_valid?
    Snapshots::Timeframes.find_timeframe(snapshot_params[:timeframe]).present?
  end

  private def school_ids_param_valid?
    snapshot_params[:school_ids]&.any?
  end

  private def authorize_request
    schools_user_admins = current_user.administered_schools.pluck(:id)

    return if snapshot_params[:school_ids]&.all? { |param_id| schools_user_admins.include?(param_id.to_i) }

    return render json: { error: 'user is not authorized for all specified schools' }, status: 403
  end

  private def retrieve_cache_or_enqueue_worker(worker)
    timeframe_start, timeframe_end = Snapshots::Timeframes.calculate_timeframes(snapshot_params[:timeframe],
      custom_start: snapshot_params[:timeframe_custom_start],
      custom_end: snapshot_params[:timeframe_custom_end],
      previous_timeframe: snapshot_params[:previous_timeframe])

    return { count: nil } unless timeframe_start && timeframe_end

    cache_key = cache_key_for_timeframe(snapshot_params[:timeframe], timeframe_start, timeframe_end)
    response = Rails.cache.read(cache_key)

    return { results: response } if response

    worker.perform_async(cache_key,
      @query,
      current_user.id,
      {
        name: snapshot_params[:timeframe],
        timeframe_start: timeframe_start,
        timeframe_end: timeframe_end,
        custom_start: snapshot_params[:timeframe_custom_start],
        custom_end: snapshot_params[:timeframe_custom_end]
      },
      snapshot_params[:school_ids],
      {
        grades: snapshot_params[:grades],
        teacher_ids: snapshot_params[:teacher_ids],
        classroom_ids: snapshot_params[:classroom_ids]
      },
      snapshot_params[:previous_timeframe])

    { message: 'Generating snapshot' }
  end

  private def cache_key_for_timeframe(timeframe_name, timeframe_start, timeframe_end)
    Snapshots::CacheKeys.generate_key(CACHE_REPORT_NAME,
      @query,
      timeframe_name,
      timeframe_start,
      timeframe_end,
      snapshot_params.fetch(:school_ids, []),
      additional_filters: {
        grades: snapshot_params.fetch(:grades, []),
        teacher_ids: snapshot_params.fetch(:teacher_ids, []),
        classroom_ids: snapshot_params.fetch(:classroom_ids, [])
      })
  end

  private def snapshot_params
    params.permit(:query,
      :timeframe,
      :timeframe_custom_start,
      :timeframe_custom_end,
      :previous_timeframe,
      headers_to_display: [],
      school_ids: [],
      grades: [],
      teacher_ids: [],
      classroom_ids: [])
  end

  private def option_params
    params.permit(
      :is_initial_load,
      :report,
      school_ids: [],
      grades: [],
      teacher_ids: []
    )
  end

  private def report = option_params[:report]

  private def initial_load?
    option_params[:is_initial_load].in?([true, 'true'])
  end
end
