require 'open-uri'
class Akamai
  # has_no_table
  
  def initialize
    @conf = self.class.config
    @ftp = BetterFTP.new(@conf[:host],@conf[:user], @conf[:pass])
    @ftp.passive = true
    @ftp.read_timeout =@conf[:read_timeout]
  end
  
  def check_status
    file = '/8475/mp3/voa/english/nnow/NNOW_HEADLINES.mp3'
    date = @ftp.mtime file
    if date < 70.minutes.ago
      to = ['liwliu@bbg.gov','dzabransky@bbg.gov']
      msg = 'Five minute audio is not updated in 70 minutes'
      UserMailer.alarm_email(to, msg).deliver_now!
    end
    puts "  NNOW_HEADLINES.mp3 #{date}"
  end
  
  def ftp_obj
    @ftp
  end

  # localfile = "2015/05/a/a5/a55788bf-8ecc-43df-a19a-3631e3856ec6.mp4"
  def copy_to_remote localfile, relative_pathname
    root = "/8475/MediaAssets2/bbg/direct/russians"
    dir = File.dirname relative_pathname
    full_dir = File.join root, dir
    basename = File.basename relative_pathname
    puts "  copy_to_remote #{full_dir} "
    @ftp.mkdir_p full_dir
    @ftp.chdir full_dir
    Rails.logger.info "  copy_to_remote #{localfile} , #{basename} "
    @ftp.putbinaryfile( localfile , basename )
  end
  #
  # below for cron in cxp-hub for voa headline news mp3
  # cronjob every hour at 10 minutes
  # */10 * * * * cd /home/oddev/hub/current && bundle exec rails runner -e production  'Akamai.voa_headline'  > /tmp/akamai-cron.log 2>&1
  def voa_headline
    # url = 'http://www.voanews.com/api/zym_ocutrrrrponktqdktqfjti!ktqey$_rrrpo'
    url = 'http://www.voanews.com/api/zym_ocutrrrrponpuqdvkifjti!ktqejqyrrrpp'
    txt = open(url, :read_timeout => 20)
    @xml_doc = Nokogiri::XML(txt) { |x| x.noblanks }
    pub_date = @xml_doc.root.xpath("channel/lastBuildDate").first.text
    pub_date = Time.zone.parse pub_date
    if File.exists? "/tmp/pangea_date.txt"
      tt = File.read "/tmp/pangea_date.txt"
      pre_date = Time.zone.parse tt
    else
      pre_date = 1.day.ago
    end
    # if pre_date < pub_date
      puts "Akamai uploading NNOW_HEADLINES.mp3"
      upload_voa_mp3
      File.write "/tmp/pangea_date.txt", pub_date.iso8601
    # end

  end
  
  protected
  
  def upload_voa_mp3
    dir = '/8475/mp3/voa/english/nnow'
    delete_old "#{dir}/archive"
    
    now_date=Time.zone.now.strftime('%Y-%m-%d')
    @ftp.mkdir_p "#{dir}/archive/#{now_date}"
    @ftp.chdir("#{dir}/archive/#{now_date}")
    
    videos = @xml_doc.root.xpath("channel/item/media:group/media:content")
    videos.each do | v |
        puts v['url']
        if v['url'].match /program_original/
          rfile = File.basename(v['url'])
          # make a backupcopy
          file_exist = false
          filepath = "#{dir}/archive/#{now_date}/#{rfile}"
          begin
            files = @ftp.list(filepath)
            puts "  upload_voa_mp3 #{files}"
            if files.empty?
              @ftp.putbinaryfile(open(v['url']), filepath)
            else
              file_exist = true
              puts "  Exists #{filepath}"
            end
          rescue
            begin
              @ftp.putbinaryfile(open(v['url']), filepath)
              puts "  Not Exists. Uploaded #{filepath}"
            rescue Exception=>ex
              puts ex.message
            end
          end
          if !file_exist
            @ftp.chdir(dir)
            @ftp.putbinaryfile(open(v['url']),'NNOW_HEADLINES.mp3')
            #
            # begin clip 2 min file
            a=AudioTranscoder.new v['url']
            f = '/tmp/NNOW_HEADLINES2min.mp3'
            a.clip f
            @ftp.putbinaryfile(f)
            puts "   Uploaded #{f}"
            # end clip 2 min file
            #
          end
          @ftp.close
          return
        end
    end
  end

  def delete_old dir
    begin
      files = @ftp.nlst(dir)
      files.each do |path|
        date = Date.parse(File.basename(path))
        if date < 1.month.ago
          # ftp.rm_r(path)
          puts " File deleted #{path}"
        end
      end
    rescue exception=>ex
      puts ex.message
    end
  end
    
  public
  
  class << self
    cattr_accessor :message
     
    def config
      @conf ||= YAML.load_file(File.join(Rails.root,'config/akamai.yml'))[Rails.env].deep_symbolize_keys
    end
    def root_dir
      config[:root_dir]
    end
    def force_upload
      config[:force_upload]
    end
    
    def delete_all localfile
      regex = config[:relative_dir_regex]
      relative_path = localfile.match(/#{regex}/)[3]
      remote_dir = config[:root_dir]
      path = File.join(remote_dir, relative_path)
      ftp_open
      begin
        ftp.rm_r path
      rescue Exception=>ex
        Rails.logger.error ex.message
      end
      ftp_close
    end
    def force_upload
      config[:force_upload]
    end
    
    def ftp
      ftp_open
    end
    
    def ftp_open
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
      if @ftp
        @ftp.close
        @ftp = nil
      end
    end

    # convert cxp-hub localfile pathname to akamai file pathname
    # /8475/MediaAssets2/bbg/direct/20150612/sample_iTunes/converted
    def local_to_remote local
      local.match /#{config[:relative_dir_regex]}/
      subdir = $2
      basename = File.basename local
      File.join(config[:root_dir], subdir, basename)
    end
    # convert cxp-hub localfile pathname to akamai url
    def local_to_remote_url local
      local.match /#{config[:relative_dir_regex]}/
      subdir = $2
      basename = File.basename local
      File.join(config[:root_path], subdir, basename)
    end
    # convert Akamai url to cxp-hub localfile pathname
    # http://www.voanews.com/MediaAssets2/bbg/direct/20150612/sample_iTunes/converted/sample_iTunes-hq.mp4
    def remote_url_to_local url
      url.match /(#{config[:root_path]})(.+)$/
      file = $2
      basename = File.basename file
      basename.match(/(\.\w+)$/)
      mimetype = GET_MIME[$1].match(/(audio|video)/)[1]
      File.join(Rails.root,'public', mimetype.pluralize, file)
    end
    # Test if file for url exists in Akamai
    # return akamai full url or nil
    # url is the media file url from Akamai. e.g.
    # http://www.voanews.com/MediaAssets2/bbg/direct/20150608/1_z6mr2rl7_1_afqagbms_1/converted/1_z6mr2rl7_1_afqagbms_1-web.mp4
    def file_exists? url
      if url.match(/^http/)
        localfile = remote_url_to_local url
      else
        localfile = url
      end
      remotefile = local_to_remote localfile
      begin
        localfile_size = File.size localfile
        remotefile_size = ftp.size  remotefile
        # puts "#{localfile}: #{localfile_size}"
        # puts "#{remotefile}: #{remotefile_size}"
        if remotefile_size == localfile_size
          url
        else
          nil
        end
      rescue Exception=>ex
        # puts ex.message
        nil
      end
    end
    
    def upload_bbg_direct localfile
      ### open ftp connection
      started = Time.now
      # ftp_open
      tries ||= 3
      if !file_exists?(localfile) || force_upload
        Rails.logger.info "Uploading #{localfile} to Akamai"
        remotefile = local_to_remote localfile
        dir = File.dirname remotefile
        ftp.mkdir_p dir
        begin
          ftp.chdir(dir)
          Timeout.timeout(config[:timeout]) do
            ftp.putbinaryfile(localfile, File.basename(localfile), 1024*64)
          end
          self.message = " Akamai uploaded #{File.basename(localfile)}"
        rescue Timeout::Error
          self.message = "File upload timed out #{(Time.now-started).to_i} sec. for: #{localfile}"
        rescue Net::FTPTempError=>ex
          tries -= 1
          if tries > 0
            retry
          else
            self.message = "File upload tried 3 times. #{ex.class.name} #{localfile} #{ex.message}"
          end    
        rescue Exception=>ex
          self.message = "File upload #{ex.class.name} #{localfile} #{ex.message}"
        ensure
          ### close ftp connection
          ftp_close
        end
      else
        self.message = "#{File.basename(localfile)} exists in Akamai"
      end
      ended = Time.now
      Rails.logger.info self.message
      Rails.logger.debug "  upload_bbg_direct done in #{(ended-started).to_i} seconds"
      local_to_remote_url localfile
    end
    # return full url path
    def securedftp localfile
      begin
        Net::SFTP.start(@conf[:host],'masset2', :password => 'masset2!media') do |sftp|
          sftp_mkdir sftp, dirs
          sftp.stat(remotefile) do |response|
            unless response.ok?
              sftp.upload!(localfile, remotefile)
            end
          end
        end
        local_to_remote_url localfile
      rescue Exception=>ex
        Rails.logger.error "securedftp #{localfile} - #{ex.message}"
        nil
      end
    end
    # create_directory recursively
    # loalfile: localfile full pathname 
    def sftp_mkdir sftp, localfile
      remotefile = local_to_remote localfile
      dir = File.dirname remotefile
      dir.match /#{config[:root_dir]}\/(.+)$/
      dirs = $1.split '/'
      new_dirs = []
      until dirs.empty? 
        new_dirs << dirs.join('/')
        dirs.pop
      end
      new_dirs.reverse!
      new_dirs.each do |d|   
        puts "sftp.mkdir! #{File.join(Akamai.config[:root_dir], d)}"
      end
    end
  end # end class methods
  
end

=begin
Net::SSH.start("54.242.144.62", "ubuntu", keys: ['/Users/lliu/.ssh/oddev.pem']) do |ssh|
  ssh.sftp.upload!("/Users/lliu/development/cxp_hub/Gemfile", "/tmp/Gemfile")
  ssh.exec! "ls -lrt /tmp/"
#  ssh.exec! "cd /some/path && tar xf /remote/file.tgz && rm /remote/file.tgz"
end

Net::SSH.start('host',
               :password=>'passwd', 
               :port=>1234,
               :username=>'user') do |ssh|
  ssh.exec! "ls -lrt /tmp/" 
end

require 'rubygems'
require 'net/sftp'

# the following code will recursively download the contents of a folder.

def open_or_get_all(sftp, open_dir, local_dir)
   handle = sftp.opendir(open_dir)
   items = sftp.readdir(handle)
   items.each do |item|
     if item.filename != '.' && item.filename != '..'
       if item.longname[0...1] == 'd'
         # mkdir locally
         Dir.mkdir(local_dir + item.filename, 0777)
         # open dir and download all
         open_or_get_all(sftp, open_dir + item.filename + '/', local_dir
+ item.filename + '/')
       else
         #puts local_dir+item.filename
         #puts open_dir+item.filename
         sftp.get_file  open_dir+item.filename, local_dir+item.filename
       end
     end
   end
   sftp.close_handle(handle)
end

Net::SFTP.start('host', 'user_name', 'password') do |sftp|
   open_or_get_all(sftp, "/home/user_name/dir_to_dnld/", "/lcl_dir/")
end
=end
