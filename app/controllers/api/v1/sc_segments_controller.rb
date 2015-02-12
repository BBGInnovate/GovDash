class Api::V1::ScSegmentsController < Api::V1::BaseController
  before_filter :authenticate_user!
  before_filter :is_admin?

  #def index 
    #pretty_respond ScSegment.all.as_json and return
  #end
  
  
end
