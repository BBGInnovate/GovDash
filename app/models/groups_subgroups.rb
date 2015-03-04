class GroupsSubgroups < ActiveRecord::Base
  belongs_to :groups
  belongs_to :subgroups
  
  def to_label
    'Groups Subgroups'
  end
  
end
