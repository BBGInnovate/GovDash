class ActiveRecord::Base
  # @topics_hash = Hash.new {|h,k| h[k] = Array.new }
  
  def self.clear_stale_connection
     connection_pool.clear_stale_cached_connections!
  end
  
  def self.show_processlist
    results= connection.execute "show processlist"
    results.each do |res|
       puts "#{res}"
    end
    nil
  end
  
  def self.show_var(name, global=nil)
    sql = "show #{global} variables like '%#{name}%'"
    results= connection.execute sql
    results.each do |res|
      puts "#{res[0]} = #{res[1]}"
    end
    nil
  end
  
  def self.import!(record_list, ignore='IGNORE')
    raise ArgumentError "record_list not an Array of Hashes" unless record_list.is_a?(Array) && record_list.all? {|rec| rec.is_a? Hash }
      
    key_list, value_list = convert_record_list(record_list)       
    key_list = key_list | [:created_at, :updated_at]
    value_list = value_list.map{|a| a += ["'#{Time.now}'", "'#{Time.now+1}'"]} 
    sql = "INSERT #{ignore} INTO #{self.table_name} (#{key_list.join(", ")}) VALUES #{value_list.map {|rec| "(#{rec.join(", ")})" }.join(" ,")}"     
    self.connection.insert_sql(sql)
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
    
  def self.truncate
      connection.execute "truncate table #{table_name}"
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
  
end

