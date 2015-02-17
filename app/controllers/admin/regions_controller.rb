class Admin::RegionsController < Admin::BaseController
  
  active_scaffold :region do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    config.columns = [:id, :name, :created_at,:updated_at]
    config.create.columns.exclude :id
    config.update.columns.exclude :id
    config.list.per_page = 30
  end
  
  protected
   
end
