class Network < ActiveRecord::Base
  validates :name, length: { in: 2..40 }
  
  def self.populate
    self.truncate
    arr = ["MBN","OCB","RFA", "RFERL", "VOA"] 
    arr.each do |r|
      self.create :name => r
    end
  end
  
  def self.filter_attr(attributes)
  
  end
  
end

