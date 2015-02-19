require 'yaml'
require 'json'

class Api::V2::SitecatalystController < Api::V2::BaseController

	#Report = Struct.new(:reportSuiteID, :dateFrom, :dateTo, :dateGranularity, :metrics, :elements, :segments)

    def config
      @config = YAML.load_file("#{Rails.root}/config/sitecatalyst.yml")[Rails.env].symbolize_keys
    end

	def index
		params_arr = params[:path].split('/')
		show_report = (params_arr[0].downcase == 'show')
		if params_arr[1].downcase == 'account' and params_arr[2].to_i > 0
			@account_id = params_arr[2]
		end
		@report_date = params_arr[3]

		if show_report
			if @account_id
				#output sitecatalyst results for a given region and (optional) date range
				# i.e. /api/sitecatalyst/show/account/1/2014-07-15/
				do_show_report @account_id, @report_date
			end
		end
	end

	def do_show_report account_id, report_date
		@output = []
		@report_date = report_date ? Time.parse(report_date) : Time.zone.now
		#get the region report and output as JSON
		@account = Account.find_by_id(account_id)
		@output << @account
		sc_reports = []
		@account.sc_segments.each do |seg|
			seg_report = {}
			report = ScReferralTraffic.where(
				sc_segment_id: seg.id, 
				:created_at => @report_date.beginning_of_day..@report_date.end_of_day
				).take!
			report.attributes.each do |attr_name, attr_value|
				seg_report[attr_name] = attr_value
			end
			seg_report[:segment_name] = seg.name
			sc_reports << seg_report
		end
		@output << sc_reports
		pretty_respond @output.as_json and return
	end

end