require 'google/api_client/client_secrets'

class HomeController < ApplicationController
  respond_to :html
  layout "angular"

  def index

  end
  
  def create
    provider = params[:provider]
    auth = request.env["omniauth.auth"]
    data = auth["credentials"]
    # ss= request.env['omniauth.strategy'].public_methods - Object.public_methods
    # ss.sort.each{|a| p a}
    scope = request.env['omniauth.strategy'].options.scope
    logger.info " scope #{scope}"

    #<OmniAuth::AuthHash expires=true expires_at=1454504148 refresh_token="1/BHvJHzejNsc_yWqi0ka3Y2BuIkWhbt7CwyVFzEF4SoE" token="ya29.fQJZLlL1F3083PeBVRQLTsv7Dxc1Vt18tDcpfvRgwVNAkWPUv2G9pK7uC0TQ39xcL3Fa">
    attr = {:email=>auth['extra']['id_info']["email"],
            :token=>data['token'],
            :expires_at=>Time.at(data['expires_at']),
            :expires=>data['expires']}
    if data['refresh_token']
      attr[:refresh_token] = data['refresh_token']
    end
    attr[:scope] = scope
    attr[:provider] = provider
    rec = GoogleAccessToken.find_by provider: provider, email: attr[:email], scope: attr[:scope]
    if rec
      [:provider, :email, :scope].each do |ar|
         attr.delete ar
      end
      rec.update_attributes attr
    else
      GoogleAccessToken.create attr
    end
    # @user = User.from_omniauth(auth)
    # sign_in_and_redirect @user
    render text: data['token']
  end
  def oauth2callback
    @auth = request.env['omniauth.auth']['credentials']
    p @auth
    
    code = params[:code]
    p "  oauth2callback code=#{code}"
    client_secrets = Google::APIClient::ClientSecrets.load "config/client_secrets.json"
    auth_client = client_secrets.to_authorization
    auth_client.update!(
      :scope => 'https://www.googleapis.com/auth/drive.metadata.readonly',
      :redirect_uri => 'http://localhost:3000/oauth2callback'
    )
    if !code
      auth_uri = auth_client.authorization_uri.to_s
      redirect_to(auth_uri, status: 303)
    else
      auth_client.code = code
      token = auth_client.fetch_access_token!
      # auth_client.client_secret = nil
      # session[:credentials] = auth_client.to_json
      render text: token
    end
  end
  
end
