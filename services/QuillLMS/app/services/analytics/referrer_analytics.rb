# frozen_string_literal: true

module Analytics
  class ReferrerAnalytics
    attr_accessor :analytics

    def initialize
      self.analytics = SegmentAnalytics.new
    end

    def track_referral_invited(referrer, referral_id)
      analytics.identify(referrer)
      analytics.track(
        event: Analytics::SegmentIo::BackgroundEvents::REFERRAL_INVITED,
        properties: { referral_id: referral_id },
        user_id: referrer.id
      )
    end

    def track_referral_activated(referrer, referral_id)
      analytics.identify(referrer)
      analytics.track(
        event: Analytics::SegmentIo::BackgroundEvents::REFERRAL_ACTIVATED,
        properties: { referral_id: referral_id },
        user_id: referrer.id
      )
    end
  end
end
