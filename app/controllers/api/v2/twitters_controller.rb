class Api::V2::TwittersController < Api::V2::BaseController
  skip_before_filter :authenticate_user!
  #before_filter :is_analyst?

  def index
    
    @show_raw = params[:raw]
    arr = params[:path].split('/')
   
    is_show = (arr[0] == 'show')
    is_timeline = (arr[0] == 'timeline')
    
    @tw_object_name = arr[1]
    @from_date = arr[2] ? Time.parse(arr[2]) : Time.zone.now
    
    if is_show
      get_s3_show @from_date
    elsif is_timeline
      get_s3_timeline @from_date
    else
      raise "Incorrect URL params #{params[:path]} "
    end
  end

  
  private
  
  def get_s3_show(date=Time.zone.now)
    u = Account.find_by_object_name @tw_object_name
    hsh = {}
    if TwitterAccount===u
      u.show_raw = @show_raw
      hsh = u.s3_show(date)
    end
    pretty_respond hsh and return
  end
  
  def get_s3_timeline(date=Time.zone.now)
    u = Account.find_by_object_name @tw_object_name
    arr = []
    if TwitterAccount===u
      u.show_raw = @show_raw
      arr = u.s3_timeline(date)
    end
    pretty_respond arr and return
  end
  
end
