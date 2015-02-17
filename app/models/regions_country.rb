class RegionsCountry < ActiveRecord::Base
  belongs_to :region
  belongs_to :country
  
  def to_label
    'Regions Countries'
  end
  
  def self.populate
    truncate
    r = Region.find_by_name 'Caucasus'
    names = ['Armenia','Azerbaijan','Georgia','Turkey']
    country_ids = Country.where(["name in (?)", names]).map{|c| c.id}
    country_ids.each do |c_id|
      create :region_id=>r.id, :country_id=> c_id
    end
    
    r = Region.find_by_name 'Central Africa'
    names = ['Burundi','Cameroon','Central African Republic','Chad','Congo - Kinshasa','Equatorial Guinea','Gabon','Congo - Brazzaville','Rwanda']
    country_ids = Country.where(["name in (?)", names]).map{|c| c.id}
    country_ids.each do |c_id|
      create :region_id=>r.id, :country_id=> c_id
    end
    
    r = Region.find_by_name 'Central America and the Caribbean'
    names = ['Costa Rica','Cuba','Dominican Republic','El Salvador','Guatemala','Haiti','Honduras','Mexico','Nicaragua','Panama']
    country_ids = Country.where(["name in (?)", names]).map{|c| c.id}
    country_ids.each do |c_id|
      create :region_id=>r.id, :country_id=> c_id
    end
    
    r = Region.find_by_name 'Central Asia'
    names = ['Kazakhstan','Kyrgyzstan','Tajikistan','Turkmenistan','Uzbekistan']
    country_ids = Country.where(["name in (?)", names]).map{|c| c.id}
    country_ids.each do |c_id|
      create :region_id=>r.id, :country_id=> c_id
    end
    
    r = Region.find_by_name 'East Asia'
    Country.find_or_create_by :name=>"China-Cantonese region"
    Country.find_or_create_by :name=>"China-Tibet"
    Country.find_or_create_by :name=>"China-Uyghur region"
    
    names = ['China','China-Cantonese region','China-Tibet','China-Uyghur region','Mongolia','North Korea','Taiwan']
    country_ids = Country.where(["name in (?)", names]).map{|c| c.id}
    country_ids.each do |c_id|
      create :region_id=>r.id, :country_id=> c_id
    end
     
    r = Region.find_by_name 'East and Southern Africa'
    names = ['Angola','Botswana','Comoros','Djibouti','Eritrea','Ethiopia','Kenya','Lesotho','Madagascar','Malawi','Mauritius','Mozambique','Namibia','Seychelles','Somalia','South Africa','South Sudan','Swaziland','Tanzania','Uganda','Zambia','Zimbabwe']
    country_ids = Country.where(["name in (?)", names]).map{|c| c.id}
    country_ids.each do |c_id|
      create :region_id=>r.id, :country_id=> c_id
    end
    
    r = Region.find_by_name 'Eastern Europe'
    names = ['Belarus','Moldova','Ukraine']
    country_ids = Country.where(["name in (?)", names]).map{|c| c.id}
    country_ids.each do |c_id|
      create :region_id=>r.id, :country_id=> c_id
    end
    
    r = Region.find_by_name 'Gulf States'
    names = ['Bahrain','Kuwait','Oman','Qatar','Saudi Arabia','United Arab Emirates','Yemen']
    country_ids = Country.where(["name in (?)", names]).map{|c| c.id}
    country_ids.each do |c_id|
      create :region_id=>r.id, :country_id=> c_id
    end
    
    r = Region.find_by_name 'Levant'
    names = ['Iraq','Jordan','Lebanon','Palestinian Territories','Syria']
    country_ids = Country.where(["name in (?)", names]).map{|c| c.id}
    country_ids.each do |c_id|
      create :region_id=>r.id, :country_id=> c_id
    end
    
    r = Region.find_by_name 'North Africa'
    names = ['Algeria','Egypt','Libya','Morocco','Sudan','Tunisia']
    country_ids = Country.where(["name in (?)", names]).map{|c| c.id}
    country_ids.each do |c_id|
      create :region_id=>r.id, :country_id=> c_id
    end
    
    r = Region.find_by_name 'Russia'
    Country.find_or_create_by :name=>"Russia-Tartarstan and Bashkortostan"
    Country.find_or_create_by :name=>"Russia-North Caucasus"
    
    names = ['Russia','Russia-North Caucasus','Russia-Tartarstan and Bashkortostan']
    country_ids = Country.where(["name in (?)", names]).map{|c| c.id}
    country_ids.each do |c_id|
      create :region_id=>r.id, :country_id=> c_id
    end
    
    r = Region.find_by_name 'South America'
    names = ['Argentina','Bolivia','Chile','Colombia','Ecuador','Paraguay','Peru','Uruguay','Venezuela']
    country_ids = Country.where(["name in (?)", names]).map{|c| c.id}
    country_ids.each do |c_id|
      create :region_id=>r.id, :country_id=> c_id
    end
    
    r = Region.find_by_name 'South and West Asia'
    Country.find_or_create_by :name=>"Pakistan (FATA)"
    names = ['Afghanistan','Bangladesh','Iran','Pakistan','Pakistan (FATA)','Sri Lanka']
    country_ids = Country.where(["name in (?)", names]).map{|c| c.id}
    country_ids.each do |c_id|
      create :region_id=>r.id, :country_id=> c_id
    end
     
    r = Region.find_by_name 'Southeast Asia'
    names = ['Myanmar [Burma]','Cambodia','Indonesia','Laos','Philippines','Thailand','Vietnam']
    country_ids = Country.where(["name in (?)", names]).map{|c| c.id}
    country_ids.each do |c_id|
      create :region_id=>r.id, :country_id=> c_id
    end
    
    r = Region.find_by_name 'West Africa'
    names = ['Benin','Burkina Faso','Cape Verde',"Côte d’Ivoire",'Ghana','Guinea','Guinea-Bissau','Liberia','Mali','Mauritania','Niger','Nigeria','Sao Tome and Principe','Senegal','Sierra Leone','Gambia','Togo']
    country_ids = Country.where(["name in (?)", names]).map{|c| c.id}
    country_ids.each do |c_id|
      create :region_id=>r.id, :country_id=> c_id
    end
    
  end
  
end
