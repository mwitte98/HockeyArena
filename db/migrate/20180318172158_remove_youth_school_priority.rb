class RemoveYouthSchoolPriority < ActiveRecord::Migration[5.1]
  def change
    remove_column :youth_schools, :priority
  end
end
