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

ActiveRecord::Schema.define(version: 20150725020310) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "players", force: :cascade do |t|
    t.integer  "playerid"
    t.string   "name"
    t.integer  "age"
    t.integer  "ai"
    t.integer  "quality"
    t.string   "potential"
    t.integer  "stadium"
    t.integer  "goalie"
    t.integer  "defense"
    t.integer  "offense"
    t.integer  "shooting"
    t.integer  "passing"
    t.integer  "speed"
    t.integer  "strength"
    t.integer  "selfcontrol"
    t.string   "playertype"
    t.integer  "experience"
    t.integer  "games"
    t.integer  "minutes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "password_digest"
    t.string   "remember_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["remember_token"], name: "index_users_on_remember_token", using: :btree

  create_table "youth_schools", force: :cascade do |t|
    t.string   "name"
    t.integer  "age"
    t.string   "quality"
    t.string   "potential"
    t.string   "talent"
    t.json     "ai"
    t.integer  "priority"
    t.string   "manager"
    t.string   "version"
    t.boolean  "draft"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
