class Api::V1::ServicesController < Api::V1::BaseController
  # before_filter :authenticate_user!
  #before_filter :is_analyst?

  private
  def service_params
    _params_
  end
  
=begin
  def index 
    # respond_with(model_class.all)
    arr = []
    model_class.all.each do |s|
      arr << s.attributes
    end
    pretty_respond arr
  end

  def show
    data = model_class.find(params[:id])
    # respond_with(data.json_obj)
    pretty_respond data.json_obj
  end

  def new
    @service = model_class.new
    respond_to do |format|
      format.html {render :layout=>'regular'}
    end
  end
  
  def edit
    @service = model_class.find params[:id]
    respond_to do |format|
      format.html {render :layout=>'regular'}
    end
  end
  
  def update 
    @data = model_class.find(params[:id])
    respond_to do |format|
      if @data.update_attributes(network_params)
        format.json {  render :json=>{:error=>"Created successfully"},
             :content_type=>"text",
             :layout=>false
             }
      else
        format.json { 
             render :json=>{:error=>@data.errors.to_json},
             :content_type=>"text",
             :layout=>false
             }
      end
    end
  end

  def create
    begin
      @data = model_class.new service_params
    rescue
      logger.error "ERR: ServicesController#create #{$!}"
    end
    
    respond_to do |format|
      if @data.valid?
        @data.save
        format.json {
             render :json=>{:error=>"Created successfully"},
             :content_type=>"text",
             :layout=>false
             }
      else
        format.json { 
             render :json=>{:error=>@data.errors.to_json},
             :content_type=>"text",
             :layout=>false
             }
      end
    end
  end

  def destroy
    @data = model_class.find(params[:id])
    @data.destroy
    respond_to do |format|
      format.json  { head :ok }
    end
  end
=end
  
end
