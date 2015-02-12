class AccountsLanguage < ActiveRecord::Base
  belongs_to :account
  belongs_to :region
  
  def to_label
    'Accounts Language'
  end
  
  def self.populate
    AccountsLanguage.truncate
    AccountsLanguage.for_facebook
    AccountsLanguage.for_twitter
  end
  # updated July 17 10:56am
  # updated July 16 11:10am
  def self.for_facebook
=begin
    a=Account.find_by_object_name 'Sawa'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: '').id
    a=Account.find_by_object_name 'alhurra'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: '').id
=end
    a=FacebookAccount.find_by_object_name 'voaindonesia'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Indonesian').id
     
    a=FacebookAccount.find_by_object_name 'parazitparazit'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Persian').id
    
    a=FacebookAccount.find_by_object_name 'voalearningenglish'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'English').id
    
    a=FacebookAccount.find_by_object_name 'voakhmer'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Khmer').id
    
    a=FacebookAccount.find_by_object_name 'voiceofamerica'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'English').id
    
    a=FacebookAccount.find_by_object_name 'VoA.Burmese.News'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Burmese').id
    
    a=FacebookAccount.find_by_object_name 'voaurdu'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Urdu').id
    
    a=Account.find_by_object_name 'voapersian'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Persian').id
    
    a=FacebookAccount.find_by_object_name 'VOATiengViet'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Vietnamese').id
    
    a=FacebookAccount.find_by_object_name 'DuniaKita'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Indonesian').id
    
    a=FacebookAccount.find_by_object_name 'voapashto'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Pashto').id
    
    a=FacebookAccount.find_by_object_name 'voahausa'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Hausa').id
    
    a=FacebookAccount.find_by_object_name 'KarwanTV'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Pashto').id
    
    a=FacebookAccount.find_by_object_name 'VOAStraightTalkAfrica'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'English').id
    
    a=FacebookAccount.find_by_object_name 'OnTenOnTen'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Persian').id
    
    a=FacebookAccount.find_by_object_name 'voadari'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Dari').id
    
    a=FacebookAccount.find_by_object_name 'voaamharic'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Amharic').id
    
    a=FacebookAccount.find_by_object_name 'voastudentu'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'English').id
    
    a=FacebookAccount.find_by_object_name 'zeriamerikes'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Albanian').id
    
#    a=FacebookAccount.find_by_object_name 'oddidevelopers'
#    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'English').id
 
  end
  
  def self.for_twitter
  # start Twitter
    a=TwitterAccount.find_by_object_name 'GolosAmeriki'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Russian').id
    
    a=TwitterAccount.find_by_object_name 'VOA_News'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'English').id
    
    a=TwitterAccount.find_by_object_name 'VOAIran'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Persian').id
    
    a=TwitterAccount.find_by_object_name 'VOALearnEnglish'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'English').id
    
    a=TwitterAccount.find_by_object_name 'voaindonesia'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Indonesian').id
    
    a=TwitterAccount.find_by_object_name 'chastime'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Ukrainian').id
    
    a=TwitterAccount.find_by_object_name 'voachina'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Mandarin').id
    
    a=TwitterAccount.find_by_object_name 'VOANoticias'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Spanish').id
    
    a=TwitterAccount.find_by_object_name 'voahausa' 
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Hausa').id
    
    a=TwitterAccount.find_by_object_name 'voakhmer'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Khmer').id
    
    a=TwitterAccount.find_by_object_name 'URDUVOA'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Urdu').id
    
    a=TwitterAccount.find_by_object_name 'VOATurkish'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Turkish').id
    
    a=TwitterAccount.find_by_object_name 'VOA_Somali'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Somali').id
    
    a=TwitterAccount.find_by_object_name 'zeriamerikes'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Albanian').id
    
    a=TwitterAccount.find_by_object_name 'Voaburmese'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Burmese').id
    
    a=TwitterAccount.find_by_object_name 'VOAAmharic'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Amharic').id
    
    a=TwitterAccount.find_by_object_name 'VOAPashto'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Pashto').id
    
    a=TwitterAccount.find_by_object_name 'voadeewa'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Deewa').id
    
    a=TwitterAccount.find_by_object_name 'VOADariAfghan'
    AccountsLanguage.find_or_create_by account_id: a.id, language_id: Language.find_by(name: 'Dari').id
    
  end
  
end
