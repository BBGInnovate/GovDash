class Group < ActiveRecord::Base
  belongs_to :organization
  validates :name, length: { in: 2..40 }
  
  
  def self.filter_attr(attributes)
  
  end
  
end

