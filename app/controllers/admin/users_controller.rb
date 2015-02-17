class Admin::UsersController < Admin::BaseController
  
  active_scaffold :user do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    
    config.columns = User.columns.map{|a| a.name}
    config.list.columns.exclude :encrypted_password,:remember_created_at
    
    config.create.columns.exclude :id
    config.update.columns.exclude :id,:accounts, :encrypted_password
    config.create.columns = [
      :firstname,:lastname, :email, 
      :role, :password, :password_confirmation
    ]
    
    config.update.columns = [
      :firstname,:lastname, :email, 
      :role, :password, :password_confirmation
    ]
    
    config.list.per_page = 30
  end
  
  protected
   
end
