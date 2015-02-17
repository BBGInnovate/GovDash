require 'json'
# require 'dhtml_confirm'
# require Rails.root.to_s + '/vendor/plugins/active_scaffold/lib/active_scaffold/data_structures/action_link'

class Admin::AccountsController < Admin::BaseController
  before_filter :action_links_order
  respond_to :html, :json
  
  active_scaffold :account do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    
    config.columns = Account.columns.map{|a| a.name}
    # config.columns = []
    config.list.columns.exclude :user_access_token, :description,:account_type_id,
       :client_id, :client_secret,:canvas_url,:created_at,:page_admin,:contact
    config.create.columns.exclude :id
    config.update.columns.exclude :id

    config.actions.exclude :create, :search, :update,:delete
    config.list.per_page = 100

  end
 
=begin 
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
       logger.debug "stop_producers: #{$!}"
     end
     redirect_to('/admin/accounts') and return
  end
=end
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
 #     :dhtml_confirm=>DhtmlConfirm.new({:message=>'Are you sure to restart all scheduled jobs?',
 #        :url=>'/admin/schedulers/restart_all'}),
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
