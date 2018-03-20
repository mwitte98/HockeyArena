class AddYouthSchoolTeam < ActiveRecord::Migration[5.1]
  def change
    add_column :youth_schools, :team, :string

    YouthSchool.all.each do |player|
      player.update(team: 'a')
    end
  end
end
