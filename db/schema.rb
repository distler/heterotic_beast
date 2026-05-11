# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_10_140000) do
  create_table "brain_busters", force: :cascade do |t|
    t.string "answer", limit: 255
    t.string "question", limit: 255
  end

  create_table "forums", force: :cascade do |t|
    t.string "description", limit: 255
    t.text "description_html"
    t.string "name", limit: 255
    t.string "permalink", limit: 255
    t.integer "position", default: 0
    t.integer "posts_count", default: 0
    t.integer "site_id"
    t.string "state", limit: 255, default: "public"
    t.integer "topics_count", default: 0
    t.index ["position", "site_id"], name: "index_forums_on_position_and_site_id"
    t.index ["site_id", "permalink"], name: "index_forums_on_site_id_and_permalink"
  end

  create_table "moderatorships", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "forum_id"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
  end

  create_table "monitorships", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil
    t.integer "topic_id"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
  end

  create_table "open_id_authentication_associations", force: :cascade do |t|
    t.string "assoc_type", limit: 255
    t.string "handle", limit: 255
    t.integer "issued"
    t.integer "lifetime"
    t.binary "secret"
    t.binary "server_url"
  end

  create_table "open_id_authentication_nonces", force: :cascade do |t|
    t.integer "created"
    t.string "nonce", limit: 255
  end

  create_table "open_id_authentication_settings", force: :cascade do |t|
    t.string "setting", limit: 255
    t.binary "value"
  end

  create_table "posts", force: :cascade do |t|
    t.text "body"
    t.text "body_html"
    t.datetime "created_at", precision: nil
    t.integer "forum_id"
    t.integer "site_id"
    t.integer "topic_id"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["created_at", "forum_id"], name: "index_posts_on_forum_id"
    t.index ["created_at", "topic_id"], name: "index_posts_on_topic_id"
    t.index ["created_at", "user_id"], name: "index_posts_on_user_id"
  end

  create_table "sites", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.text "description"
    t.string "host", limit: 255
    t.string "name", limit: 255
    t.integer "posts_count", default: 0
    t.text "tagline"
    t.integer "topics_count", default: 0
    t.datetime "updated_at", precision: nil
    t.integer "users_count", default: 0
  end

  create_table "topics", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "forum_id"
    t.integer "hits", default: 0
    t.integer "last_post_id"
    t.datetime "last_updated_at", precision: nil
    t.integer "last_user_id"
    t.boolean "locked", default: false
    t.string "permalink", limit: 255
    t.integer "posts_count", default: 0
    t.integer "site_id"
    t.integer "sticky", default: 0
    t.string "title", limit: 255
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["forum_id", "permalink"], name: "index_topics_on_forum_id_and_permalink"
    t.index ["last_updated_at", "forum_id"], name: "index_topics_on_forum_id_and_last_updated_at"
    t.index ["sticky", "last_updated_at", "forum_id"], name: "index_topics_on_sticky_and_last_updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "activated_at", precision: nil
    t.string "activation_code", limit: 40
    t.boolean "admin", default: false
    t.string "bio", limit: 255
    t.text "bio_html"
    t.datetime "created_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.string "display_name", limit: 255
    t.string "email", limit: 255
    t.datetime "last_login_at", precision: nil
    t.datetime "last_seen_at", precision: nil
    t.string "login", limit: 255
    t.string "openid_url", limit: 255
    t.string "password_digest"
    t.string "permalink", limit: 255
    t.integer "posts_count", default: 0
    t.string "remember_token", limit: 255
    t.datetime "remember_token_expires_at", precision: nil
    t.integer "site_id"
    t.string "state", limit: 255, default: "passive"
    t.datetime "updated_at", precision: nil
    t.string "website", limit: 255
    t.index ["last_seen_at"], name: "index_users_on_last_seen_at"
    t.index ["site_id", "permalink"], name: "index_site_users_on_permalink"
    t.index ["site_id", "posts_count"], name: "index_site_users_on_posts_count"
  end
end
