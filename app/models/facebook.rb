class Facebook < ActiveRecord::Base
  has_many :subscriptions

  cattr_accessor :app_token
  
  def profile
    @profile ||= FbGraph::User.me(self.access_token).fetch
  end

  class << self
    def not_empty? text
      !!text && !text.strip.empty?
    end
    
    def config(env=Rails.env)
      @config = 
        cnf = YAML.load_file("#{Rails.root}/config/facebook.yml")[env].symbolize_keys
        # add email, client_id, client_secret, canvas_url to Accounts table
        if app_token
           client_id=app_token.client_id if not_empty?(app_token.client_id) 
           client_secret=app_token.client_secret if not_empty?(app_token.client_secret)
           canvas_url = app_token.canvas_url || 'ads.localhost.com'
           cnf = {:client_id=>client_id,
                  :client_secret=>client_secret,
                  :name=>app_token.facebook_accounts[0].name,
                  :scope=> cnf[:scope],
                  :canvas_url=>canvas_url}
        end
        cnf
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
