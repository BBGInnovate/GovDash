class UserMailer < ActionMailer::Base
  default :from => "oddidev@bbg.gov"  
  
  # UserMailer.alarm_email('liwliu@bbg.gov', message).deliver worked
  def alarm_email(email, message)
      @message = message
      mail(to: email, subject: @message)
  end

=begin
  account = "voiceofamerica"
  exp = "5 hours"
  subject = "Facebook account #{account} access_token expiry in #{exp}"
  message = "Facebook access_token expiry in #{exp}"
  UserMailer.alert('liwliu@bbg.gov',subject, message).deliver worked
=end
  def alert(email, subject, message)
      @message = message
      mail(to: email, subject: subject)
  end
  
  protected

end
