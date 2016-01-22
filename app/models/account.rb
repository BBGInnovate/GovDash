class Account < ActiveRecord::Base
  self.inheritance_column = 'media_type_name'
  
  cattr_accessor :all_countries, :all_regions
  cattr_accessor :all_groups, :all_subgroups

  before_create :record_new
  after_save :save_organization
  
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
  
  alias_attribute :username, :object_name
  
  validates :username, uniqueness: {scope: :media_type_name,
     case_sensitive: false,
     message: Proc.new { |error, attributes| 
      "#{attributes[:model]} %{value} has already been taken." 
     }}, on: :create
 #    message: "Username %{value} exists." },
  
  def self.retrieve_records from_id=0
     if from_id.to_i > 0
        from_id=" id >= #{from_id}"
     else
       from_id=""
     end
     select('id, object_name,new_item').where(from_id).where("is_active=1").to_a
  end
 
  # run it evefy 1 hours
  def self.check_status
    self.select("distinct media_type_name").all.to_a.each do |a|
      klass = a.media_type_name
      if klass == 'FacebookAccount'
        date = FbPage.select("max(updated_at) AS updated_at").first
        send_alarm date.updated_at,'Facebook'
      elsif klass == 'TwitterAccount'
        date = TwTimeline.select("max(updated_at) AS updated_at").first
        send_alarm date.updated_at,'Twitter'
      elsif klass == 'YoutubeAccount'
        date = YtChannel.select("max(updated_at) AS updated_at").first
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
    else
      puts "  #{klass} status OK at #{date.to_s(:db)}"
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
    read_attribute(:object_name).split('/').last rescue ''
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
       pro = Account.accounts_profiles self.id
       profile_attr.merge! pro.attributes
       # profile_attr.merge! self.account_profile.attributes
     rescue
     end
     ['id','account_id','location','created_at','updated_at'].each do |rm|
        profile_attr.delete(rm)
     end
     the_groups = []
     Account.all_groups.each do | ac |
       if ac.account_id == self.id
         the_groups << ac.group
       end
     end
     the_groups.compact!
     the_subgroups = []
     Account.all_subgroups.each do | ac |
       if ac.account_id == self.id
         the_subgroups << ac.subgroup
       end
     end
     the_subgroups.compact!
     
     the_countries = []
     Account.all_countries.each do | ac |
       if ac.account_id == self.id
         the_countries << ac.country
       end
     end
     the_countries.compact!
     the_regions = []
     Account.all_regions.each do | ac |
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
  
  def log_error msg
     logger.error "  - #{self.id} #{msg}"
  end
  
  def info_old
    begin
     profile_attr = {data_collect_started: self.collect_started}
     begin
       profile_attr.merge! self.account_profile.attributes
     rescue
     end
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
    if !subgroup_ids.empty?
      subgroup_account_ids = AccountsSubgroup.where(["subgroup_id in (#{subgroup_ids.join(',')})"]).
           map{|a| a.account_id}
      combined_account_ids << subgroup_account_ids
    elsif !group_ids.empty?
      group_account_ids = AccountsGroup.where(["group_id in (#{group_ids.join(',')})"]).
           map{|a| a.account_id}
      combined_account_ids << group_account_ids
    elsif !organization_ids.empty?
      org_account_ids = Account.
        where(["organization_id in (?)",organization_ids]).
        map{|a| a.id}
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
        account_ids = Account.where("is_active=1").map(&:id)
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
         logger.error "Account::fetch #{url}"; response.error!
    end
    response
  end

  def to_pacific_time utc_time
    utc_offset = Time.now.in_time_zone("Pacific Time (US & Canada)").utc_offset
    utc_time + utc_offset
  end
  
  protected
  def self.redirect_url(response)
    if response['location']
      response['location']
    else
      response.body.match(/<a href="([^>]+)">/i)[1]
    end
  end
   def obj_name
     self.object_name.split('/')[0]
   end
   def record_new
     new_item = true
   end
   
   def save_organization
      mygroup =  self.groups.first
      if mygroup
        self.update_column :organization_id, mygroup.organization_id
      end
   end
   
   #  last account_id=233
