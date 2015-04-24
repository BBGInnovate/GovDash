class AddIndexLookupTables < ActiveRecord::Migration
  def change
    add_index :accounts_countries, :account_id
    add_index :accounts_countries, :country_id
    add_index :accounts_groups, :account_id
    add_index :accounts_groups, :group_id
    add_index :accounts_languages, :account_id
    add_index :accounts_languages, :language_id
    add_index :accounts_regions, :account_id
    add_index :accounts_regions, :region_id
    add_index :accounts_subgroups, :account_id
    add_index :accounts_subgroups, :subgroup_id
    add_index :countries, :name
    add_index :countries, :region_id
    add_index :regions, :name
    add_index :regions, :segment_id
    add_index :regions_countries, :region_id
    add_index :regions_countries, :country_id
    add_index :sc_segments, :sc_id
    add_index :sc_segments, :account_id
    add_index :subgroups, :name
    add_index :subgroups_regions, :subgroup_id
    add_index :subgroups_regions, :region_id
    add_index :sc_referral_traffic, :sc_segment_id

  end
end
