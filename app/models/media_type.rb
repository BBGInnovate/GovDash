class MediaType < ActiveRecord::Base
  
  def self.populate
    self.truncate
    arr = ["FacebookAccount","TwitterAccount"] 
    arr.each do |r|
      self.create :name => r
    end
  end
  
end
