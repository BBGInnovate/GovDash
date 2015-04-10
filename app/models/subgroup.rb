class Subgroup < ActiveRecord::Base
  validates :name, length: { in: 2..128 }  
  has_many :accounts
  has_many :groups_subgroups, class_name: GroupsSubgroups
  has_many :groups, :through => :groups_subgroups
  has_and_belongs_to_many :regions, :join_table => :subgroups_regions

  def self.find_me(name, group_name)
    nid = Group.find_by_name(group_name).id
    where("name='#{name}' AND group_id=#{nid}").first
  end


end

