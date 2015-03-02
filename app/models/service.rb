class Service < ActiveRecord::Base
  validates :name, length: { in: 2..40 }
#  validates_numericality_of :group_id, :on => :create
  
  belongs_to :group
  has_many :accounts

  def self.populate
    # place holder
  end
  
  def self.find_me(name, group_name)
    nid = Group.find_by_name(group_name).id
    where("name='#{name}' AND group_id=#{nid}").first
  end
end

