class Subgroup < ActiveRecord::Base
  validates :name, length: { in: 2..40 }
#  validates_numericality_of :group_id, :on => :create
  
  has_many :accounts
  has_and_belongs_to_many :groups

  def self.populate
    # place holder
  end
  
  def self.find_me(name, group_name)
    nid = Group.find_by_name(group_name).id
    where("name='#{name}' AND group_id=#{nid}").first
  end
end
