require 'rack/oauth2'
require 'authentication'

=begin
undefined method `allow_forgery_protection' 
Since abstract_controller includes that module a config method is automatically created. 
If you have an action named 'config' then that would overrite this config and that's not good.

https://github.com/moomerman/twitter_oauth

https://rubygems.org/gems/twitter_oauth

http://michaelhallsmoore.com/blog/Getting-to-grips-with-the-Ruby-OAuth-gem-and-the-Twitter-API
=end

class TwittersController < ApplicationController
  include Authentication
  
  before_filter :require_authentication, :only => :destroy
  
  rescue_from Rack::OAuth2::Client::Error, :with => :oauth2_error
  helper_method :authenticated?
  
  def new
    session[:return_to] = params[:back] if params[:back]
    conf  = BasicOauth.config
    oauth_callback = request.protocol + request.host_with_port + conf[:callback_url]
    @request_token =  BasicOauth.consumer.get_request_token({:oauth_callback=>oauth_callback})
    session[:request_token] = @request_token.token
    session[:request_token_secret] = @request_token.secret
    
    url = @request_token.authorize_url
    url << "&oauth_callback=#{CGI.escape(oauth_callback)}" 
    redirect_to url
  end
  
  def create
    unless session[:request_token] && session[:request_token_secret] 
      authentication_failed('No authentication information was found in the session. Please try again.') and return
    end
    
    unless params[:oauth_token].blank? || session[:request_token] ==  params[:oauth_token]
      authentication_failed('Authentication information does not match session information. Please try again.') and return
    end
    
    user = identify_or_create_user
    
    # The request token has been invalidated
    # so we nullify it in the session.
    session[:request_token] = nil
    session[:request_token_secret] = nil
    redirect_to twitters_path
    
  rescue Net::HTTPServerException => e
    case e.message
      when '401 "Unauthorized"'
      authentication_failed('This authentication request is no longer valid. Please try again.') and return
    else
      authentication_failed('There was a problem trying to authenticate you. Please try again.') and return
    end
    
    
  end
  
  protected
  
  def conf
    @conf = YAML.load_file("#{Rails.root}/config/twitter.yml")[Rails.env].symbolize_keys
  end
    
  def identify_or_create_user
    @request_token = OAuth::RequestToken.new(BasicOauth.consumer, session[:request_token], session[:request_token_secret])
    oauth_verifier = params["oauth_verifier"]
    @access_token = @request_token.get_access_token(:oauth_verifier => oauth_verifier)
    puts "ACCSESS TOKEN: #{@access_token.inspect}"
    @user = TwitterUser.identify_or_create_from_access_token(@access_token)
  end
  
  def oauth2_error(e)
    flash[:error] = {
      :title => e.response[:error][:type],
      :message => e.response[:error][:message]
    }
    redirect_to root_url
  end
  
end
