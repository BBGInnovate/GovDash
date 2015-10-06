class Api::V2::OrganizationsController < Api::V2::BaseController
  #before_filter :authenticate_user!
  #before_filter :is_analyst?
  #before_filter :is_admin?, only: [:new, :create, :edit, :update, :destroy]

  def add_related obj
    grp_arr = []
    subgrp_arr = []
    obj.groups.includes(:subgroups).each do |grp|
      grp_arr << {id: grp.id, name: grp.name }
      grp.subgroups.each do |subgrp|
        subgrp_arr << {id: subgrp.id, name: subgrp.name }
      end
    end
    {:groups=>grp_arr, :subgroups=>subgrp_arr}
  end
  
  def option_for_select
    cond = super
    cond << "name = 'bbg'"
    cond
  end
  
  def __option_for_select
    cond = super
    user = current_user
    cond << "(id in (select organization_id from roles where roles.user_id=#{user.id}))"
    cond
  end
  
end
