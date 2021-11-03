class RemoveYouthSchoolManager < ActiveRecord::Migration[6.1]
  def change
    remove_column :youth_schools, :manager
  end
end
