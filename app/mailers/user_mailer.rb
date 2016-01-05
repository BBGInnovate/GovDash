class UserMailer < ActionMailer::Base
  default :from => "oddidev@bbg.gov"
  before_action :set_headers

  # UserMailer.alarm_email(['liw@bbg.gov'], 'Testing AWS Email Service').deliver_now!
  # for data not inserted for a period
  def alarm_email(email, message)
      @message = message
      mail(to: email, subject: @message)
  end
  # this is for data missing for certain date
  def alert(email, subject, message)
      @message = message
      mail(to: email, subject: subject)
  end
  
  def confirm_email(user)
    @user = user
    mail(to: @user.email, subject: "BBG Social Media Dashboard Registration Confirmation")
  end

  def forget_password_email(user, pass)
    @user = user
    @pass = pass
    mail(to: @user.email, subject: "BBG Social Media Dashboard Password Reset")
  end
  protected
  def set_headers
    headers["return-path"] = "oddidev@bbg.gov"
  end
end
