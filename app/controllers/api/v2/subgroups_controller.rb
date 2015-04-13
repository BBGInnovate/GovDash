class Api::V2::SubgroupsController < Api::V2::BaseController

  #attach related Groups output
  def add_related model_object
    hsh = nil
    if Subgroup === model_object
      subgroup_ids = GroupsSubgroups.where(["subgroup_id = ?", model_object.id]).map{|gs| gs.subgroup_id}.uniq
      if !subgroup_ids.empty?
        hsh = {:related_groups=>[],
               :related_regions=>[]}
        group_ids = GroupsSubgroups.select("group_id").
           where(["subgroup_id in (?)", subgroup_ids]).
           map(&:group_id)
        Group.where(["id in (?)", group_ids] ).to_a.each do |grp|
          attr = grp.attributes
          ['created_at','updated_at'].each do |col|
            attr.delete col
          end
          hsh[:related_groups] << attr
        end
        region_ids = SubgroupsRegion.select("region_id").
                 where(["subgroup_id in (?)", subgroup_ids]).
                 map(&:region_id)
        Region.where(["id in (?)", region_ids] ).to_a.each do |reg|
          hsh[:related_regions] << reg.attributes
        end
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
