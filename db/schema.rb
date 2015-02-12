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

ActiveRecord::Schema.define(version: 20140924172829) do

  create_table "account_types", force: true do |t|
    t.string   "name",       limit: 20
    t.boolean  "is_active",             default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "accounts", force: true do |t|
    t.string   "name",              limit: 40
    t.string   "description"
    t.string   "object_name",       limit: 40
    t.boolean  "status",                       default: true
    t.boolean  "page_admin",                   default: false
    t.string   "media_type_name",   limit: 20, default: "FacebookAccount"
    t.integer  "network_id"
    t.integer  "service_id"
    t.integer  "account_type_id"
    t.integer  "language_id"
    t.string   "contact"
    t.string   "user_access_token"
    t.string   "page_access_token"
    t.boolean  "is_active",                    default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sc_segment_id"
    t.boolean  "new_item",                     default: false
  end

  create_table "accounts_countries", force: true do |t|
    t.integer  "account_id"
    t.integer  "country_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "accounts_languages", force: true do |t|
    t.integer  "account_id"
    t.integer  "language_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "accounts_regions", force: true do |t|
    t.integer  "account_id"
    t.integer  "region_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "accounts_sc_segments", id: false, force: true do |t|
    t.integer "sc_segment_id"
    t.integer "account_id"
    t.boolean "new_item",      default: false
  end

  add_index "accounts_sc_segments", ["sc_segment_id", "account_id"], name: "index_accounts_sc_segments_on_sc_segment_id_and_account_id", using: :btree

  create_table "accounts_users", force: true do |t|
    t.integer  "account_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "api_tokens", force: true do |t|
    t.string   "platform",          limit: 20
    t.integer  "account_id"
    t.string   "canvas_url"
    t.string   "api_user_email",    limit: 40
    t.string   "user_access_token"
    t.string   "page_access_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "countries", force: true do |t|
    t.string  "name",      limit: 60
    t.string  "code",      limit: 4
    t.boolean "is_active",            default: true
    t.integer "region_id"
  end

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "error_logs", force: true do |t|
    t.string   "message",    limit: 1024
    t.string   "subject",                 default: ""
    t.integer  "severity",   limit: 1
    t.boolean  "email_sent"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "facebooks", force: true do |t|
    t.string   "identifier",   limit: 20
    t.string   "access_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fb_pages", force: true do |t|
    t.integer  "account_id"
    t.string   "object_name",                          limit: 40
    t.integer  "total_likes"
    t.integer  "total_comments"
    t.integer  "total_shares"
    t.integer  "total_talking_about"
    t.integer  "likes"
    t.integer  "comments"
    t.integer  "shares"
    t.integer  "posts"
    t.integer  "replies_to_comment"
    t.integer  "fan_adds_day"
    t.integer  "story_adds_day"
    t.string   "story_adds_by_story_type_day"
    t.integer  "consumptions_day"
    t.string   "consumptions_by_consumption_type_day"
    t.integer  "stories_week"
    t.integer  "stories_day_28"
    t.string   "stories_by_story_type_week"
    t.datetime "post_created_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fb_pages", ["account_id"], name: "index_fb_pages_on_account_id", using: :btree
  add_index "fb_pages", ["post_created_time"], name: "index_fb_pages_on_post_created_time", using: :btree

  create_table "fb_posts", force: true do |t|
    t.integer  "account_id"
    t.string   "post_id",            limit: 40
    t.integer  "likes"
    t.integer  "comments"
    t.integer  "shares"
    t.string   "post_type",          limit: 20
    t.integer  "replies_to_comment"
    t.datetime "post_created_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "fb_posts", ["account_id"], name: "index_fb_posts_on_account_id", using: :btree
  add_index "fb_posts", ["post_created_time"], name: "index_fb_posts_on_post_created_time", using: :btree
  add_index "fb_posts", ["post_id"], name: "index_fb_posts_on_post_id", unique: true, using: :btree

  create_table "languages", force: true do |t|
    t.string  "name",      limit: 30
    t.string  "iso_639_1", limit: 6
    t.boolean "is_active",            default: true
  end

  create_table "media_types", force: true do |t|
    t.string   "name",       limit: 20
    t.boolean  "is_active",             default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "networks", force: true do |t|
    t.string   "name",        limit: 10
    t.string   "description"
    t.boolean  "is_active",              default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "records", force: true do |t|
    t.string   "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "region_reports", force: true do |t|
    t.integer  "region_id"
    t.datetime "date"
    t.integer  "facebook_count"
    t.integer  "twitter_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "region_reports", ["region_id"], name: "index_region_reports_on_region_id", using: :btree

  create_table "regions", force: true do |t|
    t.string  "name",       limit: 30
    t.boolean "is_active",             default: true
    t.string  "segment_id", limit: 30
  end

  create_table "roles", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.boolean  "is_active",   default: true
    t.integer  "weight"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sc_referral_traffic", force: true do |t|
    t.integer  "facebook_count"
    t.integer  "twitter_count"
    t.integer  "sc_segment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sc_segments", force: true do |t|
    t.string   "name"
    t.string   "sc_id"
    t.integer  "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "services", force: true do |t|
    t.string   "name",        limit: 40
    t.string   "description"
    t.string   "network_id"
    t.boolean  "is_active",              default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tw_timelines", force: true do |t|
    t.integer  "account_id"
    t.string   "object_name",      limit: 40
    t.integer  "total_tweets"
    t.integer  "total_favorites"
    t.integer  "total_followers"
    t.integer  "tweets"
    t.integer  "favorites"
    t.integer  "followers"
    t.integer  "retweets"
    t.integer  "mentions"
    t.datetime "tweet_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tw_timelines", ["account_id"], name: "index_tw_timelines_on_account_id", using: :btree
  add_index "tw_timelines", ["tweet_created_at"], name: "index_tw_timelines_on_tweet_created_at", using: :btree

  create_table "tw_tweets", force: true do |t|
    t.integer  "account_id"
    t.integer  "tweet_id",         limit: 8
    t.integer  "retweets"
    t.integer  "favorites"
    t.integer  "mentions"
    t.datetime "tweet_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tw_tweets", ["account_id"], name: "index_tw_tweets_on_account_id", using: :btree
  add_index "tw_tweets", ["tweet_created_at"], name: "index_tw_tweets_on_tweet_created_at", using: :btree
  add_index "tw_tweets", ["tweet_id"], name: "index_tw_tweets_on_tweet_id", using: :btree

  create_table "twitter_users", force: true do |t|
    t.string   "identifier",          limit: 20
    t.string   "access_token"
    t.string   "access_token_secret"
    t.text     "access_token_obj"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "email",                             default: "",   null: false
    t.string   "encrypted_password",                default: "",   null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                     default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "role_id"
    t.string   "firstname",              limit: 40
    t.string   "lastname",               limit: 60
    t.boolean  "is_active",                         default: true
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
