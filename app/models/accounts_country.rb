class AccountsCountry < ActiveRecord::Base
  belongs_to :account
  belongs_to :country
  
  def to_label
    'Accounts Countries'
  end
  
end
