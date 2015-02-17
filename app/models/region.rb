class Region < ActiveRecord::Base
  has_and_belongs_to_many :accounts
  
  def self.populate
    # place holder
  end
  
end