=begin
ALTER TABLE accounts MODIFY name VARCHAR(100);
ALTER TABLE accounts MODIFY object_name VARCHAR(100);
SELECT * FROM govdash_app.languages where name like "%Croatian%";
UPDATE `govdash_app`.`languages` SET `name`='Serbo-Croatian' WHERE `id`='33';
SELECT * FROM govdash_app.countries where name like "Russia%";
replace with Russia (North Caucasus) ,  Russia (Tatarstan / Bashkortistan)

# below are duplicates or Bad, should be deleted.
delete from accounts_subgroups where subgroup_id in
-- delete from groups_subgroups where subgroup_id in
-- delete from subgroups_regions where subgroup_id in
(
select id,name from subgroups where name in (
'Radio Free Afghanistan (Dari)',
'Radio Free Afghanistan (Pashto)',
'Radio Free Afghanistan  (Pashto)',
'Radio Free Afghanistan  (Gandhara)',
'Radio Free Afghanistan (Gandhara)',
'Radio Mashaal (Pashto)',
'Radio Persian',
'RFERL English - Lady Liberty',
'RFERL English - The Power Vertical'
)
)
# some youtube account ids changed. map the new id 
update yt_videos set account_id = 591 where account_id = 215;
update yt_videos set account_id = 600 where account_id = 218;
update yt_videos set account_id = 607 where account_id = 217;
update yt_videos set account_id = 608 where account_id = 557;
update yt_videos set account_id = 612 where account_id = 559;

update yt_channels set account_id = 591 where account_id = 215;
update yt_channels set account_id = 600 where account_id = 218;
update yt_channels set account_id = 607 where account_id = 217;
update yt_channels set account_id = 608 where account_id = 557;
update yt_channels set account_id = 612 where account_id = 559;

update accounts set is_active= 0 where id in (215,218,217,557,559)

