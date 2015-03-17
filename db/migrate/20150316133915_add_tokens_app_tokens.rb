class AddTokensAppTokens < ActiveRecord::Migration
  def change
    add_column :app_tokens, :user_access_token, :string, after: :client_secret
    add_column :app_tokens, :page_access_token, :string, after: :client_secret
  end
end
