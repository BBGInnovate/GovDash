require "s3"

module S3
  def self.config
    unless @config
      creds = "#{Rails.root}/config/s3.yml"
      res = YAML.load_file(creds)
      # Environment specific definitions override global definitions
      res1  = symbolize_keys(res.merge(res.delete(Rails.env)))
      # delete entries other then for current environment
      envs = [:development, :qa, :test, :staging, :production]
      envs.each{|e| res1.delete e}
      access_key_id = res1.delete(:access_key_id)
      secret_access_key = res1.delete(:secret_access_key)
      res1[:s3_credentials]={:access_key_id=>access_key_id, :secret_access_key=>secret_access_key}
      @config = symbolize_keys res1
    end
    @config
  end
  
  def self.service
    @service ||= S3::Service.new(:access_key_id => self.config[:s3_credentials][:access_key_id],
                          :secret_access_key => self.config[:s3_credentials][:secret_access_key])
  end
  def self.symbolize_keys(hash)
    hash.inject({}){|res, (key, val)|
      nkey = case key
        when String
        key.to_sym
      else
        key
      end
      nval = case val
        when Hash, Array
        symbolize_keys(val)
      else
        val
      end
      res[nkey] = nval
      res
    }
  end
end
