class CreateGoogleAccessTokens < ActiveRecord::Migration
  def change
    create_table :google_access_tokens do |t|
      t.string :email
      t.string :provider, limit: 36
      t.string :token
      t.string :refresh_token
      t.string :token_type
      t.string :scope
      t.datetime :expires_at
      t.integer :expires_in
      t.boolean :expires
      t.timestamp
    end
  end
end
