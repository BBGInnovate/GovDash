class Api::V1::FbPageResultsController < Api::V1::BaseController
  # before_filter :authenticate_user!
  #before_filter :is_analyst?

  def record
    paths = params[:path].split('/') # "voiceofamerica/14/05/23
    error = "Format voiceofamerica/14/05/26"
    if paths.size != 4
      raise error
    end
    obj_id = paths[0]
    y = paths[1]
    m = paths[2]
    d = paths[3]
    date_begin = Time.parse("#{y}-#{m}-#{d}").beginning_of_day
    date_end = date_begin.end_of_day
    fbpage = FbPage.find_by_name(obj_id)
    
    if fbpage
      data = fbpage.fb_page_results.where("report_date between '#{date_begin}' AND '#{date_end}'").first
      if data
        respond_to do |format|
          format.json { render :json=>data, :layout => false }
        end
      else
        generic_exception(Exception.new('No record found'))
      end
    else
      generic_exception(Exception.new(error))
    end
  end
  
  private
  def fb_page_result_params
    cols = model_class.columns.map{|a| a.name.to_sym}.join(',')
    params.require(:fb_page_result).permit(cols)
  end

end
