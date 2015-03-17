class Language < ActiveRecord::Base
   
  def self.common_names
    if !@common_names
      commons = LanguageList::COMMON_LANGUAGES
      cnames = commons.map{|a| a.name}
      anames = Language.all.map{| lang | lang.name}
      @common_names = cnames | anames
    end
    @common_names
  end
  
  def self.populate
    arr = %w{
    Albanian
Amharic
Arabic
Azeri/Azerbaijani
Burmese
Cantonese
Dari
Deewa
Dengi
English
French
Georgian
Hausa
Indonesian
Khmer
Kiswahili
Korean
Kurdi
Kurdish
Lao
Mandarin
Ndbele
Pashto
Persian
Russian
Shona
Somali
Spanish
Tibetan
Turkish
Ukrainian
Urdu
Uyghur
Vietnamese}
    self.truncate
    arr.each do |name|
      self.create :name=>name
    end
    
  end

end


