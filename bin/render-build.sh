#!/usr/bin/env bash
# exit on error
set -o errexit

# Force Render's build tool to initialize Node completely right now
# This flushes out the "INTERNAL_RENDER_LOG!" text safely into this script
node -v

bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean
bin/rails db:mongoid:create_indexes
