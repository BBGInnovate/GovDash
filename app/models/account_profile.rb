class AccountProfile < ActiveRecord::Base
  belongs_to :account

  def to_label
    'Account Profile'
  end
  
end