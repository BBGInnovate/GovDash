class SubgroupsRegion < ActiveRecord::Base
  self.table_name = :subgroups_regions
  belongs_to :subgroup
  belongs_to :region
end
