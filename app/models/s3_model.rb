class S3Model < Object
  attr_accessor :file_path_name
  # file_name = "facebook/voiceofamerica/insights/20140610.json"
  # no leading "/"
  def initialize
    connection!
  end
  
  def connection!
    AWS::S3::Base.establish_connection!(
      :access_key_id     => S3.config[:s3_credentials][:access_key_id],
      :secret_access_key => S3.config[:s3_credentials][:secret_access_key]
    )
  end
  
  def bucket
    @bucket ||= S3.config[:bucket]
  end
  
  def store(file_path, content)
    begin
    AWS::S3::S3Object.store(
      file_path,
      content,
      bucket,
      :content_type => 'text/json',:access => :public_read
    )
    rescue Exception=> e
      Account.logger.info "#{e.message}"
      Account.logger.info "#{e.backtrace}"
    end
    
    puts "#{file_path} Uploaded!"

  end
  
  def get_url(file_name)
    file_name = file_name.sub(/^\//, '')
    obj=AWS::S3::S3Object.find file_name, bucket
    obj.url 
  end
  
  def json_obj file_name
    str = AWS::S3::S3Object.value file_name, bucket
    json_obj = JSON.parse str
  end
  
  def download_insights(account)
    path = account.s3_filepath(date) + "insights.json"
    puts "Download from S3 #{path}. All dates are end date"
    
    results = []
    if account.since_date > 31.days.ago
      # since_date is within one month
      # get 1.month.ago insights.json file
      path1 = account.s3_filepath(date.months_ago(1)) + "insights.json"
      begin
        result2 = json_obj path1
        results << result2
      rescue
         puts "ERROR #{$!} - #{path1}"
      end
      
      begin
        result1 = json_obj path
        results << result1
      rescue
         puts "ERROR #{$!} - #{path}"
      end
    else
      begin
        result = json_obj path
        results << result
      rescue
        puts "ERROR #{$!} - #{path}"
      end
    end

    arrays = []
    results.each do |result|
      arr = []
      result.each do |a|
        if a['id'].match /page_fan_adds_unique\/day$/
         # adds_unique_day(a)
        
        elsif a['id'].match /overall\/day$/
          arr << overall_day(a)
        elsif a['id'].match /overall\/week$/
          arr << overall_week(a)
        elsif a['id'].match /overall\/month$/
          arr << overall_month(a)
        elsif a['id'].match /overall\/lifetime$/
          arr << overall_lifetime(a)
        elsif a['id'].match /page_fan_adds\/day$/
          arr << page_fan_adds_day(a)
       
        elsif a['id'].match /page_story_adds\/day$/
        arr << page_story_adds_day(a)
        
        elsif a['id'].match /page_story_adds_by_story_type\/day$/
          arr << page_story_adds_by_story_type_day(a)
        
        elsif a['id'].match /page_consumptions\/day$/
          arr << page_consumptions_day(a)
        
        elsif a['id'].match /page_consumptions_by_consumption_type\/day$/
        # arr << page_consumptions_by_consumption_type_day(a)
        
        elsif a['id'].match /page_stories\/week/
          arr << page_stories_week(a)
        
        elsif a['id'].match /page_stories_by_story_type\/week/
          arr << page_stories_by_story_type_week(a)
        
        elsif a['id'].match /page_fans\/lifetime/
          # page_fans a
        end
      end
      arrays << arr
    end
    show_raw ? results : merge_arrays(arrays)
  end
  
  
  private
  
  def convert(content)
    content = content.to_a
    arr = []
    content.each do |c|
      if c.kind_of? ActiveRecord::Base
        arr << c.attributes
      end
    end
    content
  end
  
end


