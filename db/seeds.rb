# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


#populate sc_segments with values from Sitecatalyst API
@client = OmnitureClient.new(
		'oddidev:BBG',
		'6c257ec67510138a37b8149d3b72d3d4',
		:portland,
		:verify_mode=> nil,
		:log => true,
		:wait_time => 1 
	)
report_desc = {
		"reportDescription" => {
			"reportSuiteID" => "bbgprod"
		}
	}
@response = @client.request("Segments.Get", report_desc)
unless @response.nil?
	@response.each do |item|
		ScSegment.find_or_create_by(name: item['name']) do |seg|
			seg.sc_id = item['id']
		end
	end
end


#Add relationship with segments and accounts
=begin
AccountsScSegment.create([ 
	{sc_segment_id: '1', account_id: '1'}, #radio sawa
	{sc_segment_id: '2', account_id: '2'}, #Alhurra TV
	{sc_segment_id: '3', account_id: '2'},
	{sc_segment_id: '4', account_id: '2'},
	{sc_segment_id: '5', account_id: '2'},
])
=end
opt = {:name=>"alyoumshow",
      :account_type_id=>1,
      :network_id=>Network.find_by(name: 'MBN').id,
      :service_id=>Service.find_by(name: 'AlHurra TV').id,
      :language_id=>Language.find_by(name: 'Arabic').id
      }
sawa = FacebookAccount.find_by object_name: 'Sawa'
alhurra = FacebookAccount.find_by object_name: 'alhurra'
alyoumshow = FacebookAccount.find_or_create_by :object_name=>"alyoumshow"
alyoumshow.update_attributes opt
names = ['Gulf States', 'Levant', 'North Africa']
ids = [alyoumshow.id,sawa.id,alhurra.id]
AccountsRegion.delete_all ["account_id in (?)",ids]
Region.where(["name in (?)", names]).each do |re|
  AccountsRegion.find_or_create_by :account_id=>alyoumshow.id,
     :region_id=>re.id
  AccountsRegion.find_or_create_by :account_id=>sawa.id,
     :region_id=>re.id
  AccountsRegion.find_or_create_by :account_id=>alhurra.id,
     :region_id=>re.id
end
names = ['Bahrain', 'Kuwait', 'Oman', 'Qatar', 'Saudi Arabia',
  'United Arab Emirates', 'Yemen', 'Iraq', 'Jordan', 'Lebanon', 
  'Palestinian Territories','Syria', 'Algeria', 'Egypt', 'Libya', 
  'Morocco', 'Sudan','Tunisia']
AccountsCountry.delete_all ["account_id in (?)",ids]
Country.where(["name in (?)", names]).each do |re|
  AccountsCountry.find_or_create_by :account_id=>alyoumshow.id,
     :country_id=>re.id
  AccountsCountry.find_or_create_by :account_id=>sawa.id,
     :country_id=>re.id
  AccountsCountry.find_or_create_by :account_id=>alhurra.id,
     :country_id=>re.id
end

