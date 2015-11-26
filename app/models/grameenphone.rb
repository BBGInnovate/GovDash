require 'open-uri'
class Grameenphone
  class << self
    cattr_accessor :message
    
    def check_status
      dir = '/english/video/science'
      max_date = 1.day.ago
      ftp.nlst(dir).each do | file |
        date = ftp.mtime(file)
        if date > max_date
          max_date = date
        end
      end 
      puts " Grameenphone english/video/science #{max_date}"
      if max_date < 1.hour.ago
        to = ['liwliu@bbg.gov','dzabransky@bbg.gov']
        msg = 'Grameenphone english/video/science is not updated in 1 hour'
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
      puts "   english_audio #{url}"
      txt = open(url, :read_timeout => 20).read
      hash = JSON.parse txt
      contents = hash['contents']
      force_upload = true
      (0..contents.size-1).each do |idx|
        audio_url = contents[idx]['_embedded']['audios'][0]['url']
        # only force to upload the most recent item, even it exixts
        ftp_putbinaryfile audio_url, force_upload
        filename = File.basename audio_url
        if !ftp.list(filename).empty?
          force_upload = false
        end
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
        puts "   english_video #{url}"      
        txt = open(url, :read_timeout => 20).read
        hash = JSON.parse txt
        contents = hash['contents']
        force_upload = true
        (0..contents.size-1).each do |idx|
           videos = contents[idx]['_embedded']['videos']
           videos.each do | v |
             if v['quality'] == 'hq'
               video_url = v['url']
               ftp_putbinaryfile video_url, force_upload
               filename = File.basename video_url
               if !ftp.list(filename).empty?
                 force_upload = false
               end
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
      puts "   bengali_audio #{url}"     
      txt = open(url, :read_timeout => 20).read
      hash = JSON.parse txt
      contents = hash['contents']
      force_upload = true
      (0..contents.size-1).each do |idx|
        audio = contents[idx]['_embedded']['audios'][0]
        audio_url = audio['url']
        duration = audio['duration'].to_i
        if duration < 120
          # puts "Grameenphone uploading bengali_audio #{audio_url}"
          ftp_putbinaryfile audio_url, force_upload
          filename = File.basename audio_url
          if !ftp.list(filename).empty?
            force_upload = false
          end
        end
      end
      ftp_close
    end
  
    def bengali_video
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
      puts "   bengali_video #{url}"     
      txt = open(url, :read_timeout => 20).read
      hash = JSON.parse txt
      contents = hash['contents']
      force_upload = true
      (0..contents.size-1).each do |idx|
        video_url = contents[idx]['_embedded']['videos'][0]['url']
        filename = File.basename video_url
        uploaded=false
        unless uploaded
          # puts "Grameenphone uploading bengali_video #{video_url}"
          ftp_putbinaryfile video_url, force_upload
          filename = File.basename video_url
          if !ftp.list(filename).empty?
            force_upload = false
          end
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
      ftp_putbinaryfile(url)
    end

    def upload_english_video url
      # puts "Grameenphone uploading #{dir}/#{filename}"
      ftp_putbinaryfile(url)
    end
  
    def upload_bengali url
      ftp_putbinaryfile(url)
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
    
    def ftp_putbinaryfile(url, force_upload=false)
      filename = File.basename url
      files = ftp.list(filename)
      if force_upload || files.empty?
        begin
          ftp.putbinaryfile(url, filename)
          date = ftp.mtime(filename)
          puts " #{ftp.pwd} #{date} uploaded #{url}" 
        rescue Exception=>ex
          puts ex.message
        end
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
