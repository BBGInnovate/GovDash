class RemoveClientAccounts < ActiveRecord::Migration
  def up
    remove_column "accounts",:client_id
    remove_column "accounts",:client_secret
    remove_column "accounts",:canvas_url
  end
  
  def down
    unless column_exists?(:accounts, :client_id)
      add_column "accounts",:client_id,:string,:limit=>64,:default=>'762515890447080'
      add_column "accounts",:client_secret,:string,:limit=>64,:default=>'f89517ad8f0118032e3323da04a11249'
      add_column "accounts",:canvas_url,:string,:defaul=>'http://smdata.bbg.gov/'
    end
  end
end
