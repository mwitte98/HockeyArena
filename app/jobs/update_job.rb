class UpdateJob
  include SuckerPunch::Job

  def initialize
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(ENV['client_secret']))
    @ws_u20_active = get_first_worksheet session, ENV['U20_20_key']
    @ws_u20_next = get_first_worksheet session, ENV['U20_18_key']
    @ws_sr = get_first_worksheet session, ENV['NT_key']
  end

  def perform
    update 'speedysportwhiz', 'beta', 'a'
    update 'speedysportwhiz', 'beta', 'b'
    update 'speedysportwhiz', 'live', 'a'
    update 'speedysportwhiz', 'live', 'b'
    update 'magicspeedo', 'live', 'a'
    update 'magicspeedo', 'live', 'b'
  end

  private

  def update(manager, version, ab_team)
    State.manager = manager
    State.version = version
    State.ab_team = ab_team

    if ab_team == 'a'
      @agent = Mechanize.new
      @agent.get(base_url)
      login_to_ha
    else
      @agent.get(base_url + 'index.php&p=sponsor_multiteam.inc&a=switch&team=2')
    end
    return if login_failed?

    run_updates ab_team
  end

  def base_url
    prefix = State.version == 'live' ? 'www' : 'beta'
    'http://' + prefix + '.hockeyarena.net/en/'
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
    if content.include?('Continue') || content.include?('Sign into the game')
      puts "*****Login to HA failed for #{State.manager} #{State.version}*****"
      puts content
      return true
    end
    false
  end

  def run_updates(ab_team)
    UpdateYS.run @agent, ab_team
    return unless State.version == 'live'

    UpdateNT.run @agent, @ws_u20_active, ENV['U20_20_seasons']
    UpdateNT.run @agent, @ws_u20_next, ENV['U20_18_seasons']
    UpdateNT.run @agent, @ws_sr, 'senior'
  end

  def get_first_worksheet(session, key)
    session.spreadsheet_by_key(key).worksheets[0]
  end
end
