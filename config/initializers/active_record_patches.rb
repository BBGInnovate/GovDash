class ActiveRecord::Base
  # @topics_hash = Hash.new {|h,k| h[k] = Array.new }
  
  def self.clear_stale_connection
     connection_pool.clear_stale_cached_connections!
  end
  
  def self.show_processlist(db=nil, command=nil)
    q = "SELECT * FROM information_schema.processlist "
    if db
      q = "#{q} where db='cxp_production' "
      if command
        q = "#{q} and Command='#{command}' "
      end
    end
    if command
      q = "#{q} where Command='#{command}'"
    end
    results= ActiveRecord::Base.connection.execute q
    results.each do |res|
       puts "#{res}"
    end
    nil
    puts " Total count: #{results.count}"
  end
  
  def self.show_var(name, global=nil)
    sql = "show #{global} variables like '%#{name}%'"
    results= connection.execute sql
    results.each do |res|
      puts "#{res[0]} = #{res[1]}"
    end
    nil
  end
  # attributes_array - array of attributes to be inserted
  def self.import_bulk! attributes_array
    tmp = []
    attributes_array.each  do | rec | 
       tmp << self.new(rec)
    end
    # from gem activerecord-import
    self.import tmp
  end
  # columns - column names to be updated
  # data = { 1=>{:col1=>'val1',:col2=>'val2'}, 2=>{:col2=>'val2'}}
  def self.update_bulk! data
    if Hash != data.class
      raise "   Input must be a Hash"
    elsif data.blank?
      return
    end
    if Hash != data.values.first.class
      raise "   Input Hash value must be a Hash"
    end
    started = Time.now
    columns = data.values.map(&:keys).flatten.uniq
    columns.each do | col |
      next if !self.column_names.include?(col.to_s)
      ids_hash = {}
      data.keys.each do | id |
        val = data[id][col] || data[id][col.to_sym]
        if val 
          if !ids_hash[id]
            ids_hash[id] = val
          else
            ids_hash[id].merge val
          end
        end
      end
      if !ids_hash.blank?
        self.bulk_update_column 'id', col, ids_hash
      end
    end
  end
  
  # bulk_update_column 'fb_posts', 'id', 'post_type', {417439=>'test-original'}
  def self.bulk_update_column id_column, update_column, ids_hash
    sql = "update #{self.table_name} set #{update_column} = CASE #{id_column} "
    ids_hash.each_pair do | id, val |
      sql += " WHEN #{id} THEN '#{val}'";
    end
    sql += " END WHERE #{id_column} in ( #{ids_hash.keys.join(',')} ) "
    puts "  bulk_update_column sql size: #{sql.size}"
    connection.execute sql
  end
  
  def self.import!(record_list, ignore='IGNORE')
    if record_list.empty?
      return
    end
    raise ArgumentError "record_list not an Array of Hashes" unless record_list.is_a?(Array) && record_list.all? {|rec| rec.is_a? Hash }
      
    key_list, value_list = convert_record_list(record_list)   
    
    if self.column_names.include? "created_at"    
      key_list = key_list | [:created_at, :updated_at]
      value_list = value_list.map{|a| a += ["'#{Time.now.to_s(:db)}'", "'#{Time.now.to_s(:db)}'"]} 
    end
    sql = %{INSERT #{ignore} INTO #{self.table_name} (#{key_list.join(", ")}) VALUES #{value_list.map {|rec| "(#{rec.join(", ")})" }.join(" ,")};}   
    # self.connection.insert_sql("set GLOBAL wait_timeout=28800;")   
    self.connection.insert_sql("SET unique_checks=0;")    
    self.connection.insert_sql(sql)
    self.connection.insert_sql("SET unique_checks=1;")
  end
  
  def self.convert_record_list(record_list)
    key_list = record_list.map(&:keys).flatten.uniq.sort
    value_list = record_list.map do |rec|
      list = []
      key_list.each {|key| list <<  ActiveRecord::Base.connection.quote(rec[key]) }
      list
    end
    return [key_list, value_list]
  end
  
  def self.clean_params params
    p = params
    c=self.columns.map{|a| a.name.to_sym}
    p.keys.each do |k|
      if !c.include? k
        p.delete k
      end
    end
    p
  end
  
  def filter_attr names
    p = attributes.clone
    p.keys.each do |k|
      if !names.include? k
        p.delete k
      end
    end
    p
  end
  
  def is_singular?(str)
    str.pluralize.singularize == str
  end

  def add_struct(data)
    arr = []
    self.class.reflections.keys.each do |key|
      if is_singular?(key.to_s)
        if self.class.reflections[key].macro == :belongs_to
          arr = []
          key.to_s.capitalize.constantize.all.each do |n|
            attr = n.filter_attr ['name','id']
            arr << OpenStruct.new(attr).send('table')
          end
          var = key.to_s.pluralize
          data.send "#{var}=", arr
        end
      end
    end
    data
  end
    
  def json_obj
    data = OpenStruct.new(attributes)
    add_struct data
    data.send 'table'
  end

  # copied from Delayed_job::Worker
  def say(text, level=Rails.logger.level)
    return
    text = "[Worker(#{name})] #{text}"
    puts text unless @quiet
    return unless logger
    # TODO: Deprecate use of Fixnum log levels
    unless level.is_a?(String)
      level = Logger::Severity.constants.detect { |i| Logger::Severity.const_get(i) == level }.to_s.downcase
    end
    logger.send(level, "#{Time.now.strftime('%FT%T%z')}: #{text}")
    Delayed::Worker.logger.flush
  end
  
  def send_rabbit_message action
    # see rabbit_receiver.rb
    unless ['upload','retrieve','initial_load'].include? action
      raise "#{self.class.name}#send_rabbit_message invalid action: #{action}"
    end
    
    begin
      payload = {:id => self.id,:klass=> self.class, :date=>Time.zone.now.to_s(:db)}.to_yaml
      rabbit = RabbitProducer.new
      rabbit.channel.default_exchange.publish(payload,
            :type        => action,
            :routing_key => "amqpgem.#{action}")
      rabbit.connection.close
    rescue Exception=>ex
      logger.error "   RabbitMQ #{ex.message}"
    end
  end
  
  def self.execute sql
    arr = []
    results = ActiveRecord::Base.connection.execute(sql)
    if results
      flds = results.fields
      results.each do |row|
        res = OpenStruct.new
        row.each_with_index do |f,i|
          res.send "#{flds[i]}=", f
        end
        arr << res
      end
      arr
    else
      nil
    end
  end
  
  def destroy
    if self.respond_to? :is_active
      self.update_column :is_active, false
    else
      super
    end
  end

end

