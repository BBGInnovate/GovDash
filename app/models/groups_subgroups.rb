class GroupsSubgroups < ActiveRecord::Base
  belongs_to :group
  belongs_to :subgroup

  def to_label
    'Groups Subgroups'
  end
  
  def self.insert group_id, subgroup_id
    if !!group_id && !!subgroup_id
      self.find_or_create_by group_id: group_id, subgroup_id: subgroup_id
    end
  end
  
end
