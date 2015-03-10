class AccountsGroup < ActiveRecord::Base
  belongs_to :account
  belongs_to :group
  
  def to_label
    'Accounts Groups'
  end
  
  def self.insert account_id, group_id
    if !!account_id && !!group_id
      self.find_or_create_by account_id: account_id, 
                group_id: group_id
    end
  end
  
end
