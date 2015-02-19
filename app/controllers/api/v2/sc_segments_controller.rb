class Api::V2::ScSegmentsController < Api::V2::BaseController
  before_filter :authenticate_user!
  before_filter :is_admin?

  #def index 
    #pretty_respond ScSegment.all.as_json and return
  #end
  
  
end
