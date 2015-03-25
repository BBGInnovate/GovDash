class Subgroup < ActiveRecord::Base
  validates :name, length: { in: 2..40 }  
  has_many :accounts
  has_many :groups_subgroups, class_name: GroupsSubgroups
  has_many :groups, :through => :groups_subgroups
  
  def self.find_me(name, group_name)
    nid = Group.find_by_name(group_name).id
    where("name='#{name}' AND group_id=#{nid}").first
  end

  private
  def subgroup_params
    _params_
  end

end

