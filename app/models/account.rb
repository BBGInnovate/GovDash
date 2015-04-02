class Account < ActiveRecord::Base
  self.inheritance_column = 'media_type_name'
  
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
  
  def self.retrieve sincedate=7.day.ago,  from_id=0
     if from_id.to_i > 0
        from_id=" id >= #{from_id}"
     else
       from_id=""
     end
      select('id, object_name,new_item').where(from_id).where("is_active=1").to_a
  end
  
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

  def object_name
    read_attribute(:object_name).split('/').last
  end

  def info
    begin
     profile_attr = {data_collect_started: self.collect_started}
     profile_attr.merge! self.account_profile.attributes
     ['id','account_id','location','created_at','updated_at'].each do |rm|
        profile_attr.delete(rm)
     end
     {:name=>self.name,:id=>self.id,
      :profile=>profile_attr,
      :groups=>self.groups.map(&:name),
      :subgroups=>self.subgroups.map(&:name),
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

  # override by subclass
  def location hsh
    hsh
  end
  
  def update_profile options
    options.symbolize_keys!
    # options[:description].gsub(/\n/, " ").truncate(255)
    options[:name] = self.object_name
    attr = {}
    AccountProfile.column_names.each do |col|
      if options.has_key? col.to_sym
        attr[col.to_sym] = options[col.to_sym]
      end
    end
    
    cn = find_account_country options[:location]
    insert_account_country cn
    if !self.account_profile
      self.create_account_profile attr
    else
      self.account_profile.update_attributes attr
    end
    
  end
  
  def insert_account_country country
    if country
      begin
        ac = AccountsCountry.find_by account_id: self.id, 
               country_id: country.id
        # remove mapping 
        ac.destroy if ac
        # ac = AccountsCountry.find_or_create_by account_id: self.id, 
        # country_id: country.id
      rescue Exception=>ex
      
      end
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
    if combined_account_ids.empty?
      account_ids = Account.where("is_active=1").map(&:id)
    else
      account_ids = consolidate_account_ids combined_account_ids
    end
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

  protected
   def obj_name
     self.object_name.split('/')[0]
   end
   def record_new
     new_item = true
   end
   #  last account_id=233
   
   def self.update_associations account,  _languages=nil, _groups, _sub_group, _regions
      _groups.compact!
       _regions.compact!
       a = account
       AccountsSubgroup.find_or_create_by account_id: a.id,  subgroup_id: _sub_group.id
       # a.groups.destroy_all
       _groups.each do | grp |
           group = Group.find_or_create_by name: grp, organization_id:  account.organization_id
           if !group.description
             group.update_attribute :description, "#{a.organization.name} "
           end
           
           puts "   #{grp} - group #{group.inspect}"
           AccountsGroup.find_or_create_by account_id: a.id, group_id: group.id
           GroupsSubgroups.find_or_create_by group_id: group.id, subgroup_id: _sub_group.id
       end
       if _languages
         # a.languages.destroy_all
         _languages.each do |  lan  |
           language = Language.find_by name:lan
           AccountsLanguage.find_or_create_by account_id: a.id, language_id: language.id
         end
       end
       if _regions
         # a.regions.destroy_all
         puts "  #{a.object_name} REGIONS #{_regions.inspect}"

         _regions.each do | reg |
             reg.strip!
             next if reg.empty?
             
             puts "   Region #{reg}"
             region = Region.find_or_create_by name: reg
             AccountsRegion.find_or_create_by account_id: a.id,  region_id:  region.id
          end
        end
   end
   
   def self.load_bbg line
       arr = line
       klass="#{arr[0].titleize}Account".constantize
       objectname=arr[1]
       puts "   AA #{arr[0].titleize} #{objectname}"
       org=Organization.find_by name: arr[2]
       groups=arr[3].split(',')
       subgroup=arr[4]
       subgroup = 'AlHurra TV' if subgroup == 'Al Hurra'

       sub_group = Subgroup.find_or_create_by name: subgroup
       sub_group.update_attribute :description, "#{org.name}  #{subgroup}"
      
       languages=arr[5].split(',')
       service = arr[6].strip.titleize
       regions = arr[7..-1]  rescue nil
       a=klass.find_or_create_by object_name: objectname
       unless service.empty?
          service=AccountType.find_or_create_by name: service
          a.account_type_id =  service.id
       end
       a.organization_id=org.id
       a.save
       update_associations a, languages, groups, sub_group, regions

   end
   
   def self.load_dod line
       arr = line
       klass="#{arr[0].titleize}Account".constantize
       objectname=arr[1]
       puts "   AA #{arr[0].titleize} #{objectname}"
       org=Organization.find_by name: arr[2]
       groups=arr[3].split(',')
       subgroup=arr[4]
       subgroup = 'AlHurra TV' if subgroup == 'Al Hurra'
       sub_group = Subgroup.find_or_create_by name: subgroup
       sub_group.update_attribute :description, "#{org.name}  #{subgroup}"
       languages= nil
       service = arr[5].strip.titleize rescue ""
       regions=arr[6..-1] rescue nil
       a=klass.find_or_create_by object_name: objectname
       unless service.empty?
          service=AccountType.find_or_create_by name: service
          a.account_type_id =  service.id
       end
       a.organization_id=org.id
       a.save
       update_associations a, languages, groups, sub_group, regions
       
   end
   def self.load_map_csv
      tables =  ['BBG-Table1.csv', 'DOS-Table1.csv', 'DOD-Table1.csv']
      tables.each do |  t |
         file="/Users/lliu/Desktop/GovDash-Accounts/#{t}"
         CSV.foreach(file, quote_char: '"', col_sep: ',', row_sep: :auto, headers:  false) do | line |
            if t.match(/BBG/)
               load_bbg line
            elsif t.match(/DOD/)
               load_dod line
            elsif t.match(/DOS/)
               load_dod line
            end
         end
       end
   end
end  
=begin
   def self.load_account_csv file
      file="/Users/lliu/Desktop/new_sm_accounts_rferl.csv"
      File.readlines(file).each do |line|
         klass=nil
        arr = line.split(',')
        network=arr[0]
        language=arr[1]
        group=arr[2]
        url=arr[3]
        objectname = url.split('/').last
        begin
          uri=URI.parse url
        rescue
          next
        end
        if uri.host.match(/facebook/)
           klass=FacebookAccount
        elsif uri.host.match(/twitter/)
           klass= TwitterAccount
         elsif uri.host.match(/youtube/)
           klass= YoutubeAccount
         end
         if klass
            obj = klass.find_or_create_by object_name: objectname
            obj.name="#{ network} #{language}"
            obj.media_type_name=klass.name
            name=klass.name.split('Account')[0]
            obj.description="#{ network} #{language} #{name}  Account"
            obj.organization_id=1 if !obj.organization_id
            obj.save
         end
         
      end
   end
   
=end

