class Api::V2::SubgroupsController < Api::V2::BaseController
  include Api::ReportsHelper
  #attach related Groups output
  def add_related model_object
    if Subgroup === model_object
      @region_array = get_subgroup_region_hash[model_object.id]
      @group_array = get_subgroup_group_hash[model_object.id]
      hsh = {:related_groups=>[],:related_regions=>[]}
      # sql1 = "select distinct group_id from groups_subgroups where subgroup_id = #{model_object.id}"
      # groups = Group.select("id,name,description,organization_id").where("id in (#{sql1})").to_a
      # groups.to_a.each do |grp|
      @group_array.each do |grp|
        # attr = grp.attributes
        hsh[:related_groups] << grp
      end
      # sql1 = "select distinct region_id from subgroups_regions where subgroup_id = #{model_object.id}"
      # Region.where("id in (#{sql1})").to_a.each do |reg|
      @region_array.each do |reg|
        # hsh[:related_regions] << reg.attributes
        hsh[:related_regions] << reg
      end
    end
    hsh[:related_groups].sort_by!{|a| a['id']}
    hsh[:related_regions].sort_by!{|a| a['id']}
    hsh
  end

  def create
    begin
      @data = model_class.new _params_       
    rescue
      logger.error "ERR: #{self.class.name}#create #{$!}"
    end
    responding
  end

  private
  def _params_
    cols = model_class.columns.map{|a| a.name.to_sym}
    cols << :group_ids
    params.require(model_name.to_sym).permit(cols)
  end

end
