class Admin::AccountsCountriesController < Admin::BaseController
  
  active_scaffold :accounts_country do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    config.columns = [:account_id,:country_id,:created_at,:updated_at]
    config.list.per_page = 30
  end
  
  protected
   
end
