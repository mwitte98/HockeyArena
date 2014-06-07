class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.integer :playerid
      t.string :name
      t.integer :age
      t.integer :ai
      t.integer :quality
      t.string :potential
      t.integer :stadium
      t.integer :goalie
      t.integer :defense
      t.integer :offense
      t.integer :shooting
      t.integer :passing
      t.integer :speed
      t.integer :strength
      t.integer :selfcontrol
      t.string :playertype
      t.integer :experience
      t.integer :games
      t.integer :minutes

      t.timestamps
    end
  end
end
