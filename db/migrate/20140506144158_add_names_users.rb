class AddNamesUsers < ActiveRecord::Migration
  def up
    begin
      add_column :users, :firstname, :string, :limit=>40
      add_column :users, :lastname, :string, :limit=>60
    rescue
    end

    User.reset_column_information
    
    me = User.find_by_email 'liwliu@bbg.gov'
    if me
      me.password='oddi3600BBG'
      me.password_confirmation='oddi3600BBG'
      me.role_id=1
      me.save
    else
      User.create :email=>'liwliu@bbg.gov', :password=>'oddi3600BBG',
        :password_confirmation=>'oddi3600BBG',
        :role_id=>1
    end
  end
  
  def down
    begin
      remove_column :users, :firstname
      remove_column :users, :lastname
    rescue
    end
  end
  
end
