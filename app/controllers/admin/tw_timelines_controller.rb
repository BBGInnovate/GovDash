require 'json'
# require 'dhtml_confirm'
# require Rails.root.to_s + '/vendor/plugins/active_scaffold/lib/active_scaffold/data_structures/action_link'

class Admin::TwTimelinesController < Admin::BaseController
  skip_before_filter :authenticate_user!
  skip_before_filter :is_service_chief?
  respond_to :html, :json
  
  active_scaffold :tw_timeline do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    config.list.sorting = {:tweet_created_at => :desc}
     
    config.columns = TwTimeline.columns.map{|a| a.name}
    config.create.columns.exclude :id
    config.update.columns.exclude :id, :tweet_created_at

    config.actions.exclude :create, :search,:delete
    config.list.per_page = 100

  end
end
