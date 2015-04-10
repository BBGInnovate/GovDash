class Region < ActiveRecord::Base
  has_and_belongs_to_many :accounts
  has_and_belongs_to_many :countries, :join_table => :regions_countries
  has_and_belongs_to_many :subgroups, :join_table => :subgroups_regions

  
  def self.populate
    # place holder
  end
  
end
