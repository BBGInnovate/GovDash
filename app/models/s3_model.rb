require 'aws-sdk'

=begin

key="hello"
obj = mybucket.object(key)
obj.put(body:'Hello World!')
obj.get.body.read
obj.delete

=end

class S3Model < Object
  attr_accessor :file_path_name
  def initialize
    Aws.config[:region] = 'us-east-1'
    client
  end
  
  def client
    Aws::S3::Client.new(
      access_key_id: config[:s3_credentials][:access_key_id],
      secret_access_key: config[:s3_credentials][:secret_access_key]
    )
  end
  
  def get file_path_name
    obj = get_object file_path_name
    if obj
      str = obj.get.body.read
      JSON.parse str
    else
     "{}"
    end
  end
  
  def store(file_path, content)
    obj = get_object file_path
    obj.put(body: content) if obj
  end

  def get_object file_path_name
    begin
      s3 = Aws::S3::Resource.new
      mybucket = s3.bucket(self.bucket_name)
      obj = mybucket.object(file_path_name)
    rescue
      nil
    end
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
        result2 = get path1
        results << result2
      rescue
         puts "ERROR #{$!} - #{path1}"
      end
      
      begin
        result1 = get path
        results << result1
      rescue
         puts "ERROR #{$!} - #{path}"
      end
    else
      begin
        result = get path
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
  
  protected
  
  def bucket_name
    @bucket_name ||= config[:bucket]
  end
  
  def config
    unless @config
      creds = "#{Rails.root}/config/s3.yml"
      res = YAML.load_file(creds)
      # Environment specific definitions override global definitions
      res1  = symbolize_keys(res.merge(res.delete(Rails.env)))
      # delete entries other then for current environment
      envs = [:development, :qa, :test, :staging, :production]
      envs.each{|e| res1.delete e}
      access_key_id = res1.delete(:access_key_id)
      secret_access_key = res1.delete(:secret_access_key)
      res1[:s3_credentials]={:access_key_id=>access_key_id, :secret_access_key=>secret_access_key}
      @config = symbolize_keys res1
    end
    @config
  end
  
  def symbolize_keys(hash)
    hash.inject({}){|res, (key, val)|
      nkey = case key
        when String
        key.to_sym
      else
        key
      end
      nval = case val
        when Hash, Array
        symbolize_keys(val)
      else
        val
      end
      res[nkey] = nval
      res
    }
  end
  
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
=begin
  def connection!
    AWS::S3::Base.establish_connection!(
      :access_key_id     => S3.config[:s3_credentials][:access_key_id],
      :secret_access_key => S3.config[:s3_credentials][:secret_access_key]
    )
  end
  
  def get_url(file_name)
    file_name = file_name.sub(/^\//, '')
    obj=Aws::S3::S3Object.find file_name, bucket
    obj.url 
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
=end



