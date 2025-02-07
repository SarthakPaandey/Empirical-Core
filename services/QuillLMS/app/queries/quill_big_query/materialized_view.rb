# frozen_string_literal: true

module QuillBigQuery
  class MaterializedView
    attr_reader :view_key

    QUERY_FOLDER = Rails.root.join('db/big_query/views/')
    CONFIG = Configs[:big_query_views]

    class InvalidQueryKeyError < StandardError; end

    def initialize(view_key)
      @view_key = view_key

      raise InvalidQueryKeyError unless view_key.in?(CONFIG.keys)
    end

    def refresh!
      drop!
      create!
    end

    def drop! = run_query(drop_sql)
    def create! = run_query(create_sql)

    private def run_query(sql) = QuillBigQuery::WritePermissionsRunner.run(sql)

    # Adding a COUNT query after the creation for 2 reasons: since the
    # 1) BigQuery library errors when returning the contents
    # of a Materialized View, i.e. it runs the 'CREATE' operation successfully,
    # but the API errors when parsing the Materialized View details to return:
    # "Google::Apis::ClientError: invalid: Cannot list a table of type MATERIALIZED_VIEW."
    # 2) It seems the view isn't primed until it is queried, so querying it
    def create_sql
      <<-SQL.squish
        CREATE MATERIALIZED VIEW #{name_with_dataset} #{create_options} AS (#{sql.squish});
        SELECT COUNT(*) FROM #{name_with_dataset};
      SQL
    end

    def sql = File.read(QUERY_FOLDER + config[:sql])
    def drop_sql = "DROP MATERIALIZED VIEW IF EXISTS #{name_with_dataset}"
    def fallback_with_clause = "#{name_fallback} AS (#{sql.squish})"

    def name = config[:name]
    def name_with_dataset = "#{dataset}.#{name}"
    def name_fallback = config[:name_fallback]

    private def config = @config ||= CONFIG[view_key]
    private def dataset = config[:dataset]
    private def create_options = config[:create_options]
  end
end
