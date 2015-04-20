class Redshift < ActiveRecord::Base
  self.abstract_class = true
  # establish_connection "redshift_#{Rails.env}".to_sym
  
  establish_connection({
    :adapter=>"mysql2",
    :database=>"radd_production",
    :encoding=>"utf8",
    :username=>"root",
    :reconnect=>true}
  )
  RESOURCE = {"RedshiftFbPage"=>[],
              "RedshiftFbPost"=>[],
              "RedshiftTwTimeline"=>[],
              "RedshiftTwTweet"=>[],
              "RedshiftYtChannel"=>[],
              "RedshiftYtVideo"=>[]}

class << self
  # called from the derived class
  # copy from socialdash fb_pages,fb_posts,tw_timelines,tw_tweets
  # to GovDash
  def copy_from_socialdash
    self.name.match(/Redshift(\w+)/)
    puts "  govdash_klass #{$1}"
    t_started=Time.now
    # ActiveRecord::Base.logger.level = 1
    # ActiveRecord::Base.logger.level = 0
    # socialdash_account_ids
    socialdash_account_ids.each do | old_acc_id |
      new_account = govdash_account(old_acc_id)
      next if !new_account
      i = 0
      started=Time.now
      rows = self.where(account_id: old_acc_id).order("created_at desc").to_a
      # puts "  rows count #{rows.size}"
      # with each row from radd_production, copy to
      # govdash_app corresponding table
      rows.each do | old_rec |
        begin
          find_or_create_with old_rec, new_account
        rescue Exception=>ex
          puts "   #{ex.message}"
          raise
        end
        # i += 1
        # break if i > 5
      end; nil
      ended=Time.now
      duration= ended - started
      puts "  #{self.name} #{new_account.object_name} processed #{rows.size} rows in #{duration} seconds"
    end
    t_ended=Time.now
    duration= t_ended - t_started
    puts "  #{self.name} total processed in #{duration} seconds"
    
  end
  
  def govdash_account(old_account_id)
    @govdash_account = nil
    self.name.match(/Redshift(\w+)/)
    klass_name = $1
    case klass_name
    when 'FbPage','FbPost'
      old_account = RedshiftFbPage.find_by account_id: old_account_id
      if old_account      
        @govdash_account = FacebookAccount.find_by object_name:  old_account.object_name
        if !@govdash_account
          # raise "  Not exists  FacebookAccount #{old_account.object_name} "
        end
      end
    when 'TwTimeline','TwTweet'
      old_account = RedshiftTwTimeline.find_by account_id: old_account_id
      if old_account      
        @govdash_account = TwitterAccount.find_by object_name:  old_account.object_name
        if !@govdash_account
        #  raise "  Not exists  TwitterAccount #{old_account.object_name} "
        end
      end
    end
    @govdash_account
  end

  def socialdash_account_ids
    self.name.match(/Redshift(\w+)/)
    klass_name = $1
    case klass_name
    when 'FbPage','FbPost'
      RedshiftFbPage.select('distinct account_id').map(&:account_id)
    when 'TwTimeline','TwTweet'
      RedshiftTwTimeline.select('distinct account_id').map(&:account_id)
    else
      []    
    end
  end

  def copy_data new_rec, old_rec
    changed = false
    column_array.each do |col|
      if new_rec.send(col).to_i < old_rec.send(col).to_i
        val = old_rec.send(col)
        new_rec.send("#{col}=", val)
        changed = true
      end 
    end
    date_array.each do |col|
      val = old_rec.send(col)
      new_rec.send("#{col}=", val)
    end
    if changed
      # puts "   Updating #{new_rec.object_name} #{new_rec.id}"
      new_rec.save
    else
      # puts "   Nothing changed"
    end
  end

  def find_or_create_with old_rec, new_account
    test = new_account.kind_of? Account
    return if !test
    
    old_rec.class.name.match(/Redshift(\w+)/)
    klass_name = $1
    case klass_name
    when 'FbPost'
      new_rec = FbPost.find_or_create_by(post_id: old_rec.post_id)
      new_rec.account_id = new_account.id
    when 'FbPage'
      date = old_rec.post_created_time.beginning_of_day
      new_rec = FbPage.where(account_id: new_account.id).
          where(post_created_time: (date..date.end_of_day)).to_a.first
      if !new_rec
        new_rec = FbPage.create(account_id: new_account.id,
             object_name: new_account.object_name, post_created_time: date.middle_of_day
        )
      end
      new_rec.object_name = new_account.object_name
    when 'TwTweet'
      new_rec = TwTweet.find_or_create_by(tweet_id: old_rec.tweet_id)
      new_rec.account_id = new_account.id
    when 'TwTimeline'
      date = old_rec.tweet_created_at.beginning_of_day
      new_rec = TwTimeline.where(account_id: new_account.id).
           where(tweet_created_at: (date..date.end_of_day)).to_a.first    
      if !new_rec
        new_rec = TwTimeline.create(account_id: new_account.id,
          object_name: new_account.object_name, tweet_created_at: old_rec.tweet_created_at
        )
      end
      new_rec.object_name = new_account.object_name
    end
    copy_data new_rec, old_rec
  end
