class UserMailer < ActionMailer::Base
  default :from => "oddidev@bbg.gov"  
  
  def alarm_email(email, message)
      @message = message
      mail(to: email, subject: @message)
  end

  def alert(email, subject, message)
      @message = message
      mail(to: email, subject: subject)
  end
  
  protected

end
