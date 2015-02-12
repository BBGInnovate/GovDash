class AccountsUser < ActiveRecord::Base
  belongs_to :account
  belongs_to :user
  
  def to_label
    'Accounts Users'
  end
  
end
