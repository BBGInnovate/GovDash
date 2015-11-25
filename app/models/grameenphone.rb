require 'open-uri'
class Grameenphone
  class << self
    cattr_accessor :message
    
    def check_status
      dir = '/english/audio/science'
      max_date = 1.day.ago
      ftp.nlst(dir).each do | file |
        date = ftp.mtime(file)
        if date > max_date
          max_date = date
        end
      end 
      puts " Grameenphone english/audio/science #{max_date}"
      if max_date < 7.hours.ago
        to = ['liwliu@bbg.gov','dzabransky@bbg.gov']
        msg = 'Grameenphone english/audio/science is not updated in 7 hours'
        UserMailer.alarm_email(to, msg).deliver_now!
      end
    end
  
    #
    # below for cron in cxp-hub for voa headline news mp3
    # cronjob every hour at 10 minutes
    # */15 * * * * cd /home/oddev/hub/current && bundle exec rails runner -e production  'Grameenphone.upload'  > /tmp/grameenphone-cron.log 2>&1
    def upload
      started = Time.now
      ['english_audio', 'english_video',
       'bengali_audio','bengali_video'].each do | content |
        self.send content
      end
      dur = (Time.now - started).to_i # .strftime '%H:%M:%S'
      puts "  Finished in #{dur} seconds"
    end
    
    def english_audio
      dir = '/english/audio/science'
      delete_old dir
      
      ftp.mkdir_p dir
      ftp.chdir dir
      
      limit = 10
      options = {:language=>'en',
                 :keywords=>'science minute,Science Minute',
                 :details=>2,
                 :limit=>limit}
      url = searcher options
      txt = open(url, :read_timeout => 20).read
      hash = JSON.parse txt
      contents = hash['contents']
      (0..contents.size-1).each do |idx|
        audio_url = contents[idx]['_embedded']['audios'][0]['url']
        upload_english_audio audio_url
      end
      ftp_close
    end

    def english_video
      ['Science','Economy','Health'].each do | cat |
        dir = "/english/video/#{cat.downcase}"
        delete_old dir
        ftp.mkdir_p dir
        ftp.chdir dir
      
        limit = 10
        options = {:language=>'en',
                 :keywords=>"One-Minute Features - #{cat}",
                 :details=>2,
                 :limit=>limit}
        url = searcher options         
        txt = open(url, :read_timeout => 20).read
        hash = JSON.parse txt
        contents = hash['contents']
        (0..contents.size-1).each do |idx|
           videos = contents[idx]['_embedded']['videos']
           videos.each do | v |
             if v['quality'] == 'hq'
               video_url = v['url']
               puts "  URL #{video_url}"
               upload_english_video video_url, cat.downcase
             end
           end
        end
      end
      ftp_close
    end
    
    def bengali_audio
      dir = "/bangla/audio/news"
      delete_old dir
      
      ftp.mkdir_p dir
      ftp.chdir dir
      
      limit = 10
      options = {:language=>'bn',
                 :type=>'audio',
                 :details=>2,
                 :limit=>limit}
      url = searcher options   
      txt = open(url, :read_timeout => 20).read
      hash = JSON.parse txt
      contents = hash['contents']
      (0..contents.size-1).each do |idx|
        audio = contents[idx]['_embedded']['audios'][0]
        audio_url = audio['url']
        duration = audio['duration'].to_i
        if duration < 120
          filename = File.basename audio_url
          uploaded=false
          unless uploaded
            puts "Grameenphone uploading bengali_audio #{audio_url}"
            upload_bengali audio_url, 'audio'
          end
        end
      end
      ftp_close
    end
  
    def bengali_video
      url = searcher 'VOA 60 Bangla'
      url = "#{url}&language=bn&type=video"
      
      dir = "/bangla/video/news"
      delete_old dir
      
      ftp.mkdir_p dir
      ftp.chdir dir
      
      limit = 10
      options = {:language=>'bn',
                 :keywords=>'VOA 60 Bangla,voa 60 bangla',
                 :type=>'video',
                 :details=>2,
                 :limit=>limit}
      url = searcher options 
      txt = open(url, :read_timeout => 20).read
      hash = JSON.parse txt
      contents = hash['contents']
      (0..contents.size-1).each do |idx|
        video_url = contents[idx]['_embedded']['videos'][0]['url']
        filename = File.basename video_url
        uploaded=false
        unless uploaded
          puts "Grameenphone uploading bengali_video #{video_url}"
          upload_bengali video_url, 'video'
        end
      end
      ftp_close
    end
    
    protected

    def searcher options
      query = options.to_param
      # "http://cxp-api.bbg.gov/api/search?q=#{query}&details=2&qf=keywords&limit=#{limit}"
      "http://cxp-api.bbg.gov/api/search?#{query}"
    end
  
    def upload_english_audio url
      filename = File.basename url
      begin
        files = ftp.list(filename)
        puts "  #{filename} upload_english_audio #{files}"
        if files.empty?
          ftp_putbinaryfile(url, filename)
        end
      rescue
        puts "  Not Exists #{filename}"
        begin
          ftp_putbinaryfile(url, filename)
        rescue
        end
      end
    end

    def upload_english_video url, dir
      filename = File.basename url
      puts "Grameenphone uploading #{dir}/#{filename}"
      begin
        files = ftp.list(filename)
        if files.empty?
          ftp_putbinaryfile(url, filename)
        end
      rescue
        puts "  Not Exists #{filename}"
        ftp_putbinaryfile(url, filename)
      end
    end
  
    def upload_bengali url, asset
      filename = File.basename url
      ftp_putbinaryfile(url, filename)
    end
    
    def config
      @conf ||= YAML.load_file(File.join(Rails.root,'config/grameenphone.yml'))[Rails.env].deep_symbolize_keys
    end

    def force_upload
      config[:force_upload]
    end

    def ftp
      if @ftp
        return @ftp
      end
      @ftp = BetterFTP.new(config[:host],config[:user], config[:pass])
      @ftp.passive = true
      @ftp.read_timeout = config[:read_timeout]
      @ftp.open_timeout = config[:open_timeout]
      @ftp
    end
    
    def ftp_close 
      @ftp.close if @ftp
      @ftp = nil
    end
    
    def ftp_putbinaryfile(url, filename)
      begin
        ftp.putbinaryfile(url, filename)
      rescue
      end
    end
    
    def delete_old dir
      files = ftp.nlst(dir)
      files.each do |file|
        date = ftp.mtime(file)
        # puts " File created on: #{date}"
        if date < 7.days.ago
          # ftp.delete file
          puts " Deleted #{file} - created #{date}"
        end
      end
    end
  end
end
