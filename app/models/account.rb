class Account < ActiveRecord::Base
  self.inheritance_column = 'media_type_name'
  
  before_create :record_new
  
  RETRY_SLEEP = 15  # seconds
  SLEEP = 20
  belongs_to :account_type
  belongs_to :language
  has_and_belongs_to_many :countries
  has_and_belongs_to_many :regions
  has_and_belongs_to_many :groups
  has_and_belongs_to_many :subgroups
  has_and_belongs_to_many :sc_segments
  has_and_belongs_to_many :users
  
  def self.send_message_queues
    records = self.where(:is_active=>true).all
    records.each do |a|
      run_it =  (FacebookAccount === a) ? false : true
      if run_it
        a.send_message_queue
        puts "RUN #{a.object_name}"
      else
        puts "NOT RUN #{a.object_name}"
      end
      logger.info "Sleep 10 seconds for next account"
      sleep 10
    end
  end
  
  def send_message_queue
    payload = {:account_id => self.id, :date=>Time.zone.now.to_s(:db)}.to_yaml
    rabbit = RabbitProducer.new
    rabbit.channel.default_exchange.publish(payload,
            :type        => "retrieve",
            :routing_key => "amqpgem.#{self.class.name}")
    rabbit.connection.close
  end
  
  def send_rabbit message="voiceofamerica"
    routing_key = "#{self.object_name}"
    AMQP.channel.default_exchange.publish(message, :routing_key => "routing_key") do
      Rails.logger.info "[AMQP] Published \"#{message}\""
    end
  end
  
  def receive_rabbit
    routing_key = "mq-#{self.object_name}"
    AMQP.channel.default_exchange.publish(message, :routing_key => "routing_key") do
      Rails.logger.info Terminal.yellow("[AMQP] Published \"#{message}\"")
    end
  end
  
  # options = {:group_ids=>[1,2,3], 
  #           :region_ids=>[1,2,3], 
  #           :group_ids=>[1,2,3],
  #           :country_ids=>[251],
  #           :account_ids=>[1]   # this override all 
  #          }
  def self.get_account_ids options
    social_network_ids = options[:social_network_ids] || []
    options[:media_type_names] = MediaType.where(["id in (?)", social_network_ids ]).map{|m| "'#{m.name}'"}
    
    ids = options.delete(:account_ids) || []
    options[:ids] = ids
    account_type_ids = options[:account_type_ids] || []
    group_ids = options[:group_ids] || []
    subgroup_ids = options[:subgroup_ids] || []
    service_ids = options[:service_ids] || []
    language_ids = options[:language_ids] || []
    
    region_ids = options[:region_ids] || []
    country_ids = options[:country_ids] || []
    sc_segment_ids = options[:sc_segment_ids] || []

    cond = []
    account_ids = []
    region_account_ids = []
    country_account_ids = []
    combined_account_ids = []
    if !options[:account_ids]
      options[:account_ids] = []
    else
      combined_account_ids << options[:account_ids]
    end

    [:ids, :account_type_ids, :media_type_names].each do |opt|
       if (options[opt] && options[opt].first)
         cond += ["#{opt.to_s.singularize} in (#{options[opt].join(',')})"]
       end
    end
    
    unless cond.empty?
      cond = cond.join(' AND ')
      account_ids = Account.where(cond).all.to_a.map{|a| a.id}
      combined_account_ids << account_ids
    end    

    if !language_ids.empty?
      language_account_ids = AccountsLanguage.where(["language_id in (#{language_ids.join(',')})"]).
          map{|a| a.account_id}
      combined_account_ids << language_account_ids
    end 
    if !region_ids.empty?
      region_account_ids = AccountsRegion.where(["region_id in (#{region_ids.join(',')})"]).
          map{|a| a.account_id}
      combined_account_ids << region_account_ids
    end
    if !country_ids.empty?
      country_account_ids = AccountsCountry.where(["country_id in (#{country_ids.join(',')})"]).
           map{|a| a.account_id}
      combined_account_ids << country_account_ids
    end
    if !group_ids.empty?
      group_account_ids = AccountsGroup.where(["group_id in (#{group_ids.join(',')})"]).
           map{|a| a.account_id}
      combined_account_ids << group_account_ids
    end
    if !subgroup_ids.empty?
      subgroup_account_ids = AccountsSubgroup.where(["subgroup_id in (#{subgroup_ids.join(',')})"]).
           map{|a| a.account_id}
      combined_account_ids << subgroup_account_ids
    end
    
    account_ids = consolidate_account_ids combined_account_ids
  
  end
  
  def self.consolidate_account_ids account_ids_array
    # delete empty ones from account_ids_array
    # account_ids_array.delete_if{|m| m.empty?}
    if account_ids_array.size > 0
      account_ids = account_ids_array[0]
      account_ids_array[1..-1].each do |ids|
        account_ids = (account_ids & ids)
      end
    else
      account_ids = []
    end

    puts "CONSOLIDATED account ids #{account_ids}"
    account_ids
  end
  
  def s3_filepath(date=Time.now)
    if (date.class == String)
      date = Time.parse date
    end
    root = self.class.name.split('Account')[0].downcase
    @s3_filepath = "#{root}/#{date.strftime("%d%b%y")}/user/#{self.object_name}/"
  end
  
  def self.config
    conf_name = self.name.split('Account').first.downcase
    @config ||= 
       YAML.load_file("#{Rails.root}/config/#{conf_name}.yml")[Rails.env].symbolize_keys
  end
    
  def months_list
    @months_list ||= self.class.config[:months_list].to_i
  end
  def weeks_list
    @weeks_list ||= self.class.config[:weeks_list].to_i
  end
  def days_list
    @days_list ||= self.class.config[:days_list].to_i
  end
  def until_date
    @until_date ||= Time.zone.now
  end
  def until_date=(date)
    @until_date=date
  end
  def since_date
    if !@since_date
      since_str = self.class.config[:since_date]
      if since_str.match /^(\d+\.(day|week|month)s*\.ago$)/
        @since_date = instance_eval($1)
      else
        @since_date = 3.days.ago
      end
    end
    @since_date
  end
  
  def since_date=(date)
    @since_date=date
  end
  
  def max_attempts
    3
  end

  def self.log_error message, level=0
    self.name.match /(.*)Account|\b(ScReferralTraffic)/
    #concatinate possible matches
    prefix = $1.to_s + $2.to_s
    if level==0
      subject="#{prefix} Retrieve Success"
    else
      subject="#{prefix} Retrieve Fail"
    end
    ErrorLog.to_error subject,message,level
  end

  def log_fail message, level=4
    self.class.name.match /(.*)Account/
    aname = $1
    called_by = caller_locations(1,1)[0].label
    called_by.match(/rescue (in block )?(.*)/)
    subject="#{aname} #{self.object_name} (ID: #{self.id}) failed"
    message = "#{$2} #{message}"
    ErrorLog.to_error subject,message,level
  end
  
  def is_facebook?
    self.media_type_name == 'FacebookAccount'
  end
  def is_twitter?
    self.media_type_name == 'TwitterAccount'
  end
  def is_youtube?
    self.media_type_name == 'YoutubeAccount'
  end
  def info
    begin
    {:name=>self.name,:id=>self.id,
      # :entity=>self.group.name,
      # :service=>self.service.name,
      :countries=>self.countries.map{|c| [c.id, c.name]}.to_h,
      :regions=>self.regions.map{|c| [c.id, c.name]}.to_h,
      :contact=>(self.contact || 'N/A')}
    rescue Exception=>e
      logger.error "Error: #{e.message}"
      e.backtrace[0..10].each do |m|
        logger.error "#{m}"
      end
      {}
    end
  end

  def new_item
    read_attribute(:new_item) rescue false
  end
  
  protected
   def obj_name
     self.object_name.split('/')[0]
   end
   def record_new
     new_item = true
   end
   
end
