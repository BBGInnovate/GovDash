class Admin::BaseController < ApplicationController
  layout "regular"
  before_filter :authenticate_user!
#  before_filter :is_service_chief?
  
  protected
   
end