#
# above for copy data from radd_produciton
#
  def mysql_model_class
    @mysql_model_class ||=
      if self.name =~ /Redshift(\w*)/
        $1.constantize
      else
        nil
      end
  end
  
  def upload last_id=0, conditions={} 
    RESOURCE[self.name] = 
       select("original_id").
          where("original_id > #{last_id}").
            to_a.map{|r| r.original_id}
              
    account_ids = []
    if conditions.empty?
      mysql_records = mysql_model_class.all
    elsif conditions[:account_id]
      aid = conditions[:account_id]
      if String === aid
        account_ids << aid.split(',')
      elsif Array === aid
        account_ids = aid
      elsif Integer === aid
        account_ids = [aid]
      else
        account_ids = []
      end
      mysql_records = mysql_model_class.
         where("account_id in (#{account_ids})").to_a
    end

    ids = mysql_records.map{|a| a.id}
    @bulk_insert = []
    mysql_records.each do | rec |
      attr = rec.attributes
      id = attr.delete('id')
      unless RESOURCE[self.name].include? id
        attr.merge! "original_id"=>id
        @bulk_insert << attr
        RESOURCE[self.name] << id
        if @bulk_insert.size > 1000
          logger.info "  upload #{@bulk_insert} #{mysql_model_class} data to Redshift db"
          self.send "import!", @bulk_insert,''
          @bulk_insert = []
        end
      end
    end
    if @bulk_insert.size > 0
      logger.info "  upload #{@bulk_insert} #{mysql_model_class} data to Redshift db"
      self.send "import!", @bulk_insert,''
      @bulk_insert = []
    end
  end
  handle_asynchronously :upload, :run_at => Proc.new {5.seconds.from_now }
  
  def create_or_update(attr)
     id = attr.delete('id')
     rec = where(:original_id=>id).first
     if rec
       raise ReadOnlyRecord if rec.readonly?
       rec.update_attributes attr
       logger.debug "  RedShift create_or_update updated"
     else
       attr.merge! :original_id=>id
       self.create attr
       logger.debug "  RedShift create_or_update created"
     end
  end

  protected
  def import!(record_list, ignore='IGNORE')
    raise ArgumentError "record_list not an Array of Hashes" unless record_list.is_a?(Array) && record_list.all? {|rec| rec.is_a? Hash }
      
    key_list, value_list = convert_record_list(record_list)       
    sql = "INSERT #{ignore} INTO #{self.table_name} (#{key_list.join(", ")}) VALUES #{value_list.map {|rec| "(#{rec.join(", ")})" }.join(" ,")}"     
    self.connection.execute(sql)
  end
end

end

=begin

class Ericstable < Replica
  self.table_name = 'ericstable'
end


class FacebookAccountReplica < Replica
end

class CreateYourTable < ActiveRecord::Migration

  def connection
    @connection ||= ActiveRecord::Base.connection
  end

  def with_proper_connection
    @connection = YourTable.connection
    yield
    @connection = ActiveRecord::Base.connection
  end


  def up
    with_proper_connection do
      create_table :your_table do |t|
      end
    end
  end

  def down
    with_proper_connection do
      drop_table :your_table
    end
  end
end
=end
