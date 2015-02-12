class Api::V1::TwittersController < Api::V1::BaseController
  skip_before_filter :authenticate_user!
  #before_filter :is_analyst?

  # api/facebook/s3/voiceofamerica
  # api/twitter/show/VOA_News
  # api/twitter/show/VOA_News/2014-06-20
  # api/twitter/timeline/VOA_News
  # api/twitter/timeline/VOA_News/2014-08-18
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
      # c = File.read("#{Rails.root}/show.json")
      # c = JSON.parse c
      # c=c[0]
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
