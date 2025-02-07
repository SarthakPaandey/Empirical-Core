# frozen_string_literal: true

namespace :backfill do
  # rake 'backfill:updated_at[ClassroomUnit "2020-01-01"]'
  desc 'backfills updated_at so null values do not exist'
  task :updated_at, [:klass, :fill_datetime] => :environment do |t, args|
    klass = args[:klass].constantize
    fallback_fill_datetime = DateTime.new(2018, 4, 1)

    fill_datetime = args[:fill_datetime] ? DateTime.parse(args[:fill_datetime]) : fallback_fill_datetime

    klass.unscoped.where(updated_at: nil).find_each do |record|
      backfill_value = record.created_at || fill_datetime
      puts "updating #{klass} with id #{record.id}, created_at: #{record.created_at}, to updated_at value #{backfill_value}"

      record.update_columns(
        updated_at: backfill_value
      )
    end
  end
end
