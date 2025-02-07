# frozen_string_literal: true

module Snapshots
  class CachePremiumReportsWorker
    include Sidekiq::Worker

    PUSHER_EVENT = 'data-export-cached'

    QUERIES = ::Snapshots::PREMIUM_REPORTS_QUERY_MAPPING

    def perform(cache_key, query, user_id, timeframe, school_ids, filters, previous_timeframe)
      user = User.find(user_id)
      payload = generate_payload(query, timeframe, school_ids, user, filters)
      Rails.cache.write(cache_key, payload.to_a, expires_in: cache_expiry)

      filter_hash = PayloadHasher.run([
        query,
        timeframe['name'],
        timeframe['custom_start'],
        timeframe['custom_end'],
        school_ids,
        filters['grades'],
        filters['teacher_ids'],
        filters['classroom_ids']
      ].flatten)

      SendPusherMessageWorker.perform_async(user_id, PUSHER_EVENT, filter_hash)
    end

    private def cache_expiry
      # We need to pass a number of seconds to Redis as a TTL value, and we
      # want to expire our caches overnight so that each day reports can be
      # updated, so we want the number of seconds until end of day
      now = DateTime.current
      now.end_of_day.to_i - now.to_i
    end

    private def generate_payload(query, timeframe, school_ids, user, filters)
      filters_symbolized = filters.symbolize_keys

      QUERIES[query].run(**{
        timeframe_start: DateTime.parse(timeframe['timeframe_start']),
        timeframe_end: DateTime.parse(timeframe['timeframe_end']),
        school_ids: school_ids,
        user:
      }.merge(filters_symbolized))
    end
  end
end
