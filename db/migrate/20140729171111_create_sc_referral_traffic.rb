class CreateScReferralTraffic < ActiveRecord::Migration
  def change
    create_table :sc_referral_traffic do |t|
      t.integer :facebook_count
      t.integer :twitter_count
      t.integer :sc_segment_id
      t.timestamps
    end

  end
end
