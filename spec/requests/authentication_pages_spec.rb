require 'spec_helper'

describe "Authentication" do
  
  subject { page }

  describe "signin page" do
  	before { visit '/signin' }

  	it { should have_content('Sign in') }
  	it { should have_title('Sign in') }
  end

  describe "signin" do
  	before { visit '/signin' }

  	describe "with invalid information" do
  	  before { click_button "Sign in" }

  	  it { should have_title('Sign in') }
  	  it { should have_selector('div.alert.alert-danger') }

      describe "after visiting another page" do
        before { click_link "Home" }
        it { should_not have_selector('div.alert.alert-danger') }
      end
  	end

  	describe "with valid information" do
  	  let(:user) { FactoryGirl.create(:user) }
  	  before { sign_in(user) }

  	  it { should have_title('') }
      it { should have_link('Edit profile', href: edit_user_path(user)) }
  	  it { should have_link('Sign out', href: signout_path) }

      describe "followed by signout" do
        before { click_link "Sign out" }
        it { should_not have_link('Sign out') }
      end
  	end
  end

  describe "authorization" do
    
    describe "for non-signed-in users" do
      let(:user) { FactoryGirl.create(:user) }

      describe "in the Users controller" do

        describe "visiting the edit page" do
          before { visit edit_user_path(user) }
          it { should have_title('Hockey Arena') }
        end

        describe "submitting to the update action" do
          before { patch user_path(user) }
          specify { expect(response).to redirect_to(root_path) }
        end
      end
    end

    describe "as wrong user" do
      let(:user) { FactoryGirl.create(:user) }
      let(:wrong_user) { FactoryGirl.create(:user, email: "tyler.azevedo@gmail.com") }
      before { sign_in(user, no_capybara: true) }

      describe "submitting a GET request to the Users#edit action" do
        before { get edit_user_path(wrong_user) }
        specify { expect(response.body).not_to match('Edit user') }
        specify { expect(response).to redirect_to(root_url) }
      end

      describe "submitting a PATCH request to the Users#update action" do
        before { patch user_path(wrong_user) }
        specify { expect(response).to redirect_to(root_url) }
      end
    end
  end
end
