class Api::V2::SubgroupsController < Api::V2::BaseController

  #attach related Groups output
  def add_related model_object
    if Subgroup === model_object
      hsh = {:related_groups=>[],:related_regions=>[]}
      sql1 = "select distinct group_id from groups_subgroups where subgroup_id = #{model_object.id}"
      groups = Group.select("id,name,description,organization_id").where("id in (#{sql1})").to_a
      groups.to_a.each do |grp|
        attr = grp.attributes
        hsh[:related_groups] << attr
      end
      sql1 = "select distinct region_id from subgroups_regions where subgroup_id = #{model_object.id}"
      Region.where("id in (#{sql1})").to_a.each do |reg|
        hsh[:related_regions] << reg.attributes
      end
    end
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
