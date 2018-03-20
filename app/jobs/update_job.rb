class UpdateJob
  include SuckerPunch::Job

  def initialize
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(ENV['client_secret']))
    @ws_u20_active = get_first_worksheet session, ENV['U20_20_key']
    @ws_u20_next = get_first_worksheet session, ENV['U20_18_key']
    @ws_sr = get_first_worksheet session, ENV['NT_key']
  end

  def perform
    update 'speedysportwhiz', 'live', 'a'
    update 'speedysportwhiz', 'live', 'b'
    update 'magicspeedo', 'live', 'a'
    update 'magicspeedo', 'live', 'b'
    update 'speedysportwhiz', 'beta', 'a'
    update 'speedysportwhiz', 'beta', 'b'
    update 'magicspeedo', 'beta', 'a'
    update 'magicspeedo', 'beta', 'b'
  end

  private

  def update(manager, version, team)
    State.manager = manager
    State.version = version
    if team == 'a'
      go_to_homepage
      return if login_failed?
    else
      switch_teams
    end
    run_updates team
  end

  def go_to_homepage
    @agent = Mechanize.new
    prefix = State.version == 'live' ? 'www' : 'beta'
    @agent.get('http://' + prefix + '.hockeyarena.net/en/')
    login_to_ha
  end

  def switch_teams
    prefix = State.version == 'live' ? 'www' : 'beta'
    @agent.get(
      'http://' + prefix + '.hockeyarena.net/en/index.php&p=sponsor_multiteam.inc&a=switch&team=2')
  end

  def login_to_ha
    form = @agent.page.forms.first
    form.nick = State.manager
    form.password = State.version == 'live' ? ENV['HA_password'] : ENV['beta_password']
    form.submit
  end

  def login_failed?
    sleep 1
    content = @agent.page.content
    if content.include?('Continue')
      puts "*****Login to HA failed for #{State.manager} #{State.version}*****"
      puts content
      return true
    end
    false
  end

  def run_updates(team)
    if State.version == 'live' && team == 'a'
      UpdateNT.run @agent, @ws_u20_active, ENV['U20_20_seasons']
      UpdateNT.run @agent, @ws_u20_next, ENV['U20_18_seasons']
      UpdateNT.run @agent, @ws_sr, 'senior'
    end
    UpdateYS.run @agent, team
  end

  def get_first_worksheet(session, key)
    session.spreadsheet_by_key(key).worksheets[0]
  end
end
