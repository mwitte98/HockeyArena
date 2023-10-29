class YouthSchool
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  index({ version: 1, team: 1, draft: 1, playerid: 1 }, { unique: true })
  index({ updated_at: 1 }, { expire_after_seconds: 6_048_000 }) # 70 days
end
