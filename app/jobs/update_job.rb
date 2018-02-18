class UpdateJob
  include SuckerPunch::Job

  def initialize
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(ENV['client_secret']))
    @ws_u20_active = initialize_worksheet session, ENV['U20_20_key'], ENV['U20_20_seasons']
    @ws_u20_next = initialize_worksheet session, ENV['U20_18_key'], ENV['U20_18_seasons']
    @ws_sr = initialize_worksheet session, ENV['NT_key'], 'senior'
  end

  def perform
    update 'speedysportwhiz', 'live'
    update 'magicspeedo', 'live'
    update 'speedysportwhiz', 'beta'
    update 'magicspeedo', 'beta'
  end

  private

  def update(mgr, version)
    # Login to HA
    login_to_ha mgr, version

    page = @agent.page
    if page.content.include?('Continue')
      puts "*****Login #{login_attempt} to HA failed for #{mgr} #{version}*****"
      page.search('#page').each { |info| puts info.text }
      return
    end

    if version == 'live'
      update_national_team @ws_u20_active, mgr
      update_national_team @ws_u20_next, mgr
      update_national_team @ws_sr, mgr
    end
    update_ys mgr, version, false
    update_ys mgr, version, true
  end

  def login_to_ha(mgr, version)
    is_version_live = version == 'live'
    @agent = Mechanize.new
    @agent.get(is_version_live ? 'http://www.hockeyarena.net/en/' : 'http://beta.hockeyarena.net/en/')
    form = @agent.page.forms.first
    form.nick = mgr
    form.password = is_version_live ? ENV['HA_password'] : ENV['beta_password']
    form.submit
    sleep 1
  end

  def update_national_team(ws, mgr)
    # Update team
    ws.manager = mgr
    (2..ws.ws.num_rows).each do |row_num|
      next unless ws.update_row?(row_num)
      begin
        update_player(ws, mgr)
      rescue Nokogiri::XML::XPath::SyntaxError
        redo
      end
    end
  end

  def update_player(ws, mgr)
    id = ws.id

    # don't update if there's no id
    return if id == ''

    # mark player as deleted if he doesn't exist anymore
    @agent.get("http://www.hockeyarena.net/en/index.php?p=public_player_info.inc&id=#{id}")
    page = @agent.page
    if page.content.include? 'Player does not exist or has retired !'
      ws.mark_player_as_deleted
      return
    end

    # update player attributes and click on team name link
    update_nt_player_attributes ws, mgr

    # go to player's team's stadium page
    team_id = @agent.current_page.uri.to_s[77..-1]
    @agent.get(
      "http://www.hockeyarena.net/en/index.php?p=public_team_info_stadium.php&team_id=#{team_id}"
    )

    # update player's team stadium
    update_nt_player_stadium ws

    # create or update player in db
    update_nt_player_in_db ws

    begin
      ws.ws.synchronize # save and reload
    rescue GoogleDrive::Error
      puts "**********GOOGLE DRIVE ERROR SYNCING: #{ws.name}**********"
    end
  end

  def update_ys(mgr, version, is_draft)
    # Update youth school
    if version == 'live'
      @agent.get('http://www.hockeyarena.net/en/index.php?p=manager_youth_school_form.php')
    else
      @agent.get('http://beta.hockeyarena.net/en/index.php?p=manager_youth_school_form.php')
    end

    if is_draft
      # don't update if draft and draft has happened
      return if @agent.page.search('#table-2 .thead td').size > 8
      search_string = '#table-2 tbody .center , #table-2 tbody .left , ' \
                      '#table-3 tbody .center , #table-3 tbody .left'
    else
      search_string = '#table-1 tbody td'
    end

    players = get_ys_players is_draft, search_string

    params = { players: players, mgr: mgr, version: version, is_draft: is_draft }

    remove_deleted_ys_players params

    # Add new day to db
    update_ys_player_in_db params
  end

  def update_nt_player_attributes(ws, mgr)
    page = @agent.page
    player_attributes = []
    page.search('.q1, .q').each { |player_attribute| player_attributes << player_attribute.text }
    player_attributes[3] = mgr
    player = NtPlayer.new(player_attributes)

    ws.update_row player

    player_team = player_attributes[5]
    page.link_with(text: player_team).click
  end

  def update_nt_player_stadium(ws)
    stadium_attributes = []
    @agent.page.search('.sr1 .yspscores').each { |area| stadium_attributes << area.text.strip }

    # stadium training
    stadium_training = stadium_attributes[3]
    ws.stadium = stadium_training[0] == '0' ? 0 : stadium_training[0..2]
  end

  def update_nt_player_in_db(ws)
    player_name = ws.name
    id = ws.id
    team = ws.team
    player_hash = ws.player_hash
    player_age = ws.age
    quality = ws.quality
    potential = ws.potential
    nt_player = Player.find_by(name: player_name, team: team)
    datetime = Time.now.in_time_zone('Eastern Time (US & Canada)')
    if nt_player.nil?
      Player.create!(playerid: id, name: player_name, age: player_age, quality: quality,
                     potential: potential, team: team, daily: { datetime => player_hash })
    else
      ai_hash = nt_player['daily']
      ai_hash[datetime] = player_hash
      nt_player.update(age: player_age, quality: quality, potential: potential, daily: ai_hash)
    end
  end

  def get_ys_players(is_draft, search_string)
    players = []
    player_attributes = []
    count = 0

    # pull ys info from site
    @agent.page.search(search_string).each do |player_attribute|
      count += 1
      if count < 7
        stripped_text = player_attribute.text.strip
        player_attributes << (count == 2 || count == 5 ? stripped_text : stripped_text[1..-1])
      elsif end_of_ys_row?(is_draft, count)
        players << player_attributes
        player_attributes = []
        count = 0
      end
    end

    players
  end

  def end_of_ys_row?(is_draft, count)
    (!is_draft && count == 9) || (is_draft && count == 8)
  end

  def remove_deleted_ys_players(params)
    mgr = params[:mgr]
    version = params[:version]
    is_draft = params[:is_draft]
    names = []
    params[:players].each { |player| names << player[0] }

    # Names of all players that have been tracked
    names_in_db = []
    players_in_db = YouthSchool.where(manager: mgr, version: version, draft: is_draft)
    players_in_db.each { |player| names_in_db << player['name'] }

    # Delete players from db that have been deleted on HA
    names_in_db.each do |name|
      unless names.include?(name)
        YouthSchool.find_by(name: name, manager: mgr, version: version, draft: is_draft).delete
      end
    end
  end

  def update_ys_player_in_db(params)
    mgr = params[:mgr]
    version = params[:version]
    is_draft = params[:is_draft]
    player_priority = 1
    params[:players].each do |player|
      name = player[0]
      ys_player = YouthSchool.find_by(name: name, manager: mgr, version: version, draft: is_draft)
      if ys_player.nil?
        YouthSchool.create!(name: name, age: player[1], quality: player[2],
                            potential: player[3], talent: player[4],
                            ai: {
                              Time.now.in_time_zone('Eastern Time (US & Canada)') => player[5]
                            },
                            priority: player_priority, manager: mgr,
                            version: version, draft: is_draft)
      else
        update_ys_player(player, ys_player, player_priority)
      end
      player_priority += 1
    end
  end

  def update_ys_player(player, ys_player, player_priority)
    ai_hash = ys_player['ai']
    datetime = Time.now.in_time_zone('Eastern Time (US & Canada)')
    ai_hash[datetime] = player[5]
    ys_player.update(age: player[1], quality: player[2], potential: player[3],
                     talent: player[4], ai: ai_hash, priority: player_priority)
  end

  def initialize_worksheet(session, key, team)
    Worksheet.new(ws: session.spreadsheet_by_key(key).worksheets[0], team: team)
  end
end