=end
def Account.load_group_subgroup_csv
      require 'csv'
      @group = Group.find_by name: 'RFERL'
      # backup groups_subgroups table first!
      subgrp_ids = GroupsSubgroups.where("group_id = #{@group.id}").pluck(:subgroup_id)
      GroupsSubgroups.delete_all "group_id = #{@group.id}"
      Subgroup.delete_all(["id in (?)", subgrp_ids])
      media_type = {0=>'FacebookAccount',
                    1=>'TwitterAccount',
                    2=>'YoutubeAccount'}
      tables = ['Facebook-Table1','Twitter-Table1','Youtube-Table1']
      tables.each_with_index do |  t, i |
        file="/Users/lliu/Desktop/RFERLSMDataAccts/#{t}.csv"
        CSV.foreach(file, quote_char: '"', col_sep: ',', row_sep: :auto, headers:  true) do | line |
          next if !line['Account Name']
          str = line['Account Name'].strip
          account = Account.find_or_create_by object_name: str, 
            media_type_name: media_type[i],organization_id: 1
          account.name = str 
          account.is_active = true
          account.save
          
          # Add AccountsGroup
          AccountsGroup.find_or_create_by account_id: account.id,
                           group_id: @group.id
          str=line['Sub Group'].strip
          subgroup = Subgroup.find_or_create_by name: str
          GroupsSubgroups.find_or_create_by group_id: @group.id,
              subgroup_id: subgroup.id

          AccountsSubgroup.delete_all "account_id = #{account.id}"
          AccountsSubgroup.find_or_create_by account_id: account.id,
              subgroup_id: subgroup.id
          AccountsRegion.delete_all "account_id = #{account.id}"
          str = line['Regions'] || ''
          # Add SubgroupsRegion
          str.split(',').each do | reg |
            region = Region.find_or_create_by name: reg.strip
            SubgroupsRegion.find_or_create_by subgroup_id: subgroup.id,
                           region_id: region.id
            AccountsRegion.find_or_create_by account_id: account.id,
                           region_id: region.id
          end
          AccountsCountry.delete_all "account_id = #{account.id}"
          line['Countries'].split(',').each do | con |
             country = Country.find_or_create_by name: con.strip
             AccountsCountry.find_or_create_by account_id: account.id,
                country_id: country.id
          end

          AccountsLanguage.delete_all "account_id = #{account.id}"
          line['Languages'].split(',').each do | lan |
            language = Language.find_or_create_by name: lan.strip
            AccountsLanguage.find_or_create_by account_id: account.id,
              language_id: language.id
          end
        end
      end
 
   end

   def Account.load_group_csv
      require 'csv'
      ['subgroups','regions_countries', 'subgroups_regions', 'groups_subgroups'].each do |name|
        Account.connection.execute "truncate table #{name}"
      end 
      @bulk_group_subgroup = []
      @bulk_region_country = []
      @bulk_subgroup_region = []
      
      group_subgroups_hash = Hash.new {|h,k| h[k] = [] }
      region_countries_hash = Hash.new {|h,k| h[k] = [] }
      subgroup_regions_hash = Hash.new {|h,k| h[k] = [] }
      
      tables = ['BBG-Regions-Countries-GovDash3.csv']
      tables.each do |  t |
        file="/Users/lliu/Desktop/#{t}"
        CSV.foreach(file, quote_char: '"', col_sep: ',', row_sep: :auto, headers:  true) do | line |
          next if !line['Group']
          group_str=line['Group'].strip
          subgroups_str=line['Sub-Groups'] || line['Subgroup']
          region_str = line['Regions'].strip
          subgroup_arr = subgroups_str.split(',') rescue []
          subgroup_arr.each do | sub_str |
            sub_str.strip!
            next if sub_str.empty?
            subgroup_regions_hash[sub_str] << region_str
          end
          group_subgroups_hash[group_str] << subgroup_arr
          countries_str = line['Countries'] || line['Countries ']
          countries_arr = countries_str.split(',')
          region_countries_hash[region_str] << countries_arr
        end
      end
      update_group_subgroups group_subgroups_hash
      update_subgroup_regions subgroup_regions_hash
      update_region_countries region_countries_hash
      
      GroupsSubgroups.import! @bulk_group_subgroup
      RegionsCountry.import! @bulk_region_country
      SubgroupsRegion.import! @bulk_subgroup_region
   end

   def self.update_region_countries region_countries_hash
     region_countries_hash.each_pair do | _region, _countries|
       _countries.flatten!
       _countries.uniq!
       region = Region.find_by name: _region.strip
       _countries.each do |con|
         country = Country.find_or_create_by name: con.strip
         @bulk_region_country << {:region_id=>region.id,:country_id=>country.id}
         #RegionsCountry.find_or_create_by region_id: region.id,country_id: country.id
       end
     end
   end
   # method OK
   def self.update_subgroup_regions subgroup_regions_hash
     subgroup_regions_hash.each_pair do | _subgrp, _regions|
       sg = _subgrp.strip
       _regions.uniq!
       # next if sg != 'Burmese'
       subgroup = Subgroup.find_or_create_by name: sg
       _regions.each do | _reg |
         region = Region.find_or_create_by name: _reg.strip
         logger.debug "  Create Subgroup: #{sg} Region: #{_reg}"
         @bulk_subgroup_region << {:subgroup_id=>subgroup.id,:region_id=>region.id}
         # SubgroupsRegion.find_or_create_by subgroup_id: subgroup.id,
         #                   region_id: region.id
       end
     end
   end
   
   def self.update_group_subgroups group_hash
     group_hash.each_pair do |k, v|
        v.flatten!
        v.uniq!
        group = Group.find_by name: k.strip
        _subgroups = v
        _subgroups.each do |sg|
          sg.strip!
          sg = 'AlHurra TV' if sg == 'Al Hurra'
          sg = 'Ukraine' if sg == 'Ukrainian'
          subgroup = Subgroup.find_or_create_by name: sg
          @bulk_group_subgroup << {:group_id=>group.id,:subgroup_id=>subgroup.id}
          # GroupsSubgroups.find_or_create_by group_id: group.id,
          #       subgroup_id: subgroup.id
        end
      end
   end

   def self.update_associations account, options
      
       _languages = options[:languages]
       _groups = options[:groups]
       _subgroups = options[:subgroups]
       _regions = options[:regions]
       _countries = options[:countries]
       _organization = options[:organization]
       if _organization
         _organization.strip!
         org = Organization.find_by name: _organization
       else
         org = nil
       end
              
       if _subgroups
