class ErrorLog < ActiveRecord::Base
  # severity 0 - 10
  # 10 most sever
  def self.to_error subject="", message="", severity=5
     obj = ErrorLog.create :subject=>subject,
       :message=>message, :severity=>severity
     obj
  end
  
end
