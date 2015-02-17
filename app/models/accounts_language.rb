class AccountsLanguage < ActiveRecord::Base
  belongs_to :account
  belongs_to :region
  
  def to_label
    'Accounts Language'
  end
  
  def self.populate
    AccountsLanguage.truncate
    AccountsLanguage.for_facebook
    AccountsLanguage.for_twitter
  end

  def self.for_facebook

  end
  
  def self.for_twitter

  end
  
end
