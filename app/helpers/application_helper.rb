module ApplicationHelper

  def current_sign_in_at_column(record, input_name)
    record.current_sign_in_at.to_s(:db) rescue ''
  end
  def last_sign_in_at_column(record, input_name)
    record.last_sign_in_at.to_s(:db) rescue ''
  end
  def reset_password_sent_at_column(record, input_name)
    record.reset_password_sent_at.to_s(:db) rescue ''
  end
  
  def tweet_created_at_column(record, input_name)
    record.tweet_created_at.to_s(:db)
  end
  
  def post_created_time_column(record, input_name)
    record.post_created_time.to_s(:db)
  end
  
  def created_at_column(record, input_name)
    record.created_at.to_s(:db)
  end
   
  def updated_at_column(record, input_name)
    record.updated_at.to_s(:db)
  end
   
  def is_active_column(record, input_name)
    record.is_active ? 'Y' : 'N'
  end
  
  def account_id_column(record, input_name)
    if record.respond_to? :account_id
      record.account.name
    else
      record.id
    end
  end
  def media_type_name_column(record, input_name)
    record.media_type_name.match /(\w+)Account/
    $1
  end
  def service_id_column(record, input_name)
    if Service === record
      record.id
    else
      record.service.name
    end
  end
  def network_id_column(record, input_name)
    if Network === record
      record.id
    else
      record.network.name
    end
  end
  def region_id_column(record, input_name)
    if Region === record
      record.id
    else
      record.region.name
    end
  end
  def account_type_id_column(record, input_name)
    if AccountType === record
      record.id
    else
      record.account_type.name
    end
  end
  def country_id_column(record, input_name)
    if Country === record
      record.id
    else
      record.country.name
    end
  end
  def language_id_column(record, input_name)
    if Language === record
      record.id
    else
      record.language.name
    end
  end
  def user_id_column(record, input_name)
    if User === record
      record.id
    else
      record.user.name
    end
  end
  
  def status_column(record, input_name)
    if Account === record
      if (record.updated_at < Time.zone.now - 12.hours) &&
        !!record.status && !!record.is_active
        old_updated = record.updated_at
        record.update_attributes status: false, updated_at: old_updated
      end
      klass = (record.status || !record.is_active) ? 'green-light' : 'red-light'
      if record.media_type_name=='FacebookAccount' &&
        !record.page_access_token
        klass = 'green-light'
      end
      img = (record.status) ? 'green.png' : 'red.png'
      "<img id='red-green_#{record.id}' src='/assets/#{img}' class='#{klass}' height='15' width='15' />".html_safe
    else
      "not defined here"
    end
  end
  
  def media_type_name_form_column(record, input_name)
      select_tag 'record[media_type_name]', options_for_select(MediaType.all.map{|c| [c.name,c.name]},record.media_type_name),:multiple => false,:readonly=>true
  end
  def account_id_form_column(record, input_name)
      select_tag 'record[account_id]', options_for_select(Account.where(:is_active=>true).map{|c| ["#{c.name}",c.id]},record.account_id.to_s),:multiple => false,:readonly=>true
  end
  def service_id_form_column(record, input_name)
      select_tag 'record[service_id]', options_for_select(Service.where(:is_active=>true).map{|c| ["#{c.name}",c.id]},record.service_id.to_s),:multiple => false,:readonly=>true
  end
  def network_id_form_column(record, input_name)
      select_tag 'record[network_id]', options_for_select(Network.where(:is_active=>true).map{|c| ["#{c.name}",c.id]},record.network_id.to_s),:multiple => false,:readonly=>true
  end
  def account_type_id_form_column(record, input_name)
    select_tag 'record[account_type_id]', options_for_select(AccountType.all.map{|c| ["#{c.name}",c.id]},record.account_type_id.to_s),:multiple => false,:readonly=>true
  end
  
  def language_id_form_column(record, input_name)
    select_tag 'record[language_id]', options_for_select(Language.all.map{|c| ["#{c.name}",c.id]},record.language_id.to_s),:multiple => false,:readonly=>true
  end
  
  def region_id_form_column(record, input_name)
      select_tag 'record[region_id]', options_for_select(Region.all.map{|c| ["#{c.name}",c.id]},record.region_id.to_s),:multiple => false,:readonly=>true
  end
  def country_id_form_column(record, input_name)
    select_tag 'record[country_id]', options_for_select(Country.all.map{|c| ["#{c.name}",c.id]},record.country_id.to_s),:multiple => false,:readonly=>true
  end
  
  def user_id_form_column(record, input_name)
      select_tag 'record[user_id]', options_for_select(User.all.map{|c| ["#{c.name}",c.id]},record.user_id.to_s),:multiple => false,:readonly=>true
  end
  
end
