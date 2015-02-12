class Language < ActiveRecord::Base
   
  def self.common_names
    if !@common_names
      commons = LanguageList::COMMON_LANGUAGES
      cnames = commons.map{|a| a.name}
      anames = Account.all.map{| a | a.language.name}
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
  
  
  def self.Apopulate
    self.truncate
    commons = LanguageList::ALL_LANGUAGES  
    self.create :name=>'Khmer', :iso_639_1=>'kh'
    commons.each do |c|
      self.create :name=>c.name, :iso_639_1=>c.iso_639_1
    end
    self.create :name=>'Deewa'
    
    a = self.find_by_name "Afghan Sign Language"
    a.update_attribute :name, "Pashto"
     
  end

end
=begin
 def self.populate
    @feeds = []
    url = "http://en.wikipedia.org/wiki/List_of_languages_by_number_of_native_speakers"
    doc = Nokogiri::HTML(open(url))
    if doc
      doc.css("table tr td b a[href]").each do |a|
        puts a.text
      end
    end
  end
=end


