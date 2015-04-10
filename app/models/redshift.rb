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
  def copy_from_socialdash
    account_ids.each do | old_acc_id |
      @objectname = get_object_name old_acc_id
      puts @objectname
      rows = self.where(account_id: old_acc_id ).to_a
      puts "  rows count #{rows.size}"
      rows.each do | old_rec |
        begin
          find_or_create_with old_rec, @objectname
        #rescue Exception=>ex
        #  puts "   #{ex.message}"
        end
      end
      # break
    end
  end
  
  def account_ids
    @account_ids =
      select('distinct account_id').map(&:account_id)
  end

  def get_object_name old_account_id
    @object_name =
      case self.name
      when 'RedshiftFbPage','RedshiftFbPost'
        RedshiftFbPage.find_by(account_id: old_account_id).object_name
      when 'RedshiftTwTimeline', 'RedshiftTwTweet'
        RedshiftTwTimeline.find_by(account_id: old_account_id).object_name
      end
  end
  
  def copy_data new_rec, old_rec
    column_array.each do |col|
      if new_rec.send(col).to_i < old_rec.send(col).to_i
        val = old_rec.send(col)
        new_rec.send("#{col}=", val)
      end 
    end
    puts "   new_rec  #{new_rec.inspect}"
    new_rec.save
  end

  def find_or_create_with old_rec, objectname
    self.name.match(/Redshift(\w+)/)
    klass_name = $1
    govdash_klass = klass_name.constantize
    new_acc = nil
     
    case klass_name
    when 'FbPage','FbPost'
      puts "  govdash_klass #{govdash_klass.name}"
      new_acc = FacebookAccount.find_by object_name: objectname
    when 'TwTimeline','TwTweet'
      new_acc = TwitterAccount.find_by object_name: objectname
    end
    puts "  find_or_create_with new_acc #{new_acc}"
    date = nil
    if old_rec.respond_to? :post_created_time
      date = old_rec.post_created_time.beginning_of_day
      new_rec = govdash_klass.where(account_id: new_acc.id).
           where(post_created_time: (date..date.end_of_day)).to_a.first
    else
      date = old_rec.tweet_created_at.beginning_of_day
      new_rec = govdash_klass.where(account_id: new_acc.id).
           where(tweet_created_at: (date..date.end_of_day)).to_a.first
    end
    
    if !new_rec
      case klass_name
      when 'FbPage'
        new_rec = govdash_klass.create(account_id: new_acc.id,
          object_name: objectname, post_created_time: date.middle_of_day
        )
      when 'FbPost'
        new_rec = govdash_klass.create(account_id: new_acc.id,
          post_id: old_rec.post_id, post_created_time: old_rec.post_created_time
        )
      when 'TwTimeline'
        new_rec = govdash_klass.create(account_id: new_acc.id,
          object_name: objectname, tweet_created_at: old_rec.tweet_created_at
        )
      when 'TwTweet'
        new_rec = govdash_klass.create(account_id: new_acc.id,
          tweet_id: old_rec.tweet_id, tweet_created_at: old_rec.tweet_created_at
        )
      end  
    end
    copy_data new_rec, old_rec
  end

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
