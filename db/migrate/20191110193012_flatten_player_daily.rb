class FlattenPlayerDaily < ActiveRecord::Migration[6.0]
  def change
    add_column :players, :playertype, :string

    Player.all.each do |player|
      daily = player.daily
      playertype = daily[daily.keys[-1]]['playertype']
      daily_flattened = daily.map do |k,v|
        [k, [v['ai'], v['stadium'], v['goalie'], v['defense'], v['offense'], v['shooting'], v['passing'], v['speed'], v['strength'], v['selfcontrol'], v['experience'], v['games'], v['minutes']]]
      end
      player.update(playertype: playertype, daily: daily_flattened.to_h)
    end
  end
end
