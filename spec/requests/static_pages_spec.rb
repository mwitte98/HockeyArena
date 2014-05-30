require 'spec_helper'

describe "Static pages" do

  describe "Home page" do
  	before { visit root_path }

    it "should have the content 'Hockey Arena'" do
      expect(page).to have_content('Hockey Arena')
    end

    it "should have the title 'Hockey Arena'" do
      expect(page).to have_title('Hockey Arena')
    end
  end
end