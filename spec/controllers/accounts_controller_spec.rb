require 'spec_helper'

describe AccountsController do

  describe "GET 'imtesting'" do
    it "returns http success" do
      get 'imtesting'
      response.should be_success
    end
  end

end
