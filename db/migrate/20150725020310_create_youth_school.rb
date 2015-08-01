class CreateYouthSchool < ActiveRecord::Migration
  def change
    create_table :youth_schools do |t|
      t.string :name
      t.integer :age
      t.string :quality
      t.string :potential
      t.string :talent
      t.json :ai
      t.integer :priority
      t.string :manager
      t.string :version
      t.boolean :draft

      t.timestamps
    end
  end
end
