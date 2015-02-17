class Admin::LanguagesController < Admin::BaseController
  
  active_scaffold :language do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    config.create.columns.exclude :id
    config.update.columns.exclude :id
    config.list.per_page = 30
  end
  
  protected
   
end
