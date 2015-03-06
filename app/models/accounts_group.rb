class AccountsGroup < ActiveRecord::Base
  belongs_to :account
  belongs_to :group
  
  def to_label
    'Accounts Groups'
  end
end
