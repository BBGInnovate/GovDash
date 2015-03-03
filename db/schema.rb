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

ActiveRecord::Schema.define(version: 20150302175811) do

  create_table "account_types", force: :cascade do |t|
    t.string   "name",       limit: 20
    t.boolean  "is_active",  limit: 1,  default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "accounts", force: :cascade do |t|
    t.string   "name",              limit: 40
    t.string   "description",       limit: 255
    t.string   "object_name",       limit: 40
    t.boolean  "status",            limit: 1,   default: true
    t.boolean  "page_admin",        limit: 1,   default: false
    t.string   "media_type_name",   limit: 20,  default: "FacebookAccount"
    t.integer  "group_id",          limit: 4
    t.integer  "service_id",        limit: 4
    t.integer  "account_type_id",   limit: 4
    t.integer  "language_id",       limit: 4
    t.string   "contact",           limit: 255
    t.string   "user_access_token", limit: 255
    t.boolean  "is_active",         limit: 1,   default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sc_segment_id",     limit: 4
    t.boolean  "new_item",          limit: 1,   default: false
  end

  add_index "accounts", ["group_id"], name: "index_accounts_on_group_id", using: :btree

  create_table "accounts_countries", force: :cascade do |t|
    t.integer  "account_id", limit: 4
    t.integer  "country_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "accounts_languages", force: :cascade do |t|
    t.integer  "account_id",  limit: 4
    t.integer  "language_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "accounts_regions", force: :cascade do |t|
    t.integer  "account_id", limit: 4
    t.integer  "region_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "accounts_sc_segments", id: false, force: :cascade do |t|
    t.integer "sc_segment_id", limit: 4
    t.integer "account_id",    limit: 4
    t.boolean "new_item",      limit: 1, default: false
  end

  add_index "accounts_sc_segments", ["sc_segment_id", "account_id"], name: "index_accounts_sc_segments_on_sc_segment_id_and_account_id", using: :btree

  create_table "accounts_users", force: :cascade do |t|
    t.integer  "account_id", limit: 4
    t.integer  "user_id",    limit: 4
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

  create_table "countries", force: :cascade do |t|
    t.string  "name",      limit: 60
    t.string  "code",      limit: 4
    t.boolean "is_active", limit: 1,  default: true
    t.integer "region_id", limit: 4
  end

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

  create_table "groups", force: :cascade do |t|
    t.string   "name",            limit: 128
    t.string   "description",     limit: 255
    t.boolean  "is_active",       limit: 1,   default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id", limit: 4
  end

  add_index "groups", ["organization_id"], name: "index_groups_on_organization_id", using: :btree

  create_table "languages", force: :cascade do |t|
    t.string  "name",      limit: 30
    t.string  "iso_639_1", limit: 6
    t.boolean "is_active", limit: 1,  default: true
  end

  create_table "media_types", force: :cascade do |t|
    t.string   "name",       limit: 20
    t.boolean  "is_active",  limit: 1,  default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "organizations", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

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
    t.string  "name",       limit: 30
    t.boolean "is_active",  limit: 1,  default: true
    t.string  "segment_id", limit: 30
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "description", limit: 255
    t.boolean  "is_active",   limit: 1,   default: true
    t.integer  "weight",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sc_referral_traffic", force: :cascade do |t|
    t.integer  "facebook_count", limit: 4
    t.integer  "twitter_count",  limit: 4
    t.integer  "sc_segment_id",  limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sc_segments", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "sc_id",      limit: 255
    t.integer  "account_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "services", force: :cascade do |t|
    t.string   "name",        limit: 40
    t.string   "description", limit: 255
    t.string   "network_id",  limit: 255
    t.boolean  "is_active",   limit: 1,   default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

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
    t.string   "email",                  limit: 255, default: "",   null: false
    t.string   "encrypted_password",     limit: 255, default: "",   null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "role_id",                limit: 4
    t.string   "firstname",              limit: 40
    t.string   "lastname",               limit: 60
    t.boolean  "is_active",              limit: 1,   default: true
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "yt_channels", force: :cascade do |t|
    t.integer  "account_id",   limit: 4
    t.string   "channel_id",   limit: 255
    t.integer  "views",        limit: 4
    t.integer  "comments",     limit: 4
    t.integer  "videos",       limit: 4
    t.integer  "subscribers",  limit: 4
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "yt_channels", ["account_id"], name: "index_yt_channels_on_account_id", using: :btree
  add_index "yt_channels", ["channel_id"], name: "index_yt_channels_on_channel_id", using: :btree
  add_index "yt_channels", ["published_at"], name: "index_yt_channels_on_published_at", using: :btree

  create_table "yt_videos", force: :cascade do |t|
    t.integer  "account_id",   limit: 4
    t.string   "channel_id",   limit: 255
    t.string   "video_id",     limit: 40
    t.integer  "likes",        limit: 4
    t.integer  "comments",     limit: 4
    t.integer  "favorites",    limit: 4
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "yt_videos", ["account_id"], name: "index_yt_videos_on_account_id", using: :btree
  add_index "yt_videos", ["channel_id"], name: "index_yt_videos_on_channel_id", using: :btree
  add_index "yt_videos", ["published_at"], name: "index_yt_videos_on_published_at", using: :btree
  add_index "yt_videos", ["video_id"], name: "index_yt_videos_on_video_id", unique: true, using: :btree

  add_foreign_key "groups", "organizations"
end
