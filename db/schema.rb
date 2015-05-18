# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150424132000) do

  create_table "account_profiles", force: :cascade do |t|
    t.integer  "account_id",      limit: 4
    t.string   "platform_type",   limit: 20
    t.string   "name",            limit: 40
    t.string   "display_name",    limit: 255
    t.text     "description",     limit: 65535
    t.string   "location",        limit: 255
    t.string   "url",             limit: 255
    t.string   "avatar",          limit: 255
    t.integer  "total_followers", limit: 4
    t.boolean  "verified",        limit: 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "account_types", force: :cascade do |t|
    t.string   "name",       limit: 40
    t.boolean  "is_active",  limit: 1,  default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "accounts", force: :cascade do |t|
    t.string   "name",             limit: 40
    t.string   "description",      limit: 255
    t.string   "object_name",      limit: 40
    t.boolean  "status",           limit: 1,   default: true
    t.boolean  "page_admin",       limit: 1,   default: false
    t.string   "media_type_name",  limit: 20,  default: "FacebookAccount"
    t.integer  "account_type_id",  limit: 4
    t.integer  "organization_id",  limit: 4
    t.string   "contact",          limit: 255
    t.boolean  "is_active",        limit: 1,   default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sc_segment_id",    limit: 4
    t.boolean  "new_item",         limit: 1,   default: false
    t.string   "object_name_type", limit: 40
  end

  create_table "accounts_countries", force: :cascade do |t|
    t.integer  "account_id", limit: 4
    t.integer  "country_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "accounts_countries", ["account_id"], name: "index_accounts_countries_on_account_id", using: :btree
  add_index "accounts_countries", ["country_id"], name: "index_accounts_countries_on_country_id", using: :btree

  create_table "accounts_groups", id: false, force: :cascade do |t|
    t.integer "account_id", limit: 4, null: false
    t.integer "group_id",   limit: 4, null: false
  end

  add_index "accounts_groups", ["account_id"], name: "index_accounts_groups_on_account_id", using: :btree
  add_index "accounts_groups", ["group_id"], name: "index_accounts_groups_on_group_id", using: :btree

  create_table "accounts_languages", force: :cascade do |t|
    t.integer  "account_id",  limit: 4
    t.integer  "language_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "accounts_languages", ["account_id"], name: "index_accounts_languages_on_account_id", using: :btree
  add_index "accounts_languages", ["language_id"], name: "index_accounts_languages_on_language_id", using: :btree

  create_table "accounts_regions", force: :cascade do |t|
    t.integer  "account_id", limit: 4
    t.integer  "region_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "accounts_regions", ["account_id"], name: "index_accounts_regions_on_account_id", using: :btree
  add_index "accounts_regions", ["region_id"], name: "index_accounts_regions_on_region_id", using: :btree

  create_table "accounts_sc_segments", id: false, force: :cascade do |t|
    t.integer "sc_segment_id", limit: 4
    t.integer "account_id",    limit: 4
    t.boolean "new_item",      limit: 1, default: false
  end

  add_index "accounts_sc_segments", ["sc_segment_id", "account_id"], name: "index_accounts_sc_segments_on_sc_segment_id_and_account_id", using: :btree

  create_table "accounts_subgroups", id: false, force: :cascade do |t|
    t.integer "account_id",  limit: 4, null: false
    t.integer "subgroup_id", limit: 4, null: false
  end

  add_index "accounts_subgroups", ["account_id"], name: "index_accounts_subgroups_on_account_id", using: :btree
  add_index "accounts_subgroups", ["subgroup_id"], name: "index_accounts_subgroups_on_subgroup_id", using: :btree

  create_table "accounts_users", force: :cascade do |t|
    t.integer  "account_id", limit: 4
    t.integer  "user_id",    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.string   "platform",          limit: 20
    t.integer  "account_id",        limit: 4
    t.string   "canvas_url",        limit: 255
    t.string   "api_user_email",    limit: 40
    t.string   "user_access_token", limit: 255
    t.string   "page_access_token", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "app_tokens", force: :cascade do |t|
    t.string   "platform",       limit: 20
    t.string   "canvas_url",     limit: 255
    t.string   "api_user_email", limit: 40
    t.string   "client_id",      limit: 255
    t.string   "client_secret",  limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "articles", force: :cascade do |t|
    t.string   "url",        limit: 255
    t.string   "format",     limit: 20
    t.text     "body",       limit: 65535
    t.string   "byline",     limit: 255
    t.datetime "pub_date"
    t.string   "keywords",   limit: 255
    t.integer  "content_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.binary   "uuid",       limit: 16
  end

  add_index "articles", ["content_id"], name: "index_articles_on_content_id", using: :btree
  add_index "articles", ["url"], name: "index_articles_on_url", using: :btree
  add_index "articles", ["uuid"], name: "index_articles_on_uuid", unique: true, using: :btree

  create_table "audios", force: :cascade do |t|
    t.string   "mimetype",   limit: 20
    t.string   "url",        limit: 255
    t.integer  "bitrate",    limit: 4
    t.integer  "duration",   limit: 4
    t.integer  "filesize",   limit: 4
    t.integer  "content_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.binary   "uuid",       limit: 16
    t.string   "quality",    limit: 255
  end

  add_index "audios", ["content_id"], name: "index_audios_on_content_id", using: :btree
  add_index "audios", ["url"], name: "index_audios_on_url", using: :btree
  add_index "audios", ["uuid"], name: "index_audios_on_uuid", unique: true, using: :btree

  create_table "contents", force: :cascade do |t|
    t.binary   "uuid",            limit: 16
    t.string   "title",           limit: 255
    t.text     "description",     limit: 65535
    t.datetime "pub_date"
    t.string   "state",           limit: 20
    t.string   "object_name",     limit: 255
    t.integer  "network_id",      limit: 4
    t.integer  "organization_id", limit: 4
    t.integer  "language_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "keywords",        limit: 65535
  end

  add_index "contents", ["language_id"], name: "index_contents_on_language_id", using: :btree
  add_index "contents", ["network_id"], name: "index_contents_on_network_id", using: :btree
  add_index "contents", ["object_name"], name: "index_contents_on_object_name", unique: true, using: :btree
  add_index "contents", ["organization_id"], name: "index_contents_on_organization_id", using: :btree
  add_index "contents", ["pub_date"], name: "index_contents_on_pub_date", using: :btree
  add_index "contents", ["uuid"], name: "index_contents_on_uuid", unique: true, using: :btree

  create_table "contents_countries", id: false, force: :cascade do |t|
    t.integer  "country_id", limit: 4
    t.integer  "content_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "contents_countries", ["content_id"], name: "index_contents_countries_on_content_id", using: :btree
  add_index "contents_countries", ["country_id"], name: "index_contents_countries_on_country_id", using: :btree

  create_table "contents_opencalais_categories", id: false, force: :cascade do |t|
    t.integer "content_id",             limit: 4, null: false
    t.integer "opencalais_category_id", limit: 4, null: false
  end

  add_index "contents_opencalais_categories", ["content_id"], name: "index_contents_opencalais_categories_on_content_id", using: :btree
  add_index "contents_opencalais_categories", ["opencalais_category_id"], name: "index_contents_opencalais_categories_on_opencalais_category_id", using: :btree

  create_table "contents_opencalais_entities", id: false, force: :cascade do |t|
    t.integer "content_id",           limit: 4, null: false
    t.integer "opencalais_entity_id", limit: 4, null: false
  end

  add_index "contents_opencalais_entities", ["content_id"], name: "index_contents_opencalais_entities_on_content_id", using: :btree
  add_index "contents_opencalais_entities", ["opencalais_entity_id"], name: "index_contents_opencalais_entities_on_opencalais_entity_id", using: :btree

  create_table "contents_opencalais_geographies", id: false, force: :cascade do |t|
    t.integer "content_id",              limit: 4, null: false
    t.integer "opencalais_geography_id", limit: 4, null: false
  end

  add_index "contents_opencalais_geographies", ["content_id"], name: "index_contents_opencalais_geographies_on_content_id", using: :btree
  add_index "contents_opencalais_geographies", ["opencalais_geography_id"], name: "index_contents_opencalais_geographies_on_opencalais_geography_id", using: :btree

  create_table "countries", force: :cascade do |t|
    t.string "name", limit: 60
    t.string "code", limit: 4
    t.binary "uuid", limit: 16
  end

  add_index "countries", ["code"], name: "index_countries_on_code", using: :btree
  add_index "countries", ["uuid"], name: "index_countries_on_uuid", unique: true, using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0, null: false
    t.integer  "attempts",   limit: 4,     default: 0, null: false
    t.text     "handler",    limit: 65535,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "documents", force: :cascade do |t|
    t.string   "mimetype",   limit: 20
    t.integer  "filesize",   limit: 4
    t.string   "url",        limit: 255
    t.integer  "content_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.binary   "uuid",       limit: 16
  end

  add_index "documents", ["content_id"], name: "index_documents_on_content_id", using: :btree
  add_index "documents", ["url"], name: "index_documents_on_url", using: :btree
  add_index "documents", ["uuid"], name: "index_documents_on_uuid", unique: true, using: :btree

  create_table "error_logs", force: :cascade do |t|
    t.string   "message",    limit: 1024
    t.string   "subject",    limit: 255,  default: ""
    t.integer  "severity",   limit: 1
    t.boolean  "email_sent", limit: 1
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "facebooks", force: :cascade do |t|
    t.string   "identifier",   limit: 20
    t.string   "access_token", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fb_pages", force: :cascade do |t|
    t.integer  "account_id",                           limit: 4
    t.string   "object_name",                          limit: 40
    t.integer  "total_likes",                          limit: 4
    t.integer  "total_comments",                       limit: 4
    t.integer  "total_shares",                         limit: 4
    t.integer  "total_talking_about",                  limit: 4
    t.integer  "likes",                                limit: 4
    t.integer  "comments",                             limit: 4
    t.integer  "shares",                               limit: 4
    t.integer  "posts",                                limit: 4
    t.integer  "replies_to_comment",                   limit: 4
    t.integer  "fan_adds_day",                         limit: 4
    t.integer  "story_adds_day",                       limit: 4
    t.string   "story_adds_by_story_type_day",         limit: 255
    t.integer  "consumptions_day",                     limit: 4
    t.string   "consumptions_by_consumption_type_day", limit: 255
    t.integer  "stories_week",                         limit: 4
    t.integer  "stories_day_28",                       limit: 4
    t.string   "stories_by_story_type_week",           limit: 255
    t.datetime "post_created_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fb_pages", ["account_id"], name: "index_fb_pages_on_account_id", using: :btree
  add_index "fb_pages", ["post_created_time"], name: "index_fb_pages_on_post_created_time", using: :btree

  create_table "fb_posts", force: :cascade do |t|
    t.integer  "account_id",         limit: 4
    t.string   "post_id",            limit: 40
    t.integer  "likes",              limit: 4
    t.integer  "comments",           limit: 4
    t.integer  "shares",             limit: 4
    t.string   "post_type",          limit: 20
    t.integer  "replies_to_comment", limit: 4
    t.datetime "post_created_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fb_posts", ["account_id"], name: "index_fb_posts_on_account_id", using: :btree
  add_index "fb_posts", ["post_created_time"], name: "index_fb_posts_on_post_created_time", using: :btree
  add_index "fb_posts", ["post_id"], name: "index_fb_posts_on_post_id", unique: true, using: :btree

  create_table "fbpages", force: :cascade do |t|
    t.integer  "account_id",                           limit: 4
    t.string   "object_name",                          limit: 40
    t.integer  "total_likes",                          limit: 4
    t.integer  "total_comments",                       limit: 4
    t.integer  "total_shares",                         limit: 4
    t.integer  "total_talking_about",                  limit: 4
    t.integer  "likes",                                limit: 4
    t.integer  "comments",                             limit: 4
    t.integer  "shares",                               limit: 4
    t.integer  "posts",                                limit: 4
    t.integer  "replies_to_comment",                   limit: 4
    t.integer  "fan_adds_day",                         limit: 4
    t.integer  "story_adds_day",                       limit: 4
    t.string   "story_adds_by_story_type_day",         limit: 255
    t.integer  "consumptions_day",                     limit: 4
    t.string   "consumptions_by_consumption_type_day", limit: 255
    t.integer  "stories_week",                         limit: 4
    t.integer  "stories_day_28",                       limit: 4
    t.string   "stories_by_story_type_week",           limit: 255
    t.datetime "post_created_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fbpages", ["account_id"], name: "index_fb_pages_on_account_id", using: :btree
  add_index "fbpages", ["post_created_time"], name: "index_fb_pages_on_post_created_time", using: :btree

  create_table "groups", force: :cascade do |t|
    t.string   "name",            limit: 100
    t.string   "description",     limit: 255
    t.boolean  "is_active",       limit: 1,   default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id", limit: 4
  end

  add_index "groups", ["organization_id"], name: "index_groups_on_organization_id", using: :btree

  create_table "groups_subgroups", id: false, force: :cascade do |t|
    t.integer "group_id",    limit: 4, null: false
    t.integer "subgroup_id", limit: 4, null: false
  end

  create_table "images", force: :cascade do |t|
    t.string   "url",        limit: 255
    t.string   "mimetype",   limit: 20
    t.integer  "filesize",   limit: 4
    t.integer  "width",      limit: 4
    t.integer  "height",     limit: 4
    t.integer  "content_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "caption",    limit: 65535
    t.string   "credit",     limit: 255
    t.string   "source",     limit: 255
    t.binary   "uuid",       limit: 16
  end

  add_index "images", ["content_id"], name: "index_images_on_content_id", using: :btree
  add_index "images", ["url"], name: "index_images_on_url", using: :btree
  add_index "images", ["uuid"], name: "index_images_on_uuid", unique: true, using: :btree

  create_table "ingressed_items", force: :cascade do |t|
    t.string   "type",                                    limit: 20
    t.string   "original_lang_code",                      limit: 10
    t.integer  "machine_translated_character_count",      limit: 4
    t.integer  "derived_original_word_count",             limit: 4
    t.integer  "rss_item_rss_source_id",                  limit: 4
    t.string   "rss_item_url",                            limit: 255
    t.string   "rss_item_original_title",                 limit: 255
    t.string   "rss_item_original_description",           limit: 500
    t.string   "rss_item_machine_translated_title",       limit: 255
    t.string   "rss_item_machine_translated_description", limit: 500
    t.string   "rss_item_human_translated_title",         limit: 255
    t.string   "rss_item_human_translated_description",   limit: 255
    t.datetime "rss_item_published_at"
    t.string   "original_lang_code_detected",             limit: 10
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ingressed_items", ["rss_item_rss_source_id", "rss_item_url"], name: "index_ingressed_items_on_rss_item_rss_source_id_and_rss_item_url", unique: true, using: :btree
  add_index "ingressed_items", ["type"], name: "index_ingressed_items_on_type", using: :btree

  create_table "languages", force: :cascade do |t|
    t.string   "name",       limit: 100
    t.string   "lang_code",  limit: 20
    t.datetime "created_at"
    t.datetime "updated_at"
    t.binary   "uuid",       limit: 16
  end

  add_index "languages", ["uuid"], name: "index_languages_on_uuid", unique: true, using: :btree

  create_table "media_types", force: :cascade do |t|
    t.string   "name",       limit: 20
    t.boolean  "is_active",  limit: 1,  default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "networks", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.string   "object_name",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url",             limit: 255
    t.text     "description",     limit: 65535
    t.integer  "organization_id", limit: 4
    t.binary   "uuid",            limit: 16
  end

  add_index "networks", ["organization_id"], name: "index_networks_on_organization_id", using: :btree
  add_index "networks", ["uuid"], name: "index_networks_on_uuid", unique: true, using: :btree

  create_table "networks_countries", id: false, force: :cascade do |t|
    t.integer  "country_id", limit: 4
    t.integer  "network_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "networks_countries", ["country_id"], name: "index_networks_countries_on_country_id", using: :btree
  add_index "networks_countries", ["network_id"], name: "index_networks_countries_on_network_id", using: :btree

  create_table "opencalais_categories", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "opencalais_entities", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "entity_type", limit: 255
  end

  create_table "opencalais_geographies", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.float    "latitude",   limit: 24
    t.float    "longitude",  limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "organizations", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "object_name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url",         limit: 255
    t.text     "description", limit: 65535
    t.binary   "uuid",        limit: 16
  end

  add_index "organizations", ["uuid"], name: "index_organizations_on_uuid", unique: true, using: :btree

  create_table "photo_galleries", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.string   "url",        limit: 255
    t.integer  "content_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.binary   "uuid",       limit: 16
  end

  add_index "photo_galleries", ["content_id"], name: "index_photo_galleries_on_content_id", using: :btree
  add_index "photo_galleries", ["url"], name: "index_photo_galleries_on_url", using: :btree
  add_index "photo_galleries", ["uuid"], name: "index_photo_galleries_on_uuid", unique: true, using: :btree

  create_table "records", force: :cascade do |t|
    t.string   "data",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "region_reports", force: :cascade do |t|
    t.integer  "region_id",      limit: 4
    t.datetime "date"
    t.integer  "facebook_count", limit: 4
    t.integer  "twitter_count",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "region_reports", ["region_id"], name: "index_region_reports_on_region_id", using: :btree

  create_table "regions", force: :cascade do |t|
    t.string  "name",       limit: 100
    t.boolean "is_active",  limit: 1,   default: true
    t.string  "segment_id", limit: 30
  end

  add_index "regions", ["name"], name: "index_regions_on_name", using: :btree
  add_index "regions", ["segment_id"], name: "index_regions_on_segment_id", using: :btree

  create_table "regions_countries", force: :cascade do |t|
    t.integer "region_id",  limit: 4
    t.integer "country_id", limit: 4
  end

  add_index "regions_countries", ["country_id"], name: "index_regions_countries_on_country_id", using: :btree
  add_index "regions_countries", ["region_id"], name: "index_regions_countries_on_region_id", using: :btree

  create_table "roles", force: :cascade do |t|
    t.string   "name",        limit: 20
    t.string   "description", limit: 255
    t.boolean  "disabled",    limit: 1,   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "rss_sources", force: :cascade do |t|
    t.string   "url",             limit: 255
    t.datetime "last_fetched_at"
    t.string   "rss_title",       limit: 40
    t.string   "rss_description", limit: 255
    t.string   "rss_language",    limit: 16
    t.integer  "rss_ttl",         limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rss_sources", ["url"], name: "index_rss_sources_on_url", unique: true, using: :btree

  create_table "rss_subscriptions", force: :cascade do |t|
    t.boolean  "active",                                        limit: 1,  default: true
    t.integer  "rss_source_id",                                 limit: 4
    t.string   "name",                                          limit: 40
    t.integer  "ingressed_item_count",                          limit: 4,  default: 0
    t.integer  "ingressed_item_byte_count",                     limit: 4,  default: 0
    t.integer  "ingressed_item_machine_translation_byte_count", limit: 4,  default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rss_subscriptions", ["active", "rss_source_id"], name: "index_rss_subscriptions_on_active_and_rss_source_id", unique: true, using: :btree
  add_index "rss_subscriptions", ["rss_source_id"], name: "rss_subscriptions_rss_source_id_fk", using: :btree

  create_table "sc_referral_traffic", force: :cascade do |t|
    t.integer  "facebook_count", limit: 4
    t.integer  "twitter_count",  limit: 4
    t.integer  "sc_segment_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sc_referral_traffic", ["sc_segment_id"], name: "index_sc_referral_traffic_on_sc_segment_id", using: :btree

  create_table "sc_segments", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "sc_id",      limit: 255
    t.integer  "account_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sc_segments", ["account_id"], name: "index_sc_segments_on_account_id", using: :btree
  add_index "sc_segments", ["sc_id"], name: "index_sc_segments_on_sc_id", using: :btree

  create_table "services", force: :cascade do |t|
    t.string   "name",        limit: 40
    t.string   "description", limit: 255
    t.string   "network_id",  limit: 255
    t.boolean  "is_active",   limit: 1,   default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "socialmedia_accounts", force: :cascade do |t|
    t.binary   "uuid",            limit: 16
    t.integer  "network_id",      limit: 4
    t.integer  "organization_id", limit: 4
    t.string   "name",            limit: 255
    t.text     "description",     limit: 65535
    t.integer  "status",          limit: 4
    t.string   "url",             limit: 255
    t.string   "account_type",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "socialmedia_accounts", ["network_id"], name: "index_socialmedia_accounts_on_network_id", using: :btree
  add_index "socialmedia_accounts", ["organization_id"], name: "index_socialmedia_accounts_on_organization_id", using: :btree
  add_index "socialmedia_accounts", ["uuid"], name: "index_socialmedia_accounts_on_uuid", unique: true, using: :btree

  create_table "subgroups", force: :cascade do |t|
    t.string   "name",        limit: 100
    t.string   "description", limit: 255
    t.boolean  "is_active",   limit: 1,   default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "subgroups", ["name"], name: "index_subgroups_on_name", using: :btree

  create_table "subgroups_regions", force: :cascade do |t|
    t.integer "subgroup_id", limit: 4
    t.integer "region_id",   limit: 4
  end

  add_index "subgroups_regions", ["region_id"], name: "index_subgroups_regions_on_region_id", using: :btree
  add_index "subgroups_regions", ["subgroup_id"], name: "index_subgroups_regions_on_subgroup_id", using: :btree

  create_table "system_infos", force: :cascade do |t|
    t.string   "property_name",   limit: 40
    t.integer  "last_content_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "topics", force: :cascade do |t|
    t.string   "name",         limit: 40
    t.string   "topic",        limit: 255
    t.string   "source",       limit: 20
    t.string   "organization", limit: 50
    t.string   "network",      limit: 20
    t.string   "language",     limit: 40
    t.string   "country",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "topics", ["topic"], name: "index_topics_on_topic", using: :btree

  create_table "translations", force: :cascade do |t|
    t.integer  "content_id",             limit: 4
    t.string   "translated_title",       limit: 255
    t.text     "translated_description", limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "translations", ["content_id"], name: "index_translations_on_content_id", using: :btree

  create_table "tw_timelines", force: :cascade do |t|
    t.integer  "account_id",       limit: 4
    t.string   "object_name",      limit: 40
    t.integer  "total_tweets",     limit: 4
    t.integer  "total_favorites",  limit: 4
    t.integer  "total_followers",  limit: 4
    t.integer  "tweets",           limit: 4
    t.integer  "favorites",        limit: 4
    t.integer  "followers",        limit: 4
    t.integer  "retweets",         limit: 4
    t.integer  "mentions",         limit: 4
    t.datetime "tweet_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tw_timelines", ["account_id"], name: "index_tw_timelines_on_account_id", using: :btree
  add_index "tw_timelines", ["tweet_created_at"], name: "index_tw_timelines_on_tweet_created_at", using: :btree

  create_table "tw_tweets", force: :cascade do |t|
    t.integer  "account_id",       limit: 4
    t.integer  "tweet_id",         limit: 8
    t.integer  "retweets",         limit: 4
    t.integer  "favorites",        limit: 4
    t.integer  "mentions",         limit: 4
    t.datetime "tweet_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tw_tweets", ["account_id"], name: "index_tw_tweets_on_account_id", using: :btree
  add_index "tw_tweets", ["tweet_created_at"], name: "index_tw_tweets_on_tweet_created_at", using: :btree
  add_index "tw_tweets", ["tweet_id"], name: "index_tw_tweets_on_tweet_id", using: :btree

  create_table "twitter_users", force: :cascade do |t|
    t.string   "identifier",          limit: 20
    t.string   "access_token",        limit: 255
    t.string   "access_token_secret", limit: 255
    t.text     "access_token_obj",    limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "username",            limit: 20,    null: false
    t.string   "crypted_password",    limit: 100,   null: false
    t.string   "password_salt",       limit: 40,    null: false
    t.string   "persistence_token",   limit: 255,   null: false
    t.string   "single_access_token", limit: 255,   null: false
    t.text     "settings",            limit: 65535
    t.string   "email",               limit: 40
    t.boolean  "admin",               limit: 1
    t.integer  "role_id",             limit: 4
    t.boolean  "disabled",            limit: 1
    t.string   "full_name",           limit: 255
    t.string   "organization",        limit: 20
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["single_access_token"], name: "index_users_on_single_access_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  limit: 255,   null: false
    t.integer  "item_id",    limit: 4,     null: false
    t.string   "event",      limit: 255,   null: false
    t.string   "whodunnit",  limit: 255
    t.text     "object",     limit: 65535
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

  create_table "videos", force: :cascade do |t|
    t.string   "url",        limit: 255
    t.string   "mimetype",   limit: 20
    t.integer  "bitrate",    limit: 4
    t.integer  "duration",   limit: 4
    t.integer  "filesize",   limit: 4
    t.integer  "content_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.binary   "uuid",       limit: 16
    t.string   "quality",    limit: 255
  end

  add_index "videos", ["content_id"], name: "index_videos_on_content_id", using: :btree
  add_index "videos", ["url"], name: "index_videos_on_url", using: :btree
  add_index "videos", ["uuid"], name: "index_videos_on_uuid", unique: true, using: :btree

  create_table "web_pages", force: :cascade do |t|
    t.integer  "ingressed_item_id",                       limit: 4
    t.string   "initial_url",                             limit: 255
    t.string   "final_url",                               limit: 255
    t.string   "media_type",                              limit: 64
    t.string   "original_title",                          limit: 255
    t.text     "original_text",                           limit: 65535
    t.string   "original_lang_code",                      limit: 10
    t.string   "machine_translated_title",                limit: 255
    t.text     "machine_translated_text",                 limit: 65535
    t.integer  "machine_translated_character_count",      limit: 4
    t.string   "human_translated_title",                  limit: 255
    t.text     "human_translated_text",                   limit: 65535
    t.integer  "source_word_count_for_human_translation", limit: 4
    t.string   "categories_from_calais",                  limit: 255
    t.string   "original_lang_code_detected",             limit: 10
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "web_pages", ["ingressed_item_id"], name: "web_pages_ingressed_item_id_fk", using: :btree

  create_table "yt_channels", force: :cascade do |t|
    t.integer  "account_id",        limit: 4
    t.string   "channel_id",        limit: 255
    t.integer  "views",             limit: 4
    t.integer  "comments",          limit: 4
    t.integer  "videos",            limit: 4
    t.integer  "subscribers",       limit: 4
    t.integer  "video_subscribers", limit: 4,   default: 0
    t.integer  "video_comments",    limit: 4,   default: 0
    t.integer  "video_favorites",   limit: 4,   default: 0
    t.integer  "video_likes",       limit: 4,   default: 0
    t.integer  "video_views",       limit: 4,   default: 0
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "video_dislikes",    limit: 4,   default: 0
  end

  add_index "yt_channels", ["account_id"], name: "index_yt_channels_on_account_id", using: :btree
  add_index "yt_channels", ["channel_id"], name: "index_yt_channels_on_channel_id", using: :btree
  add_index "yt_channels", ["published_at"], name: "index_yt_channels_on_published_at", using: :btree

  create_table "yt_videos", force: :cascade do |t|
    t.integer  "account_id",   limit: 4
    t.string   "video_id",     limit: 40
    t.integer  "likes",        limit: 4
    t.integer  "comments",     limit: 4
    t.integer  "favorites",    limit: 4
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "yt_videos", ["account_id"], name: "index_yt_videos_on_account_id", using: :btree
  add_index "yt_videos", ["published_at"], name: "index_yt_videos_on_published_at", using: :btree
  add_index "yt_videos", ["video_id"], name: "index_yt_videos_on_video_id", unique: true, using: :btree

  add_foreign_key "groups", "organizations"
  add_foreign_key "rss_subscriptions", "rss_sources", name: "rss_subscriptions_rss_source_id_fk"
  add_foreign_key "web_pages", "ingressed_items", name: "web_pages_ingressed_item_id_fk"
end
