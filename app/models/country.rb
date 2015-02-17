class Country < ActiveRecord::Base

  has_and_belongs_to_many :accounts

  def self.populate
    url = "https://raw.github.com/umpirsky/country-list/master/country/cldr/en/country.xml"
    doc = Nokogiri::XML(open(url))
    if doc
      self.truncate
      self.create :code=> 'All', :name=>'All'
      @links = doc.xpath('//countries/country').each do |i|
        name = i.xpath('name').text
        self.create :code=> i.xpath('iso').text, :name=>name
      end
    end
  end
  
end