# select * from subgroups where name in ('Ukrainian', 'Afaan Oromo','PNN' ,'Tibetan','Tatar-Bashkir')
          _subgroups.split(',').each do |sg|
            sg.strip!
            case sg
            when 'Al Hurra'
              sg = 'AlHurra TV'
            when 'Ukrainian'
              sg = 'Ukraine'
            when 'PNN'
              sg = 'Persian'
            when 'Tibetan'
              sg = 'Tibet'
            when 'Tatar-Bashkir'
              sg = 'Tartar-Bashkir'
            end
            subgroup = Subgroup.find_or_create_by name: sg
            if org
              subgroup.update_attribute :description, "#{org.name}  #{sg}"
            end
            @bulk_account_subgroup << {:account_id=>account.id,:subgroup_id=>subgroup.id}
            # AccountsSubgroup.find_or_create_by account_id: account.id,  subgroup_id: subgroup.id
         end
       end

       if _groups
         Group.delete_all("name in ('Washington','D.C.')")
         _groups.split(';').each do | grp |
           grp.strip!
           group = Group.find_or_create_by name: grp
           if org
             group.update_attribute :organization_id, org.id         
             if !group.description && org
               group.update_attribute :description, "#{org.name} "
             end
           end
           @bulk_account_group << {:account_id=>account.id,:group_id=>group.id}
           # AccountsGroup.find_or_create_by account_id: account.id, group_id: group.id
           account.subgroups.reload.to_a.each do |sg |
             @bulk_group_subgroup << {:group_id=>group.id,:subgroup_id=>sg.id}
             # GroupsSubgroups.find_or_create_by group_id: group.id, subgroup_id: sg.id
           end
         end
       end

       if _languages
       # select * from languages where name in ('Afaan Oromo')
         # Zimbabwe is not a lang name
         _languages.split(',').each do | lan |
           lan.strip!
           case lan
           when 'Laos'
             lan = 'Lao'
           when 'Azerbaijani'
             lan = 'Azeri/Azerbaijani'
           when 'Belarussian'
             lan = 'Belarusian'
           when 'Afaan Oromo'
             lan = 'Afaan Oromoo'
           when 'Swahili'
             lan = 'Kiswahili'
           when 'Tajikistan'
             lan = 'Tajik'
           when 'Zimbabwe'
             lan = 'Shona,Ndebele'
             language = Language.find_or_create_by name: 'Shona'
             language = Language.find_or_create_by name: 'Ndebele'
           when 'Chechen','Crimean', 'Kazak','Tajikistan','Tatar','Shona','Ndebele'
             language = Language.find_or_create_by name: lan
           end
           lan.split(',').each do |la|
             language = Language.find_by name: la
             if language
               @bulk_account_language << {:account_id=>account.id,:language_id=>language.id}
               # AccountsLanguage.find_or_create_by account_id: account.id, language_id: language.id
             else
               logger.debug "  Cannot find #{la}"
               raise
             end
           end
         end
       end
       if _regions
       # select * from regions where name in ('Caucus','Caucusus')
         logger.debug "  #{account.object_name} REGIONS #{_regions.inspect}"
         _regions.split(',').each do | reg |
            reg.strip!
            next if reg.empty?
            
            case reg
            when "Near East (Middle East and North Africa)"
              regs = "Middle East,North Africa"
              regs.split(',').each do |rg|
                region = Region.find_or_create_by name: rg
                @bulk_account_region << {:account_id=>account.id,:region_id=>region.id}
                # AccountsRegion.find_or_create_by account_id: account.id,  region_id:  region.id
              end
            when "Central America Caribbean"
              reg = "Central America and the Caribbean"
              region = Region.find_or_create_by name: reg
              @bulk_account_region << {:account_id=>account.id,:region_id=>region.id}
              # AccountsRegion.find_or_create_by account_id: account.id,  region_id:  region.id
            when "Caucus","Caucusus"
              reg  = 'Caucasus'
              region = Region.find_or_create_by name: reg
              @bulk_account_region << {:account_id=>account.id,:region_id=>region.id}
              # AccountsRegion.find_or_create_by account_id: account.id,  region_id:  region.id
            else
              region = Region.find_or_create_by name: reg
              @bulk_account_region << {:account_id=>account.id,:region_id=>region.id}
              # AccountsRegion.find_or_create_by account_id: account.id,  region_id:  region.id
            end
          end
       end
       
       if _countries
         # select * from countries where name in ('Tajikstan','Union of Soviet Socialist Republics')
         _countries.split(',').each do | co  |
           co.strip!
           case co
           when 'Tajikstan'
             co = 'Tajikistan'
           end
           country = Country.find_or_create_by name: co
           @bulk_account_country << {:account_id=>account.id,:country_id=>country.id}
           # AccountsCountry.find_or_create_by account_id: account.id, country_id: country.id
         end
       end

   end

   def clean_accounts
     Account.all.each do |a|
       if a.object_name != a.object_name.strip
         logger.debug " DELETE #{a.object_name}"
         a.destroy!
       end
     end
   end
   
   
   def Account.load_map_csv
   #  ["subgroups",'groups','languages','regions','countries'].each do | name |
   #   Account.connection.execute "truncate table accounts_#{name}"
   #  end
     @bulk_account_group = []
     @bulk_account_subgroup = []
     @bulk_account_language = []
     @bulk_account_region = []
     @bulk_account_country = []
     @bulk_group_subgroup = []
     # new
     @bulk_subgroup_region = []
     @bulk_region_country = []
     @region_countries_hash = Hash.new {|h,k| h[k] = [] }
     @subgroup_regions_hash = Hash.new {|h,k| h[k] = [] }
     
      require 'csv'
      #tables =  ['BBG-Table 1.csv', 'DOS-Table 1.csv', 'DOD-Table 1.csv']
      #    
      # https://bbginnovate.atlassian.net/secure/attachment/20613/GovDash-Accts-All.xlsx
      # tables = ['GovDash-Accts-All3.csv']
      tables = ['GovDash-Accts-Updates.csv']
      tables.each do |  t |
         # file="/Users/lliu/Desktop/GovDash-Accounts/#{t}"
         file="/Users/lliu/Desktop/#{t}"
         CSV.foreach(file, quote_char: '"', col_sep: ',', row_sep: :auto, headers:  true) do | line |
            if t.match(/BBG/)
               load_bbg line
            elsif t.match(/DOD/)
               load_dod line
            elsif t.match(/DOS/)
               load_dod line
            else
               load_line line
            end
         end
       end
     AccountsGroup.import! @bulk_account_group
     AccountsSubgroup.import! @bulk_account_subgroup
     AccountsLanguage.import! @bulk_account_language
     AccountsRegion.import! @bulk_account_region
     AccountsCountry.import! @bulk_account_country
     GroupsSubgroups.import! @bulk_group_subgroup
     
     update_subgroup_regions @subgroup_regions_hash
     # update_region_countries @region_countries_hash
     
     SubgroupsRegion.import! @bulk_subgroup_region
     # RegionsCountry.import! @bulk_region_country
   end
   def self.load_line line
       arr = line
       return if !arr['Platform']
       # for subgroup-region-country mapping
       subgroups_str=line['Sub-Groups'] || arr['Subgroup'] rescue nil
       regions_str = line['Region'].strip rescue nil
       countries_str = line['Country'] || line['Countries '] rescue nil
       if subgroups_str
         subgroups_str.split(',').each do | sub_str |
           if regions_str
             regions_str.split(',').each do |  region_str |
               @subgroup_regions_hash[sub_str] << region_str.strip
               if countries_str
                 countries_str.split(',').each do |  country_str |
                   @region_countries_hash[region_str] << country_str
                 end
               end
             end
           end
         end
       end
       #  
       klass="#{arr['Platform'].strip.titleize}Account".constantize
       objectname=arr['Account Name'] || arr['Name']
       objectname.strip!
       a = klass.find_or_create_by object_name: objectname
       
       organization = arr['Org'] || arr['Organization']
       organization.strip if organization
       groups=arr['Group']
       subgroups=arr['Sub-Group'] || arr['Subgroup']
       languages= arr['Language']
       service = !!arr['Type'] ? arr['Type'].strip.titleize : nil
       regions = arr['Region']
       countries = arr['Country']
       
       unless service
          service=AccountType.find_or_create_by name: service
          a.account_type_id =  service.id
       end
       options = {:languages=>languages, :groups=>groups, 
         :subgroups=>subgroups, :regions=>regions, 
         :countries=>countries, :organization=>organization}
       update_associations a, options
       
   end

   def self.load_bbg line
       arr = line
       return if !arr['Platform']
       klass="#{arr['Platform'].titleize}Account".constantize
       objectname=arr['Account Name'] || arr['Name']
       objectname.strip!
       organization = arr['Org']
       groups=arr['Group']
       subgroups=arr['Sub-Group'] || arr['Subgroup']
       languages=arr['Language']
       service = arr['Type'].strip.titleize
       regions = arr['Region']  rescue nil
       countries = arr['Country']
 
       a=klass.find_or_create_by object_name: objectname
       unless service.empty?
          service=AccountType.find_or_create_by name: service
          a.account_type_id =  service.id
       end
       options = {:languages=>languages, :groups=>groups, 
         :subgroups=>subgroups, :regions=>regions, 
         :countries=>countries, :organization=>organization}
       update_associations a, options
   end
   
   def self.load_dod line
       arr = line
       return if !arr['Platform']
       
       klass="#{arr['Platform'].titleize}Account".constantize
       objectname=arr['Account Name'] || arr['Name']
       
       logger.debug "  NNN   A_#{objectname}_A"
       objectname.strip!
       a = klass.find_or_create_by object_name: objectname
       organization = arr['Org']
       groups=arr['Group']
       subgroups=arr['Sub-Group'] || arr['Subgroup']
       languages= !!arr['Language'] ? arr['Language'] : nil
       service = !!arr['Type'] ? arr['Type'].strip.titleize : nil
       regions = !!arr['Region'] ? arr['Region'] : nil
       countries = !!arr['Country'] ? arr['Country'] : nil
       
       unless service
          service=AccountType.find_or_create_by name: service
          a.account_type_id =  service.id
       end
       options = {:languages=>languages, :groups=>groups, 
         :subgroups=>subgroups, :regions=>regions, 
         :countries=>countries, :organization=>organization}
       update_associations a, options
       
   end

