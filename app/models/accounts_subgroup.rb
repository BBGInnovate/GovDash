class AccountsSubgroup < ActiveRecord::Base
  belongs_to :account
  belongs_to :subgroup
  
  def to_label
    'Accounts Subgroups'
  end

  def self.insert account_id, subgroup_id
    if !!account_id && !!subgroup_id
      self.find_or_create_by account_id: account_id, 
                  subgroup_id: subgroup_id
    end
  end
end
