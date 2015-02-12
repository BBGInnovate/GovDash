class Region < ActiveRecord::Base
  has_and_belongs_to_many :accounts
  
  def self.populate
=begin
    region = Region.find_by(name: 'Balkans')
    if region
      return
    else
      Region.truncate
      load "#{Rails.root}/db/seeds.rb"
    end
=end
    Region.truncate
    arr = ["All", "Central America Caribbean", "South America", "West Africa", "Balkans", "Caucasus", "Central Africa", "East and Southern Africa",
     "East Asia", "Eastern Europe", "Gulf States", "Levant", "North Africa", "Russian Federation", "South and West Asia", "Southeast Asia"] 
    arr.each do |r|
      Region.create :name => r, :is_active => 1
    end

  end
  
end
