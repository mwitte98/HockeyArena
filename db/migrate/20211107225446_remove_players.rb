class RemovePlayers < ActiveRecord::Migration[6.1]
  def change
    drop_table :players
  end
end
