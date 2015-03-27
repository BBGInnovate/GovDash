class Api::V2::SubgroupsController < Api::V2::BaseController

  #attach related Groups output
  def add_related model_object
    hsh = nil
    if Subgroup === model_object
      subgroup_ids = GroupsSubgroups.where(["subgroup_id = ?", model_object.id]).map{|gs| gs.subgroup_id}.uniq
      if !subgroup_ids.empty?
        hsh = {:related_groups=>[]}
        subgroup_ids.each do |sgid|
          grps = GroupsSubgroups.where(["subgroup_id in (?)", subgroup_ids]).map{ |gs| gs.group.as_json }
          hsh[:related_groups] = grps
        end
      end 
    end
    hsh
  end

  def create
    begin
      @data = model_class.new _params_
      puts "data: "
      puts @data.inspect
       
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
