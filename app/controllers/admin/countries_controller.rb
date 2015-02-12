class Admin::CountriesController < Admin::BaseController
  
  active_scaffold :country do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    config.columns = [:id, :name, :region_id,:created_at,:updated_at]
    config.create.columns.exclude :id
    config.update.columns.exclude :id
    # config.actions.exclude :search, :show
    config.list.per_page = 30
  end
  
  protected
   
end
