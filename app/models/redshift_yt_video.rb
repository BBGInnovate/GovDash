class RedshiftYtVideo < Redshift
  self.table_name = "yt_videos"

  class << self
  def upload last_id=0, conditions={} 
    klass = self
    klass_name = klass.name
    mysql_klass = klass.mysql_model_class
    ids = []
    if conditions.empty?
      ids = mysql_klass.select("distinct yt_channel_id").map{|a| a.yt_channel_id}
    elsif conditions[:yt_channel_id]
      aid = conditions[:yt_channel_id]
      if String === aid
        ids = aid.split(',') 
      else
        ids = aid
      end
    end
    ids.each do | acc_id |
      arr = []
      klass::RESOURCE[klass_name] = 
        klass.select("original_id").
        where(:yt_channel_id=>acc_id).
        where("original_id > #{last_id}").
        to_a.map{|r| r.original_id}
      
      mysql_klass.where(:yt_channel_id=>acc_id).
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
        say " YtChannel #{acc_id} #{arr.size} rows uploaded"
      else
        say " YtChannel #{acc_id} Nothing to upload"
      end
    end
  end
  handle_asynchronously :upload, :run_at => Proc.new {10.seconds.from_now }
  end
end
