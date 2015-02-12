class Service < ActiveRecord::Base
  validates :name, length: { in: 2..40 }
#  validates_numericality_of :network_id, :on => :create
  
  belongs_to :network
  has_many :accounts

  def self.populate
    self.truncate
    aa = self.seeds
    aa.each do |a|
      arr = a.split(',')
      arr[0].gsub!('-', ' ')
      name = "#{arr[0]}"
      puts "NAME #{name}"
      nid=Network.find_by_name(arr[1]).id
      self.create :name=>name, :network_id=>nid
    end
  end
  
  def self.find_me(name, network_name)
    nid = Network.find_by_name(network_name).id
    where("name='#{name}' AND network_id=#{nid}").first
  end
  
  
  def self.seeds
    ["AlHurra TV,MBN", "Radio Sawa,MBN", "Radio-Marti,OCB", "TV-Marti,OCB", "Khmer,RFA", "English,RFA", 
    "Burmese,RFA", "Vietnamese,RFA", "Cantonese,RFA", "Laos,RFA", "Mandarin,RFA", "Tibetan,RFA", 
    "Uyghur,RFA", "Korean,RFA", "English,RFERL", "Ukrainian,RFERL", "Russian,RFERL", "Persian,RFERL",
    "Dari,RFERL", "Russian,VOA", "English,VOA", "PNN,VOA", "Learning-English,VOA", "Indonesian,VOA",
    "Ukrainian,VOA", "Mandarin,VOA", "Spanish,VOA", "Hausa,VOA", "Khmer,VOA", "Urdu,VOA", "Turkish,VOA",
    "Somali,VOA", "Albanian,VOA", "Burmese,VOA", "Amharic,VOA", "Pashto,VOA", "Deewa,VOA", "Dengi,VOA",
    "Afghan,VOA", "French,VOA", "Kiswahili,VOA", "English-to-Africa,VOA",
    "Vietnamese,VOA", "Uzbek,VOA", "Uzbek,RFERL", "Belarus,RFERL", "Iraqi,RFERL", "Balkans,RFERL", 
    "Kazakh,RFERL"]
  end
  
  
=begin
  
  
=end

  # copy paste arr = to rails console
  # copy results to self.seeds
  # 
  def self.raw_seeds
   arr = %w{
Al-Hurra,MBN
Sawa,	MBN
Radio-Marti,	OCB
TV-Marti,	OCB
Khmer,	RFA
English,	RFA
Burmese,	RFA
Vietnamese,	RFA
Cantonese	,RFA
Laos,	RFA
Mandarin,	RFA
Tibetan,	RFA
Uyghur	,RFA
Korean	,RFA
English,	RFERL
Ukrainian	,RFERL
Russian,	RFERL
Persian,	RFERL
Dari,	RFERL
Russian,	VOA
English,	VOA
PNN	,VOA
Learning-English,	VOA
Indonesian,	VOA
Ukrainian,	VOA
Mandarin,	VOA
Spanish,	VOA
Hausa,	VOA
Khmer,	VOA
Urdu,	VOA
Turkish,	VOA
Somali,	VOA
Albanian,	VOA
Burmese,VOA
Amharic,	VOA
Pashto	,VOA
Deewa,	VOA
Dengi,	VOA
Afghan,	VOA
French,	VOA
Kiswahili,	VOA
English-to-Africa,	VOA
Uzbek, VOA
Uzbek, RFERL
Belarus, RFERL
Iraqi, RFERL
Balkans, RFERL}
  end
end
