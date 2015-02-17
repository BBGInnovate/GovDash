class Api::V1::FacebooksController < Api::V1::BaseController
  skip_before_filter :authenticate_user!
  #before_filter :is_analyst?

  def index
    @fb_object_name = nil
    @from_date = Time.now
    @to_date = @from_date
    @show_raw = params[:raw]
    arr = params[:path].split('/')
    upload = (arr[0] == 'upload')
    download = (arr[0] == 'download')
    if upload
      @fb_object_name = arr[1]
      process_s3
    elsif download
      @fb_object_name = arr[1]
      @from_date = Time.parse(arr[2]) if arr[2]
      get_s3_insights @from_date
    elsif arr.size == 2
      @fb_object_name = arr[0]
      @from_date = Time.parse arr[1]
      @to_date = @from_date
      get_stats
    elsif arr.size == 3
      @fb_object_name = arr[0]
      @from_date = Time.parse arr[1]
      @to_date = Time.parse arr[2]
      get_stats
    else
      raise "Incorrect URL params #{params[:path]} "
    end

  end
  
  
  private
  
  def get_s3_insights(date=Time.now)
    u = Account.find_by_object_name @fb_object_name
    arr = []
    if FacebookAccount===u
      u.show_raw = @show_raw
      arr = u.download_insights(date)
    end
    pretty_respond arr and return
  end
  
  def process_s3
    u = Account.find_by_object_name @fb_object_name
    arr = []
    if FacebookAccount===u
      file_path = "facebook/#{Time.now.strftime("%d%b%y")}/user/#{@fb_object_name}/insights.json"
      arr = ["Insights for #{@fb_object_name} uploaded to S3 #{file_path}"]
      u.upload_insights
      data = u.insights
      data.each do |d|
        arr << d
      end
      pretty_respond arr and return
    else
      pretty_respond ["#{@fb_object_name} not found"]
    end
  end
  
  def get_stats
    @account = Account.find_by_object_name @fb_object_name
    arr = ["#{@account.object_name}"]
    arr << "#{@from_date.strftime('%Y-%m-%d')} - #{@to_date.strftime('%Y-%m-%d')}"
    if @account
      if @from_date && @to_date
        data = selection(@from_date.beginning_of_day, @to_date.end_of_day)
        attributes = data.attributes.slice('likes','shares','comments','posts')
        arr << attributes
      end 
    end
    pretty_respond arr and return
  end
  
  def selection(beginning_of_day,end_of_day)
   data = @account.fb_pages.select("sum(posts) as posts,sum(likes) as likes, sum(comments) as comments, sum(shares) as shares").
      where("post_created_time BETWEEN '#{beginning_of_day}' AND '#{end_of_day}' ").first
  end
  
end
