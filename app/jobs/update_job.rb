class UpdateJob
  include SuckerPunch::Job

  def initialize
    session = GoogleDrive::Session.from_service_account_key(StringIO.new(ENV['client_secret']))
    @ws_u20_active = get_first_worksheet session, ENV['U20_20_key']
    @ws_u20_next = get_first_worksheet session, ENV['U20_18_key']
  end

  def perform
    update 'beta', 'a'
    update 'beta', 'b'
    update 'live', 'a'
    update 'live', 'b'
  end

  private

  def update(version, ab_team)
    State.version = version
    State.ab_team = ab_team

    if ab_team == 'a'
      @agent = Mechanize.new
      @agent.get(base_url)
      login_to_ha
    else
      @agent.get("#{base_url}index.php&p=sponsor_multiteam.inc&a=switch&team=2")
    end
    return if login_failed?

    run_updates ab_team
  end

  def base_url
    prefix = State.version == 'live' ? 'www' : 'beta'
    "http://#{prefix}.hockeyarena.net/en/"
  end

  def login_to_ha
    @agent.get(base_url)
    form = @agent.page.forms.first
    form.nick = 'speedysportwhiz'
    form.password = State.version == 'live' ? ENV['HA_password'] : ENV['beta_password']
    form.submit
  end

  def login_failed?
    sleep 1
    content = @agent.page.content
    if content.include?('Continue') || content.include?('Sign into the game')
      puts "*****Login to HA failed for #{State.version}*****"
      puts content
      return true
    end
    false
  end

  def run_updates(ab_team)
    UpdateYS.run @agent, ab_team
    return unless State.version == 'live' && State.ab_team == 'a'

    UpdateNT.run @agent, @ws_u20_active, ENV['U20_20_seasons']
    UpdateNT.run @agent, @ws_u20_next, ENV['U20_18_seasons']
  end

  def get_first_worksheet(session, key)
    session.spreadsheet_by_key(key).worksheets[0]
  end
end
