class Redshift < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "redshift_#{Rails.env}".to_sym
  
  RESOURCE = {"RedshiftFbPage"=>[],
              "RedshiftFbPost"=>[],
              "RedshiftTwTimeline"=>[],
              "RedshiftTwTweet"=>[],
              "RedshiftYtChannel"=>[],
              "RedshiftYtVideo"=>[]}

class << self
  def say(text)
    Delayed::Worker.logger.add(Logger::INFO, text)
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
    
    puts "   AAAA #{RESOURCE[self.name].inspect}"
    puts "   AAAA mysql_records #{mysql_records.size}"
    
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
          self.send "import!", @bulk_insert,''
          @bulk_insert = []
        end
      end
    end
    puts "   AAAA @bulk_insert #{@bulk_insert.size}"
    if @bulk_insert.size > 0
      self.send "import!", @bulk_insert,''
      @bulk_insert = []
    end
  end
  # handle_asynchronously :upload, :run_at => Proc.new {5.seconds.from_now }
  
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
