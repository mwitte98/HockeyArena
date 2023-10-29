class UpdateJob
  include SuckerPunch::Job

  def perform
    puts 'Starting update of YouthSchool data'
    %w[beta live].each do |version|
      @version = version
      %w[a b].each do |ab_team|
        @ab_team = ab_team
        update
      end
    end
    puts 'Finished update of YouthSchool data'
  end

  private

  def update
    if @ab_team == 'a'
      @agent = Mechanize.new
      login_to_ha
    else
      @agent.get("#{base_url}index.php&p=sponsor_multiteam.inc&a=switch&team=2")
    end
    return if login_failed?

    go_to_ys_page
    update_ys false # update ys
    update_ys true # update draft
  end

  def base_url
    prefix = @version == 'live' ? 'www' : 'beta'
    "http://#{prefix}.hockeyarena.net/en/"
  end

  def login_to_ha
    @agent.get("#{base_url}login")
    form = @agent.page.forms.first
    form.nick = 'speedysportwhiz'
    form.password = @version == 'live' ? ENV.fetch('HA_password') : ENV.fetch('beta_password')
    form.submit
  end

  def login_failed?
    sleep 1
    content = @agent.page.content
    if content.include?('Sign into the game') || content.include?('We are performing maintenance on the servers')
      puts "*****Login to HA failed for #{@version}*****"
      puts content
      return true
    end
    false
  end

  def go_to_ys_page
    prefix = @version == 'live' ? 'www' : 'beta'
    @agent.get("http://#{prefix}.hockeyarena.net/en/index.php?p=manager_youth_school_form.php")
  end

  def update_ys(is_draft)
    @is_draft = is_draft

    # get data from page
    players = scrape_ys_players

    # add current ai to db
    update_db players
  end

  def scrape_ys_players
    search_string = @is_draft ? '#table-3 tbody tr, #table-2 tbody tr' : '#table-1 tbody tr'

    @agent.page.search(search_string).map do |player|
      id = get_id player
      attributes = player.children.map(&:text).map { |text| text.tr("\u00A0", '') }.map(&:strip).reject(&:blank?)
      [id] + attributes
    end
  end

  def get_id(player)
    children = player.children.select { |child| child.instance_of?(Nokogiri::XML::Element) }
    children.last.children.first.get_attribute 'id'
  end

  def update_db(players)
    players.each do |player|
      ys_player = find_ys_player player[0]
      if ys_player.nil?
        create_ys_player player
      else
        update_ys_player player, ys_player
      end
    end
  end

  def find_ys_player(id)
    YouthSchool.find_by(playerid: id, version: @version, draft: @is_draft, team: @ab_team)
  end

  def create_ys_player(player)
    YouthSchool.create!(
      playerid: player[0], name: player[1], age: player[2].to_i, quality: player[3],
      potential: player[4], talent: player[5], ai: { Time.zone.now.to_s => player[6].to_i },
      version: @version, draft: @is_draft, team: @ab_team)
  end

  def update_ys_player(player, ys_player)
    ai_hash = ys_player['ai']
    ai_hash[Time.zone.now.to_s] = player[6].to_i
    ys_player.update(
      name: player[1], age: player[2].to_i, quality: player[3], potential: player[4], talent: player[5], ai: ai_hash)
  end
end
