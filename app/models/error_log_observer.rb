# observe model related events
class ErrorLogObserver < ActiveRecord::Observer
  def after_create(error_log)
    if error_log.severity > 0
      receivers = EMAIL_SETTINGS[:receivers] || 'liwliu@bbg.gov'
      begin
      #  UserMailer.
      #     alert(receivers, error_log.subject, error_log.message).
      #     deliver_now
        error_log.email_sent = false
        error_log.save
      rescue
      end
    end
  end
end

