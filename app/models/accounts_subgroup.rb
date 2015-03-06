class AccountsSubgroup < ActiveRecord::Base
  belongs_to :account
  belongs_to :subgroup
  
  def to_label
    'Accounts Subgroups'
  end

end
