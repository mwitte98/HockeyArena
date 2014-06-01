require 'spec_helper'

describe "User pages" do

  subject { page }

  describe "Signup page" do
    before { visit signup_path }

    it { should have_content('Sign Up') }
    it { should have_title('Sign Up') }

    let(:submit) { "Create my account" }

    describe "with invalid information" do
      it "should not create a user" do
        expect { click_button submit }.not_to change(User, :count)
      end
    end

    describe "with valid information" do
      before do
        fill_in "Name",         with: "Example User"
        fill_in "Email",        with: "mcw9612@rit.edu"
        fill_in "Password",     with: "foobar"
        fill_in "Confirmation", with: "foobar"
      end

      it "should create a user" do
        expect { click_button submit }.to change(User, :count).by(1)
      end

      describe "after saving the user" do
        before { click_button submit }
        let(:user) { User.find_by(email: 'mcw9612@rit.edu') }

        it { should have_link('Sign out') }
        it { should have_title('') }
        it { should have_selector('div.alert.alert-success', text: 'Successful') }

        describe "followed by signout" do
          before { click_link "Sign out" }
          it { should_not have_link('Sign out') }
        end
      end
    end
  end

  describe "edit" do
    let(:user) { FactoryGirl.create(:user) }
    before do
      sign_in(user)
      visit edit_user_path(user)
    end

    describe "page" do
      it { should have_content("Update your profile") }
      it { should have_title("Edit user") }
    end

    describe "with invalid information" do
      before { click_button "Save changes" }

      it { should have_content('error') }
    end

    describe "with valid information" do
      let(:new_name) { "New Name" }
      before do
        fill_in "Name", with: new_name
        fill_in "Email", with: user.email
        fill_in "Password", with: user.password
        fill_in "Confirm Password", with: user.password
        click_button "Save changes"
      end

      it { should have_selector('div.alert.alert-success') }
      it { should have_link('Sign out', href: signout_path) }
      specify { expect(user.reload.name).to eq new_name }
    end
  end
end