class RemoveTokensAppTokens < ActiveRecord::Migration
  def change
    begin
      remove_column :app_tokens, :user_access_token
      remove_column :app_tokens, :page_access_token
    rescue
    end
  end
end
