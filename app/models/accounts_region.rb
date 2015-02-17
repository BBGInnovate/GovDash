class AccountsRegion < ActiveRecord::Base
  belongs_to :account
  belongs_to :region
  
  def to_label
    'Accounts Regions'
  end
  
end
