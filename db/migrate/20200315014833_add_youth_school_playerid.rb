class AddYouthSchoolPlayerid < ActiveRecord::Migration[6.0]
  def change
    add_column :youth_schools, :playerid, :string
  end
end
