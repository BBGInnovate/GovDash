require 'json'
# require 'dhtml_confirm'
# require Rails.root.to_s + '/vendor/plugins/active_scaffold/lib/active_scaffold/data_structures/action_link'

class Admin::AccountsController < Admin::BaseController
  skip_before_filter :authenticate_user!
  skip_before_filter :is_analyst?
  # skip_before_filter :action_links_order
  # skip_before_filter :action_fetch
  respond_to :html, :json
  
  active_scaffold :account do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    
    config.columns = Account.
      columns.map{|a| a.name if a.name!='sc_segment_id'}.
      compact | [:regions,:countries,:sc_segments]
    # config.columns = []
    
    config.list.columns = [:id,:media_type_name,:object_name, :status,:updated_at,
    :network_id,:language_id,:regions,:countries,:sc_segments]

    config.list.columns.exclude :sc_segments
    config.update.columns.exclude :regions,:countries,:sc_segments
    
    config.create.columns.exclude :id
    config.update.columns.exclude :id
    config.actions.exclude :search, :delete
    config.list.per_page = 100
    
    config.columns[:media_type_name].label = 'Platform'
    
    # config.columns[:regions].actions_for_association_links = [:new, :list]
    # config.sti_children = [:facebook_account, :twitter_account]

    config.action_links.add 'fetch',
      :label => 'Fetch stats',
      :security_method => 'show?',
      :type => :member,
      :page => false

  end

  def fetch
    record = Account.find_by id: params[:id]
    ret = record.retrieve
    status = ret ? 1 : 0
    hash= {:status=>status,
           :id=>record.id,
           :text=>"<p id='fetch'>Retrieve #{record.object_name} returned #{ret}</p>"
          }
    render :json=>hash.to_json,
             :content_type=>"text",
             :layout=>false
  
  end
  
  def start_producers
    logger.debug "start_producers: started"
    `bundle exec clockworkd -c app/models/clock.rb start --log` 
    redirect_to('/admin/accounts') and return
  end
  def stop_producers
    pid = `pidof clockworkd.clock`.to_i
    begin
      logger.debug  `#{Rails.root}/gracefully-kill #{pid}`  if pid > 0
    rescue
      logger.debug "stop__producers: #{$!}"
    end
    redirect_to('/admin/accounts') and return
  end
  
  def start_consumer
    logger.debug "start_consumer: started"
    RabbitReceiver.receive
    redirect_to('/admin/accounts') and return
  end
  
  def stop_consumer
    pid = File.read 'tmp/receiver.id'
    if pid
      begin
        logger.debug  `#{Rails.root}/gracefully-kill #{pid}`
        File.delete("tmp/receiver.id") 
      rescue
        logger.debug "stop_consumer: #{$!}"
     end
      redirect_to('/admin/accounts') and return
    end
  end 
  
  # most recent insights is two days behind current time 
  # http://ads.localhost.com:3000/admin/accounts/insights/voakhmer.json
  def insights
    request.format = "json" unless params[:format]
    arr = []
    path = params[:path].split('/')
    obj_id = path[0]
    account = Account.find_by_object_name obj_id
    if account
      data = account.upload_insights
      data.each do |d|
        arr << d
      end
    end 
    respond_to do |format|
      format.json { render :json=>JSON.pretty_generate(arr), :layout => false }
    end
  end
  
  protected
  
  def action_fetch
    links = active_scaffold_config.action_links
    links.add 'fetch',
      :label => 'Fetch stats',
      :security_method => 'show?',
      :type => :member,
      :page => false

  end
  
  def show? record=nil
    if !record.is_active || 
      (record.media_type_name=='FacebookAccount' &&
        !record.page_access_token)
      false
    else
      !record.status
    end
  end
  
   # change link order
  def action_links_order
    links = active_scaffold_config.action_links
    
    links.add 'start_producers',
      :label => 'Start MQ Producers',
      :type => :collection,
      :security_method => 'clockworkd_norun?',
      :html_options => {:title => 'Start all producers'},
      :confirm => 'Are you sure to start all producers?',
      :page => true,
      :position => :top,
      :inline => false
      
    links.add 'stop_producers',
      :label => 'Stop MQ Producers',
      :type => :collection,
      :security_method => 'clockworkd_run?',
      :html_options => {:title => 'Stop all producers'},
      :confirm => 'Are you sure to stop all producers?',
      :page => true,
      :position => :top,
      :inline => false
      
    links.add 'start_consumer',
      :label => 'Start MQ Consumer',
      :type => :collection,
      :security_method => 'consumer_norun?',
      :html_options => {:title => 'Start consumer'},
      :confirm => 'Are you sure to start consumer?',
      :page => true,
      :position => :top,
      :inline => false
      
    links.add 'stop_consumer',
      :label => 'Stop MQ Consumer',
      :type => :collection,
      :security_method => 'consumer_run?',
      :html_options => {:title => 'Stop consumer'},
      :confirm => 'Are you sure to stopconsumer?',
      :page => true,
      :position => :top,
      :inline => false

  end
  
  def producer_norun?
     pid = File.read 'tmp/producer.id' rescue nil
     !pid
  end
  
  def producer_run?
     pid = File.read 'tmp/producer.id' rescue nil
     !!pid
  end
  
  def consumer_norun?
     pid = File.read 'tmp/receiver.id' rescue nil
     !pid
  end
  
  def consumer_run?
     pid = File.read 'tmp/receiver.id' rescue nil
     !!pid
  end
  
  def clockworkd_norun?
     `pidof clockworkd.clock`.to_i == 0
  end
  
  def clockworkd_run?
     `pidof clockworkd.clock`.to_i > 0
  end
  
   
end
