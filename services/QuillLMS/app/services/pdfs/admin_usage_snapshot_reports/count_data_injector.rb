# frozen_string_literal: true

module Pdfs
  module AdminUsageSnapshotReports
    class CountDataInjector < ApplicationService
      WORKER = Snapshots::CacheSnapshotCountWorker

      attr_reader :admin_report_filter_selection, :item

      def initialize(admin_report_filter_selection:, item:)
        @admin_report_filter_selection = admin_report_filter_selection
        @item = item
      end

      def run
        return item unless valid_query_key?

        item.merge(count:, change:)
      end

      private def change
        return nil if count.nil? || previous.nil? || previous.zero?

        (((count - previous).to_f / previous) * 100).round
      end

      private def count = current_results[:count]&.round
      private def previous = previous_results[:count]&.round

      private def current_results
        @current_results ||= ResultsFetcher.run(admin_report_filter_selection:, query_key:, worker: WORKER)
      end

      private def previous_results
        @previous_results ||=
          ResultsFetcher.run(admin_report_filter_selection:, query_key:, worker: WORKER, previous_timeframe: true)
      end

      private def query_key = item[:queryKey]
      private def valid_query_key? = Snapshots::COUNT_QUERY_MAPPING.key?(query_key)
    end
  end
end
