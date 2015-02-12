class UpdateAccountsRegions < ActiveRecord::Migration
  def change
    AccountsRegion.populate
  end
end
