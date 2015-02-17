class Admin::ErrorLogsController < Admin::BaseController
  skip_before_filter :authenticate_user!
  
  #layout "regular"
  respond_to :html, :json
  
  active_scaffold :error_log do |config|
    config.list.columns = :subject,:message,:severity,:created_at
    config.list.sorting = {:created_at => :desc}
    config.actions.exclude :search, :create,:update,:delete
    config.list.per_page = 100
    
    config.action_links.add 'fetch',
      :label => 'Fetch stats',
      :security_method => 'show?',
      :type => :member,
      :page => false
  end
  
  def fetch
    err = ErrorLog.find_by id: params[:id]
    err.subject.match /\(ID: (\d+)\)/
    account_id = $1
    @account = Account.find_by_id account_id
    @account.class.name.match /(.*)Account/
    @aname = $1
    begin
      ret = @account.retrieve
      status = ret ? 1 : 0
      subject="#{@aname} #{@account.object_name} (ID: #{@account.id}) #{ret}"
      message = subject
      @new_log = ErrorLog.to_error subject,message,0
      text="<p id='fetch'>Retrieve #{@account.object_name} returned #{ret}</p>"
      
    rescue Exception=>error
      status = 0
      text="<p id='fetch'>Retrieve #{@aname} #{@account.object_name} returned #{error.message}</p>"  
    end
    hash= {:status=>status,
           :id=>@account.id,
           :text=>text
          }
    if status == 1
      hash[:row] = new_row
    end
    render :json=>hash.to_json,
             :content_type=>"text",
             :layout=>false
  end
  
  protected
  
  def show? record=nil
    record.subject.match /\(ID: (\d+)\)/
    (record.severity != 0) && $1
  end
  
  def new_row
    sub = "#{@aname} #{@account.object_name} (ID: #{@account.id}) Success "
    html=%{<tr id="as_admin__error_logs-list-#{@new_log.id}-row" class="record " data-refresh="#{@new_log.id}">
    <td class="subject-column "> #{sub} </td>
    <td class="message-column "> #{sub} </td>
    <td class="severity-column numeric "> 0 </td>
    <td class="created_at-column sorted "> #{@new_log.created_at} </td>
    <td class="actions"></td></tr>}
    html.html_safe
  end
end
