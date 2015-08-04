class Group < ActiveRecord::Base
  belongs_to :organization
  # has_many :accounts
  has_and_belongs_to_many :accounts
  has_many :groups_subgroups, class_name: GroupsSubgroups
  has_many :subgroups, :through => :groups_subgroups

  validates :name, length: { in: 2..40 }

  def self.filter_attr(attributes)
  
  end
  
end

