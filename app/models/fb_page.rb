#
# this class is to get data from a facebook page
# first get top level likes, all posts
# require Rails.root.to_s + '/lib/read_page_detail'

class FbPage < ActiveRecord::Base
#  include ReadPageDetail
  belongs_to :account

  # prerequisite:
  # add to database.yml:
  #    redshift_development
  #    redshift_production
  # gem 'daemons'
  # gem 'delayed_job_active_record'
  # gem 'activerecord4-redshift-adapter'
  # gem 'pg'
  # run RAILS_ENV=production bin/delayed_job restart
  # uncomment after_save for sync record to AWS RedShift
  #
  # after_save :sync_redshift
  
  # 36235438073_10152175670143074
  def save_lifetime_data
    today = Time.zone.now
    if post_created_time > today.beginning_of_day &&
       post_created_time <= today.end_of_day
       # link = "https://graph.facebook.com/?id=http://www.voanews.com"
       link = "https://graph.facebook.com/?id=#{self.obj_name}"
       begin       
         response = fetch(link)
         json = JSON.parse response.body
         websites = json['website'].split(' ')
       rescue Exception=>error
         logger.error error.message
         return
       end
       
       shares = 0
       begin
         websites.each do |website|
           if !website.match(/http:\/\/|https:\/\//)
             website = "http://#{website}"
           end
           link = "https://graph.facebook.com/?id=#{website}"
           response = fetch(link)
           json = JSON.parse response.body
           shares += json['shares'].to_i
         end
       rescue Exception=>error
         puts "FbPAge#save_lifetime_data #{error.message}"
         puts "#{error.backtrace}"
       end
       @page = self.account.graph_api.get_object self.obj_name
       res = FbPage.where(:account_id=>self.account_id).select("sum(comments) AS comments").first
       
       self.update_attributes :total_shares=>shares, :total_likes=>@page['likes'], 
         :total_comments => res.comments,
         :total_talking_about=>@page['talking_about_count']
    end
  end
  
  def obj_name
    self.object_name.split('/')[0]
  end
  
  protected
  
  def sync_redshift
    attr = self.attributes
    RedshiftFbPage.create_or_update(attr)
  end
  # bin/delayed_job restart 
  # to clear cache of method create_or_update
  handle_asynchronously :sync_redshift, :run_at => Proc.new { 5.seconds.from_now }
  
  
  def fetch(url, limit = 3)
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = 180
       # http.set_debug_output($stdout)
    if uri.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    response = http.get(uri.request_uri)
    case response
       when (Net::HTTPOK || Net::HTTPSuccess)
          return response
       when Net::HTTPRedirection
          new_url = redirect_url(response)
          logger.debug "Redirect to " + new_url
          return fetch(new_url, limit - 1)
       else
         response.error!
    end
    response
  end

end





