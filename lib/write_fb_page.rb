module WriteFbPage

  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
  end # module ClassMethods

  # instance methods below
  
  def parse_insights date=Time.now
    results = insights
    begin
      unless results
        path = s3_filepath(date) + "insights.json"
        results = S3Model.new.json_obj path
      end
    rescue Exceptio=>error
      logger.error "Error #{error.message} - #{path}"
    end

    results.each do |a|
        if a['id'].match /page_fan_adds_unique\/day$/
         # adds_unique_day_create(a)
        elsif a['id'].match /page_fan_adds\/day$/
          page_fan_adds_day_create(a)
        elsif a['id'].match /page_story_adds\/day$/
          page_story_adds_day_create(a)
        elsif a['id'].match /page_story_adds_by_story_type\/day$/
          page_story_adds_by_story_type_day_create(a)
        elsif a['id'].match /page_consumptions\/day$/
          page_consumptions_day_create(a)
        elsif a['id'].match /page_consumptions_by_consumption_type\/day$/
          page_consumptions_by_consumption_type_day_create(a)
        elsif a['id'].match /page_stories\/week/
          page_stories_week_create(a)
        elsif a['id'].match /page_stories\/days_28/
          page_stories_day_28_create(a)
          
        elsif a['id'].match /page_stories_by_story_type\/week/
          page_stories_by_story_type_week_create(a)
        elsif a['id'].match /page_fans\/lifetime/
          # page_fans a
        end
    end
    
    return 0
  end
  
  protected
  
  def nested_value_data content, attr_name
    end_time = nil
    content['values'].each do |co|
      end_time = Time.parse co['end_time']
      begin
        options = {attr_name=>co['value'].to_json,
                  :post_created_time => end_time}
        find_or_create_page(options)
      
      rescue
        logger.error "ERROR #{$!} #{co['value']}"
      end
    end
     
  end

  def single_value_data content
    arr = []
    content['values'].each do |co|
      hsh = {}
      hsh[:end_time] = Time.parse co['end_time']
      hsh[:value] = co['value'].to_i
      arr << hsh
    end
    arr
  end
  def create_insight_metric content, attr_name
    arr = single_value_data content
    arr.each do |a|
      options = {attr_name=>a[:value],
                :post_created_time=>a[:end_time]}
      find_or_create_page(options)
    end
  end
  
  def page_fan_adds_day_create content=nil
    method = __method__.to_s
    method.match(/^page_(.*)_create$/)
    create_insight_metric content, $1.to_sym
  end
    
  def page_story_adds_day_create(content)
    method = __method__.to_s
    method.match(/^page_(.*)_create$/)
    create_insight_metric content, $1.to_sym
  end
  
  def page_story_adds_by_story_type_day_create(content)
    method = __method__.to_s
    method.match(/^page_(.*)_create$/)
    nested_value_data content, $1.to_sym
  end
  
  def page_consumptions_day_create(content)
    method = __method__.to_s
    method.match(/^page_(.*)_create$/)
    create_insight_metric content, $1.to_sym
  end
  
  def page_consumptions_by_consumption_type_day_create(content)
    method = __method__.to_s
    method.match(/^page_(.*)_create$/)
    nested_value_data content, $1.to_sym
  end
  
  def page_stories_week_create(content)
    method = __method__.to_s
    method.match(/^page_(.*)_create$/)
    create_insight_metric content, $1.to_sym
  end
  
  def page_stories_day_28_create(content)
    method = __method__.to_s
    method.match(/^page_(.*)_create$/)
    create_insight_metric content, $1.to_sym
  end
  
  def page_stories_by_story_type_week_create(content)
    method = __method__.to_s
    method.match(/^page_(.*)_create$/)
    nested_value_data content, $1.to_sym
  end
  
end
