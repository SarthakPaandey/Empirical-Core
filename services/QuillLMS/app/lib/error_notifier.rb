# frozen_string_literal: true

module ErrorNotifier
  # pass an exception
  def self.report(error, options = {})
    Sentry.capture_exception(error, extra: options)
    NewRelic::Agent.notice_error(error, options)
  end
end
