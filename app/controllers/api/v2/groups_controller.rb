class Api::V2::GroupsController < Api::V2::BaseController


  def add_related model_object
    #attach related Subgroups
    hsh = nil
    if Group === model_object
      sql1 = "select distinct subgroup_id from groups_subgroups where group_id = #{model_object.id}"
      subgrps = Subgroup.where("id in (#{sql1})").to_a
      if subgrps.count > 0
        hsh = {:related_subgroups=>[]}
        subgrps.each do |sg|
          hsh[:related_subgroups] = sg.attributes
        end
      end
    end
    hsh
  end

  def _params_
    cols = model_class.columns.map{|a| a.name.to_sym}
    params.require(model_name.to_sym).permit(cols)
  end
  
end
