class Role < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization
  
  def self.populate
    self.create :name=>'Administrator', :weight=>8,
      :description => 'administer users'
    self.create :name=>'Analyst',:weight=>5,
      :description => 'Access all reports'
    self.create :name=>'Service Chief',:weight=>3,
      :description => 'view a limited set of reports only for a specific Network/Language'
    self.create :name=>'Anonymous',:weight=>1,
      :description => 'This is a private Dashboard without Anon access'
  end
end