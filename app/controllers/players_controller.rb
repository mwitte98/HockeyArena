class PlayersController < ApplicationController
  before_action :signed_in_user

  def show5354
    @players = Player.order("ai DESC").all(:conditions => ["age != ?", 17])
  end

  def show5556
    @players = Player.order("ai DESC").all(:conditions => ["age = ?", 17])
  end

  def get_info
    agent = Mechanize.new
    agent.get("http://www.hockeyarena.net/en/")

    form = agent.page.forms.first
    form.nick = ENV['nick']
    form.password = ENV['password']
    form.submit

    agent.get("http://www.hockeyarena.net/en/index.php?p=national_players.php")

    @player_names = []
    agent.page.search("#table-2 img+ a").each do |item|
      @player_names << item.text.strip
    end

    @player_names.each do |player_name|
      agent.page.link_with(:text => player_name).click
      playerid = agent.page.search(".stats:nth-child(4) th").first.text.strip[-8..-1]

      player_info = []
      agent.page.search(".q").each do |info|
        player_info << info.text.strip
      end

      age = player_info[0]
      ai = player_info[8]
      goalie = player_info[14]
      defense = player_info[16]
      offense = player_info[18]
      shooting = player_info[20]
      passing = player_info[22]
      speed = player_info[15]
      strength = player_info[17]
      selfcontrol = player_info[19]
      experience = player_info[23]

      if player_info[3] == "RIT Tigers"
        games = player_info[32]
        minutes = player_info[34]
      else
        games = player_info[29]
        minutes = player_info[31]
      end

      agent.page.link_with(:text => player_info[3]).click
      teamid = agent.page.uri.to_s[77..-1]
      agent.get("http://www.hockeyarena.net/en/index.php?p=public_team_info_stadium.php&team_id=#{teamid}")
      stadium_info = []
      agent.page.search(".sr1 .yspscores").each do |info|
        stadium_info << info.text.strip
      end
      stadium = stadium_info[3][0..2]

      newplayer = Player.create!(playerid: playerid, name: player_name, age: age, ai: ai, quality: 0, potential: "0", stadium: stadium,
        goalie: goalie, defense: defense, offense: offense, shooting: shooting, passing: passing, speed: speed, strength: strength,
        selfcontrol: selfcontrol, playertype: "none", experience: experience, games: games, minutes: minutes)
      agent.get("http://www.hockeyarena.net/en/index.php?p=national_players.php")
    end

    redirect_to players5354_path
  end

  private

    def signed_in_user
      unless signed_in?
        flash[:warning] = "You must be signed in to access that page."
        redirect_to root_url
      end
    end

end
