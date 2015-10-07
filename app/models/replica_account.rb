class ReplicaAccount < Replica
  self.table_name = "accounts"
  self.inheritance_column = 'media_type_name'
  
  cattr_accessor :all_countries, :all_regions
  cattr_accessor :all_groups, :all_subgroups

  before_create :record_new
  
  has_one :account_profile, foreign_key: :account_id, 
      dependent: :destroy

  RETRY_SLEEP = 15  # seconds
  SLEEP = 20
  belongs_to :account_type
  belongs_to :organization
  has_and_belongs_to_many :languages
  has_and_belongs_to_many :countries
  has_and_belongs_to_many :regions
  has_and_belongs_to_many :groups
  has_and_belongs_to_many :subgroups
  has_and_belongs_to_many :sc_segments
  has_and_belongs_to_many :users

  # run it evefy 1 hours
  def self.check_status
    self.select("distinct media_type_name").all.to_a.each do |a|
      klass = a.media_type_name
      if klass == 'FacebookAccount'
        date = ReplicaFbPage.select("max(updated_at) AS updated_at").first
        send_alarm date.updated_at,'Facebook'
      elsif klass == 'TwitterAccount'
        date = ReplicaTwTimeline.select("max(updated_at) AS updated_at").first
        send_alarm date.updated_at,'Twitter'
      elsif klass == 'YoutubeAccount'
        date = ReplicaYtChannel.select("max(updated_at) AS updated_at").first
        send_alarm date.updated_at, 'Youtube'
      end
    end
  end

  def self.send_alarm date, klass
    ago = ((Time.now - date)/3600).to_i
    to = ['liwliu@bbg.gov','aramachandran@bbg.gov','amartin@bbg.gov','hnoor@bbg.gov']
    msg = "#{klass} data not updated in #{ago} hours"
    if klass == 'Facebook'
      to_send = (date < 9.hours.ago)
    else
      to_send = (date < 6.hours.ago) 
    end
    if to_send
      UserMailer.alarm_email(to, msg).deliver_now!
      logger.debug "  #{klass} updated at #{date.to_s(:db)} Current time: #{Time.now.to_s(:db)}"
    end
  end

  def self.send_message_queues
    records = self.where(:is_active=>true).all
    records.each do |a|
      run_it =  (FacebookAccount === a) ? false : true
      if run_it
        a.send_message_queue
        logger.debug "RUN #{a.object_name}"
      else
        logger.debug "NOT RUN #{a.object_name}"
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

  def object_name
    read_attribute(:object_name).split('/').last
  end

  def self.accounts_profiles account_id
    @accounts_profiles ||= AccountProfile.
      select([:account_id,:platform_type,:name,:display_name,:description,
             :url,:avatar,:total_followers,:verified]).to_a
    @accounts_profiles.detect{|ap| ap.account_id==account_id}
  end

  def info
    begin
     profile_attr = {data_collect_started: self.collect_started}
     begin
       pro = ReplicaAccount.accounts_profiles self.id
       profile_attr.merge! pro.attributes
       # profile_attr.merge! self.account_profile.attributes
     rescue
     end
     ['id','account_id','location','created_at','updated_at'].each do |rm|
        profile_attr.delete(rm)
     end
     the_groups = []
     ReplicaAccount.all_groups.each do | ac |
       if ac.account_id == self.id
         the_groups << ac.group
       end
     end
     the_groups.compact!
     the_subgroups = []
     ReplicaAccount.all_subgroups.each do | ac |
       if ac.account_id == self.id
         the_subgroups << ac.subgroup
       end
     end
     the_subgroups.compact!
     the_countries = []
     ReplicaAccount.all_countries.each do | ac |
       if ac.account_id == self.id
         the_countries << ac.country
       end
     end
     the_countries.compact!
     the_regions = []
     ReplicaAccount.all_regions.each do | ac |
       if ac.account_id == self.id
         the_regions << ac.region
       end
     end
     the_regions.compact!
     {:name=>self.name,:id=>self.id,
      :profile=>profile_attr,
      :groups=>the_groups.map(&:name),
      :subgroups=>the_subgroups.map(&:name),
      :countries=>the_countries.map{|c| [c.id, c.name]}.to_h,
      :regions=> the_regions.map{|c| [c.id, c.name]}.to_h, 
      :contact=>(self.contact || 'N/A')}
    rescue Exception=>e
      logger.error "Error: #{e.message}"
      e.backtrace[0..10].each do |m|
        logger.error "#{m}"
      end
      {}
    end
  end

  # override by subclass
  def location hsh
    hsh
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
    organization_ids = options[:organization_ids] || []
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
      account_ids = ReplicaAccount.where(cond).
        pluck(:id)
      combined_account_ids << account_ids
    end    

    if !language_ids.empty?
      language_account_ids = AccountsLanguage.
          where(["language_id in (#{language_ids.join(',')})"]).
          pluck(:account_id)
      combined_account_ids << language_account_ids
    end 
    if !region_ids.empty?
      region_account_ids = AccountsRegion.
          where(["region_id in (#{region_ids.join(',')})"]).
          pluck(:account_id)
      combined_account_ids << region_account_ids
    end
    if !country_ids.empty?
      country_account_ids = AccountsCountry.
           where(["country_id in (#{country_ids.join(',')})"]).
           pluck(:account_id)
      combined_account_ids << country_account_ids
    end
    if !subgroup_ids.empty?
      subgroup_account_ids = AccountsSubgroup.
           where(["subgroup_id in (#{subgroup_ids.join(',')})"]).
           pluck(:account_id)
      combined_account_ids << subgroup_account_ids
    elsif !group_ids.empty?
      group_account_ids = AccountsGroup.
           where(["group_id in (#{group_ids.join(',')})"]).
           pluck(:account_id)
      combined_account_ids << group_account_ids
    elsif !organization_ids.empty?
      org_account_ids = ReplicaAccount.
        where(["organization_id in (?)",organization_ids]).
        pluck(:id)
      combined_account_ids << org_account_ids  
    end

    # remove 1 == 0 when user role is setup
    if !current_user.is_admin?
      user_account_ids = []
      current_user.organizations.each do |org|
        user_account_ids << org.accounts.map(&:id)
      end
      user_account_ids.flatten!
    end
    if combined_account_ids.empty?
        account_ids = ReplicaAccount.where("is_active=1").
          pluck(:id)
    else
        account_ids = consolidate_account_ids combined_account_ids
    end
    if !current_user.is_admin?
      account_ids = (user_account_ids & account_ids)
    else
      account_ids
    end
    account_ids
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

    logger.debug "CONSOLIDATED account ids #{account_ids}"
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

  def new_item
    read_attribute(:new_item) rescue false
  end
  
  # used by FacebookAccount#save_lifetime_data
  def self.fetch(url, limit = 3)
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 180
       # http.set_debug_output($stdout)
    if uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    response = http.get(uri.request_uri)
    case response
       when (Net::HTTPOK || Net::HTTPSuccess)
          return response
       when Net::HTTPRedirection
          new_url = redirect_url(response)
          logger.debug "Redirect to " + new_url
          return fetch(new_url, limit - 1)
       else
         response.error!
    end
    response
  end

  def to_pacific_time utc_time
    utc_offset = Time.now.in_time_zone("Pacific Time (US & Canada)").utc_offset
    utc_time + utc_offset
  end
  
  protected
   def obj_name
     self.object_name.split('/')[0]
   end
   def record_new
     new_item = true
   end
end  

