include ApplicationHelper

def sign_in(user, options={})
  if options[:no_capybara]
  	# Sign in when not using no_capybara
  	remember_token = User.new_remember_token
  	cookies[:remember_token] = remember_token
  	user.remember_token = User.encrypt(remember_token)
    user.save
  else
  	visit signin_path
  	fill_in "Email", with: user.email
  	fill_in "Password", with: user.password
  	click_button "Sign in"
  end
end