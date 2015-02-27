class RemoveTokensAppTokens < ActiveRecord::Migration
  def change
    remove_column :app_tokens, :user_access_token
    remove_column :app_tokens, :page_access_token
  end
end
