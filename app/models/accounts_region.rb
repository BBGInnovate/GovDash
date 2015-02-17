class AccountsRegion < ActiveRecord::Base
  belongs_to :account
  belongs_to :region
  
  def to_label
    'Accounts Regions'
  end
  
  def self.populate
    AccountsRegion.truncate
    FacebookAccount.create_test_account
    AccountsRegion.for_facebook
    AccountsRegion.for_twitter
  end
  # updated July 17 10:56am
  # updated July 16 11:10am
  def self.for_facebook
    a=FacebookAccount.find_by_object_name 'Sawa'
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'Caucasus').id
     
    a=FacebookAccount.find_by_object_name 'alhurra'
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'Caucasus').id
    
    a=FacebookAccount.find_by_object_name 'voaindonesia'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'Southeast Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Indonesia').id
        
    a=FacebookAccount.find_by_object_name 'parazitparazit'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'South and West Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Iran').id
    
    a=FacebookAccount.find_by_object_name 'voalearningenglish'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  1
    AccountsCountry.find_or_create_by account_id: a.id, country_id: 1
    
    a=FacebookAccount.find_by_object_name 'voakhmer'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'Southeast Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Cambodia').id
    
    a=FacebookAccount.find_by_object_name 'voiceofamerica'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  1
    AccountsCountry.find_or_create_by account_id: a.id, country_id: 1
    
    a=FacebookAccount.find_by_object_name 'VoA.Burmese.News'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'Southeast Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Myanmar [Burma]').id
    
    a=FacebookAccount.find_by_object_name 'voaurdu'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'South and West Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Pakistan').id
    
    a=FacebookAccount.find_by_object_name 'voapersian'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'South and West Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Iran').id
    
    a=FacebookAccount.find_by_object_name 'VOATiengViet'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'Southeast Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Vietnam').id
    
    a=FacebookAccount.find_by_object_name 'DuniaKita'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'Southeast Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Indonesia').id
    
    a=FacebookAccount.find_by_object_name 'voapashto'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'South and West Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Afghanistan').id
    
    a=FacebookAccount.find_by_object_name 'voahausa'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'West Africa').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Nigeria').id
    
    a=FacebookAccount.find_by_object_name 'KarwanTV'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'South and West Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Afghanistan').id
    
    a=FacebookAccount.find_by_object_name 'VOAStraightTalkAfrica'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'East and Southern Africa').id
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'West Africa').id
    # AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: '').id
    
    a=FacebookAccount.find_by_object_name 'OnTenOnTen'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'South and West Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Iran').id
    
    a=FacebookAccount.find_by_object_name 'voadari'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'South and West Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Afghanistan').id
    
    a=FacebookAccount.find_by_object_name 'voaamharic'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'East and Southern Africa').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Ethiopia').id
    
    a=FacebookAccount.find_by_object_name 'voastudentu'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  1
    AccountsCountry.find_or_create_by account_id: a.id, country_id: 1
    
    a=FacebookAccount.find_by_object_name 'zeriamerikes'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'Eastern Europe').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Albania').id
    
#    a=FacebookAccount.find_by_object_name 'oddidevelopers'
#    AccountsRegion.find_or_create_by account_id: a.id, region_id:  1
#    AccountsCountry.find_or_create_by account_id: a.id, country_id: 1
    
  end
  
  def self.for_twitter
  # start Twitter
    a=TwitterAccount.find_by_object_name 'GolosAmeriki'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  Region.find_by(name: 'Russian Federation').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Russia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Ukraine').id
     
    a=TwitterAccount.find_by_object_name 'VOA_News'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  1
    AccountsCountry.find_or_create_by account_id: a.id, country_id: 1
    
    a=TwitterAccount.find_by_object_name 'VOAIran'
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'South and West Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Iran').id
    
    a=TwitterAccount.find_by_object_name 'VOALearnEnglish'
    AccountsRegion.find_or_create_by account_id: a.id, region_id:  1
    AccountsCountry.find_or_create_by account_id: a.id, country_id: 1
    
    
    a=TwitterAccount.find_by_object_name 'voaindonesia'
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'Southeast Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Indonesia').id
    
    a=TwitterAccount.find_by_object_name 'chastime'
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'Russian Federation').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Ukraine').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Russia').id
    
    a=TwitterAccount.find_by_object_name 'voachina'
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'East Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'China').id
    
    a=TwitterAccount.find_by_object_name 'VOANoticias'
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'South America').id
    # 'Central America Caribbean' name exception
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'Central America Caribbean').id
    names = ['Costa Rica', 'Cuba', 'Dominican Republic', 'El Salvador', 'Guatemala', 'Haiti', 'Honduras', 
    'Mexico', 'Nicaragua', 'Panama', 'Argentina', 'Bolivia', 'Chile', 'Colombia', 'Ecuador', 
    'Paraguay', 'Peru', 'Uruguay', 'Venezuela']
    names.each do |name|
       co = Country.find_by name: name
       if co
         AccountsCountry.find_or_create_by account_id: a.id, country_id: co.id
       else
         puts "Country #{name} not found" 
       end
    end
    
    a=TwitterAccount.find_by_object_name 'voahausa' 
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'West Africa').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Nigeria').id
    
    a=TwitterAccount.find_by_object_name 'voakhmer'
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'Southeast Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Cambodia').id
    
    a=TwitterAccount.find_by_object_name 'URDUVOA'
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'South and West Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Pakistan').id
    
    a=TwitterAccount.find_by_object_name 'VOATurkish'
    # Caucasus name exception
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'Caucasus').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Turkey').id
    
    a=TwitterAccount.find_by_object_name 'VOA_Somali'
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'East and Southern Africa').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Somalia').id
    
    a=TwitterAccount.find_by_object_name 'zeriamerikes'
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'Eastern Europe').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Albania').id
    
    a=TwitterAccount.find_by_object_name 'Voaburmese'
    # "Myanmar [Burma]" name exception
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'Southeast Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Myanmar [Burma]').id
   
    a=TwitterAccount.find_by_object_name 'VOAAmharic'
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'East and Southern Africa').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Ethiopia').id

    a=TwitterAccount.find_by_object_name 'VOAPashto'
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'South and West Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Afghanistan').id

    a=TwitterAccount.find_by_object_name 'voadeewa'
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'South and West Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Afghanistan').id

    a=TwitterAccount.find_by_object_name 'VOADariAfghan'
    AccountsRegion.find_or_create_by account_id: a.id, region_id: Region.find_by(name: 'South and West Asia').id
    AccountsCountry.find_or_create_by account_id: a.id, country_id: Country.find_by(name: 'Afghanistan').id
    
  end
  
end
