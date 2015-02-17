class Facebook < ActiveRecord::Base
  has_many :subscriptions

  cattr_accessor :account
  
  def profile
    @profile ||= FbGraph::User.me(self.access_token).fetch
  end

  class << self
    def not_empty? text
      !!text && !text.strip.empty?
    end
    
    def config
      @config = 
       if ENV['fb_client_id'] && ENV['fb_client_secret'] && ENV['fb_scope'] && ENV['fb_canvas_url']
        {
          :client_id     => ENV['fb_client_id'],
          :client_secret => ENV['fb_client_secret'],
          :scope         => ENV['fb_scope'],
          :canvas_url    => ENV['fb_canvas_url']
        }
      else
        cnf = YAML.load_file("#{Rails.root}/config/facebook.yml")[Rails.env].symbolize_keys

        # add email, client_id, client_secret, canvas_url to Accounts table
        if account
           client_id=account.client_id if not_empty?(account.client_id) 
           client_secret=account.client_secret if not_empty?(account.client_secret)
           canvas_url = account.canvas_url || 'ads.localhost.com'
           cnf = {:client_id=>client_id,
                  :client_secret=>client_secret,
                  :name=>account.name,
                  :canvas_url=>canvas_url}
        end

        cnf
      end
    rescue Errno::ENOENT => e
      raise StandardError.new("config/facebook.yml could not be loaded.")
    end

    def app
      FbGraph::Application.new config[:client_id], :secret => config[:client_secret]
    end

    def auth(redirect_uri = nil)
      FbGraph::Auth.new config[:client_id], config[:client_secret], :redirect_uri => redirect_uri
    end

    def identify(fb_user)
      _fb_user_ = find_or_initialize_by(identifier: fb_user.identifier.try(:to_s))
      _fb_user_.access_token = fb_user.access_token.access_token
      _fb_user_.save!
      _fb_user_
    end
  end

end
