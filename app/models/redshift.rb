class Redshift < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "redshift_#{Rails.env}".to_sym
  
  @@existing_fb_pages = []
  @@existing_fb_posts = []
  @@existing_tw_timelines = []
  @@existing_tw_tweets = []
  
  RESOURCE = {"RedshiftFbPage"=>@@existing_fb_pages,
              "RedshiftFbPost"=>@@existing_fb_posts,
              "RedshiftTwTimeline"=>@@existing_tw_timelines,
              "RedshiftTwTweet"=>[]}
class << self       
  def mysql_model_class
    if self.name =~ /Redshift(\w*)/
      $1.constantize
    else
      nil
    end
  end
  
  def upload last_id, conditions={} 
    klass = self
    # klass = RedshiftTwTweet
    klass_name = klass.name
    mysql_klass = klass.mysql_model_class
    
    account_ids = []
    if conditions.empty?
      account_ids = mysql_klass.select("distinct account_id").map{|a| a.account_id}
    elsif conditions[:account_id]
      aid = conditions[:account_id]
      if Array === aid
        account_ids << aid.split(',') 
      else
        account_ids << aid
      end
    end
    
    account_ids.each do | acc_id |
      arr = []
      klass::RESOURCE[klass_name] = 
        klass.select("original_id").
        where(:account_id=>acc_id).
        where("original_id > #{last_id}").
        to_a.map{|r| r.original_id}
      
      mysql_klass.where(:account_id=>acc_id).
        where("id > #{last_id}").to_a.each do |rec|
        attr = rec.attributes
        id = attr.delete('id')
        unless klass::RESOURCE[klass_name].include? id
          attr.merge! "original_id"=>id
          arr << attr
          klass::RESOURCE[klass_name] << id
        end
      end
      
      unless arr.empty?
        klass.send "import!", arr,''
        Rails.logger.debug " Account #{acc_id} #{arr.size} rows uploaded"
      else
        Rails.logger.debug " Account #{acc_id} Nothing to upload"
      end
      
      sleep 3
      
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
