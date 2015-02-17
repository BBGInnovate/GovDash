class RegionsCountry < ActiveRecord::Base
  belongs_to :region
  belongs_to :country
  
  def to_label
    'Regions Countries'
  end
  
  def self.populate
    # place holder
  end
  
end
