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

ActiveRecord::Schema.define(version: 20180318172158) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "players", id: :serial, force: :cascade do |t|
    t.integer "playerid"
    t.string "name", limit: 255
    t.integer "age"
    t.integer "quality"
    t.string "potential", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "team"
    t.json "daily"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "email", limit: 255
    t.string "password_digest", limit: 255
    t.string "remember_token", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["remember_token"], name: "index_users_on_remember_token"
  end

  create_table "youth_schools", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "age"
    t.string "quality"
    t.string "potential"
    t.string "talent"
    t.json "ai"
    t.string "manager"
    t.string "version"
    t.boolean "draft"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