end  
=begin
  require 'csv'
  file="/Users/lliu/Downloads/voachina-posts.csv"
  CSV.foreach(file, quote_char: '"', col_sep: ',', row_sep: :auto, headers:  false) do | line |
    if t.match(/by action type - like/)
      logger.debug "   #{t}"
    end
  end
 
  voalearningenglish-posts.csv:
  str = '"Post ID",Permalink,"Post Message",Type,Countries,Languages,Posted,"Lifetime Post Total Reach","Lifetime Post organic reach","Lifetime Post Paid Reach","Lifetime Post Total Impressions","Lifetime Post Organic Impressions","Lifetime Post Paid Impressions","Lifetime Engaged Users","Lifetime Talking About This (Post) by action type - answer","Lifetime Talking About This (Post) by action type - comment","Lifetime Talking About This (Post) by action type - like","Lifetime Talking About This (Post) by action type - share","Lifetime Post Stories by action type - answer","Lifetime Post Stories by action type - comment","Lifetime Post Stories by action type - like","Lifetime Post Stories by action type - share"'  
  
  voachina-posts.csv.bk:
  str = '"Post ID",Permalink,"Post Message",Type,Countries,Languages,Posted,"Lifetime Post Total Reach","Lifetime Post organic reach","Lifetime Post Paid Reach","Lifetime Post Total Impressions","Lifetime Post Organic Impressions","Lifetime Post Paid Impressions","Lifetime Engaged Users","Lifetime Talking About This (Post) by action type - comment","Lifetime Talking About This (Post) by action type - like","Lifetime Talking About This (Post) by action type - share","Lifetime Post Stories by action type - comment","Lifetime Post Stories by action type - like","Lifetime Post Stories by action type - share"'
  
  voapashto-posts.csv:
  str = '"Post ID",Permalink,"Post Message",Type,Countries,Languages,Posted,"Lifetime Post Total Reach","Lifetime Post organic reach","Lifetime Post Paid Reach","Lifetime Post Total Impressions","Lifetime Post Organic Impressions","Lifetime Post Paid Impressions","Lifetime Engaged Users","Lifetime Talking About This (Post) by action type - comment","Lifetime Talking About This (Post) by action type - like","Lifetime Talking About This (Post) by action type - share","Lifetime Post Stories by action type - comment","Lifetime Post Stories by action type - like","Lifetime Post Stories by action type - share"'
  head = str.split(',')  
  head.each_with_index do |b,i| 
    if b.match(/by action type - /)
       logger.debug "   #{i}   #{b}" 
    end
  end; nil
  voalearningenglish-posts.csv:
   14   "Lifetime Talking About This (Post) by action type - answer"
   15   "Lifetime Talking About This (Post) by action type - comment"
   16   "Lifetime Talking About This (Post) by action type - like"
   17   "Lifetime Talking About This (Post) by action type - share"
   18   "Lifetime Post Stories by action type - answer"
   19   "Lifetime Post Stories by action type - comment"
   20   "Lifetime Post Stories by action type - like"
   21   "Lifetime Post Stories by action type - share"
  voachina-posts.csv.bk:
   14   "Lifetime Talking About This (Post) by action type - comment"
   15   "Lifetime Talking About This (Post) by action type - like"
   16   "Lifetime Talking About This (Post) by action type - share"
   17   "Lifetime Post Stories by action type - comment"
   18   "Lifetime Post Stories by action type - like"
   19   "Lifetime Post Stories by action type - share"
  voapashto-posts.csv:
   14   "Lifetime Talking About This (Post) by action type - comment"
   15   "Lifetime Talking About This (Post) by action type - like"
   16   "Lifetime Talking About This (Post) by action type - share"
   17   "Lifetime Post Stories by action type - comment"
   18   "Lifetime Post Stories by action type - like"
   19   "Lifetime Post Stories by action type - share"
  file="/Users/lliu/Downloads/voapashto-posts.csv"
  file="/Users/lliu/Downloads/voachina-posts.csv.bk"
  # begin
  
  file="/Users/lliu/Downloads/voalearningenglish-posts.csv"
  j = 15
  file="/Users/lliu/Downloads/voapashto-posts.csv"
  j = 14
  file="/Users/lliu/Downloads/voachina-posts.csv.bk"
  j = 14
  hash = {:talking_comments=> 0,:talking_likes=>0,:talking_shares=>0,
          :story_comments=>0,:story_likes=>0,:story_shares=>0}
  File.readlines(file).each_with_index do |line, fi|
    if fi > 0
     arr = line.split(',')
     hash.keys.each_with_index do | k, i |
       # logger.debug " #{k}  #{j+i} "
       hash[k] += arr[j+i].to_i
     end
    end
  end; nil
  logger.debug File.basename(file)
  logger.debug hash.inspect
  
  # end
  talking_comments = 0
  talking_likes = 0
  talking_shares = 0
  story_comments = 0
  story_likes = 0
  story_shares = 0
  
  hash = {:talking_comments=> 0,:talking_likes=>0,:talking_shares=>0,
          :story_comments=>0,:story_likes=>0,:story_shares=>0}
  j = 15
  File.readlines(file).each_with_index do |line, i|
    if i > 0
     arr = line.split(',')
     hash.keys.each_with_index do | k, i |
       hash[k] += arr[j+i].to_i
     end
     talking_comments += arr[j].to_i
     talking_likes += arr[j+1].to_i
     talking_shares += arr[j+2].to_i
     story_comments += arr[j+3].to_i
     story_likes += arr[j+4].to_i
     story_shares += arr[j+5].to_i
    end
  end; nil
  logger.debug File.basename(file)
  logger.debug hash.inspect
  
  logger.debug "talking_comments: #{talking_comments}, talking_likes: #{talking_likes}, talking_shares: #{talking_shares}"; nil
  logger.debug "story_comments: #{story_comments}, story_likes: #{story_likes}, story_shares: #{story_shares}"; nil
  
   
  file="/Users/lliu/Desktop/accounts.csv"
  file="/Users/lliu/Desktop/tw.csv"
  file="/Users/lliu/Downloads/voalearningenglish.csv"
  # file="/Users/lliu/Downloads/voachina.csv"
  file="/Users/lliu/Downloads/voapashto.csv"
   
  file="/Users/lliu/Downloads/voachina-posts.csv.bk"
  file="/Users/lliu/Downloads/voalearningenglish-posts.csv"
  talking_likes = 0
  story_likes = 0
  likes = 0
  dislikes = 0
  File.readlines(file).each_with_index do |line, i|
    if i > 0
     arr = line.split(',')
     logger.debug "  #{arr[15].to_i}  - #{arr[18].to_i}"
     talking_likes += arr[15].to_i
     story_likes += arr[18].to_i
     # dislikes += arr[3].to_i
    end
  end; nil
  logger.debug talking_likes
  logger.debug story_likes
  # logger.debug likes - dislikes
    
  arr = []
  File.readlines(file).each do |line|
     arr << "'#{line.gsub("\n",'')}'"
  end
  logger.debug arr.join(',')
  
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

