# Updated "ROmniture" project for use with Sitecatalyst API v1.4
class OmnitureClient

    DEFAULT_REPORT_WAIT_TIME = 0.25

    ENVIRONMENTS = {
      :san_jose       => "https://api.omniture.com/admin/1.4/rest/",
      :dallas         => "https://api2.omniture.com/admin/1.4/rest/",
      :london         => "https://api3.omniture.com/admin/1.4/rest/",
      :portland       => "https://api5.omniture.com/admin/1.4/rest/",
      :singapore      => "https://api4.omniture.com/admin/1.4/rest/",
      :san_jose_beta  => "https://beta-api.omniture.com/admin/1.4/rest/",
      :dallas_beta    => "https://beta-api2.omniture.com/admin/1.4/rest/",
      :sandbox        => "https://api-sbx1.omniture.com/admin/1.4/rest/"
    }    
    
    def initialize(username, shared_secret, environment, options={})
      @username       = username
      @shared_secret  = shared_secret
      @environment    = environment.is_a?(Symbol) ? ENVIRONMENTS[environment] : environment.to_s

      @wait_time      = options[:wait_time] ? options[:wait_time] : DEFAULT_REPORT_WAIT_TIME
      @log            = options[:log] ? options[:log] : false
      @verify_mode    = options[:verify_mode] ? options[:verify_mode] : false
      HTTPI.log       = false
    end
        
    def request(method, parameters = {})
      # response = https_post(method, parameters)
      response = send_request(method, parameters)

      begin
        JSON.parse(response.body)
      rescue JSON::ParserError => pe
        response.body
      rescue Exception => e
        log(Logger::ERROR, "Error in request response:\n#{response.body}")
        raise "Error in request response:\n#{response.body}"
      end
    end
    
    def get_report(report_description)
      begin     
        response = request("Report.Queue", report_description)
        
        if response['reportID']
           response = get_queued_report response['reportID']
            
           if !response.kind_of?(Hash)
             log(Logger::ERROR, "Report.Queue returned with error:\n#{response.inspect}")
           end
        end
      rescue
        log(Logger::ERROR, "Report.queue returned with error:\n#{$!.inspect}")
        raise "Report.Queue returned with error:\n#{$!.inspect}"
      end
      response
    end
    
    attr_writer :log
    
    def log?
      @log != false
    end
    
    def logger
      @logger ||= ::Logger.new(STDOUT)
    end
    
    def log_level
      @log_level ||= ::Logger::INFO
    end
    
    def log(*args)
      level = args.first.is_a?(Numeric) || args.first.is_a?(Symbol) ? args.shift : log_level
      logger.log(level, args.join(" ")) if log?
    end
        
    private
      
    def send_request(method, data)
      log(Logger::INFO, "Requesting #{method}...")
      generate_nonce
      
      log(Logger::INFO, "Created new nonce: #{@password}")
      
      request = HTTPI::Request.new

      if @verify_mode
        request.auth.ssl.verify_mode = @verify_mode
      end

      request.url = @environment + "?method=#{method}"
      
      request.headers = request_headers
      request.body = data.to_json

      response = HTTPI.post(request)
      
      if response.code >= 400
        log(:error, "Request failed and returned with response code: #{response.code}\n\n#{response.body}")
        raise "Request failed and returned with response code: #{response.code}\n\n#{response.body}" 
      end
      
      log(Logger::INFO, "Server responded with response code #{response.code}.")
      
      response
    end
    
    def generate_nonce
      @nonce          = Digest::MD5.new.hexdigest(rand().to_s)
      # @created        = Time.now.strftime("%Y-%m-%dT%H:%M:%SZ")
      @created        = 1.second.ago.strftime("%Y-%m-%dT%H:%M:%SZ")
      combined_string = @nonce + @created + @shared_secret
      sha1_string     = Digest::SHA1.new.hexdigest(combined_string)
      @password       = Base64.encode64(sha1_string).to_s.chomp("\n")
    end    

    def request_headers 
      {
        "X-WSSE" => "UsernameToken Username=\"#{@username}\", PasswordDigest=\"#{@password}\", Nonce=\"#{@nonce}\", Created=\"#{@created}\""
      }
    end
    
    def get_queued_report(report_id)
      done = false
      error = false
      status = nil
      start_time = Time.now
      end_time = nil

      begin
        log(Logger::INFO, "Checking on status of report #{report_id}...")
        begin
          response = self.request('Report.Get',{"reportID"=>report_id})
        rescue
          error = $!.message
          log(Logger::ERROR, "get_queued_report : #{error}") 
        end
        puts "RESPONSE #{response.inspect}" 
        if /comparison of Symbol/.match error.to_s
          status = 400
        end
        if response.kind_of? Hash
          error = false
          done = true
        end
        sleep @wait_time if !done
      end while !done
      
      if error
        msg = "get_queued_report : Unable to get data for report #{report_id}. Code: #{status}."
        log(Logger::INFO, msg)
        raise msg
      end
      end_time = Time.now
      log(Logger::INFO, "Report with ID #{report_id} has finished processing in #{((end_time - start_time)*1000).to_i} ms")
      
      response
    end
 
  end

