module UsersHelper

  def role_form_column(record, input_name)
    select_tag 'record[role_id]', options_for_select(Role.all.map{|c| ["#{c.name}",c.id]},record.role_id.to_s),:multiple => false
  end
  
end
