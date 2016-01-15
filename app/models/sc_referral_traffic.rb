#SiteCatalyst Refferal Traffic Reports
class ScReferralTraffic < Account
	belongs_to :sc_segment
	self.table_name = "sc_referral_traffic"

	def self.sitecatalyst_conf
		@sitecatalyst_conf ||= YAML.load_file("#{Rails.root}/config/sitecatalyst.yml")[Rails.env].symbolize_keys
	end

	#create an omniture client
	@client = OmnitureClient.new(
			ScReferralTraffic.sitecatalyst_conf[:username],
			ScReferralTraffic.sitecatalyst_conf[:shared_secret],
			:portland,
			:verify_mode=> nil,
			:log => true,
			:wait_time => 1 
	)

	#Retreive/Store a Referral Traffic Segment Report from Sitecatalyst
	def self.get_daily_report
		started = Time.zone.now
		#counter for the number of successful reports retrieved
     	count = 0
     	#counter for the total number of accounts tried
     	size = 0
		server = ActionMailer::Base.default_url_options[:server]

     	date_str = Time.now.in_time_zone("Pacific Time (US & Canada)").strftime("%Y-%m-%d")
     	#eager load accounts to check if a new segement was added
     	accounts = Account.eager_load(:sc_segments).order('accounts.id ASC')
		accounts.each do |a|
			if a.new_item?
				#new segment relationship, get previous six months reports for archive
				a.sc_segments.each do |seg|
					if seg.sc_id
						archive_started = Time.zone.now
						success = get_archive_report seg
						archive_ended = Time.zone.now
						archive_total_seconds=(archive_ended-archive_started).to_i
						duration=Time.at(archive_total_seconds).utc.strftime("%H:%M:%S")
						msg = "#{server} : Account segments archival data fetched for Account #{a.id}. Started: #{archive_started.to_s(:db)} Duration: #{duration}"
						level = success ? 0 : 5
						log_error msg,level
						if success
							#update the segment's new_time flag
							account_seg = AccountsScSegment.where(
								account_id: a.id, 
								:sc_segment_id => seg.id,
								:new_item => true
								).update_all( new_item: false ) rescue nil
						end
					end
				end
			else
				#get today's report
				a.sc_segments.each do |seg|
					if seg.sc_id
						size += 1
						success = retrieve seg, date_str
						unless success.nil?
							count += 1
						end
					end
				end
			end
		end

		ended = Time.zone.now
		total_seconds=(ended-started).to_i
		duration=Time.at(total_seconds).utc.strftime("%H:%M:%S")
		msg = "#{server} : #{count} out of #{size} Account segments fetched. Started: #{started.to_s(:db)} Duration: #{duration}"
		level = ((size-count)/2.0).round % size
		log_error msg,level

	end

	#Retreive/Store previous six months Referral Traffic Segment Reports from Sitecatalyst
	def self.get_archive_report seg
		if seg.sc_id
			#go back 185 days (6 months)
			((Date.today - 185).to_date..Date.today.to_date).each do |d|
				date_str = d.strftime("%Y-%m-%d")
				logger.debug "get_archive_report for #{date_str}"
				report = retrieve seg, date_str
			end
		end
	end

	def self.retrieve seg, date_str
		#build reportDescription for SiteCatalyst 
		logger.debug "ScReferralTraffic.retrieve processing Segment: #{seg.sc_id} for #{date_str}"
		report_desc = {
			"reportDescription" => {
			"reportSuiteID" => "bbgprod",
			"dateFrom" => date_str,
			"dateTo" => date_str,
			"dateGranularity" => "day",
			"metrics" => [
				{
					"id" => "Visits"
				}
			],
		 	"elements" => [
				{
					"id" => "referringdomain",
					"selected" => [
						"facebook.com", 
						"twitter.com",
						"t.co"
					]
		 		}
		 	],
		 	"segments" => []
		 	}
		}
		#append the segment ID to reportDescription
		report_desc['reportDescription']['segments'].push( {"id" => seg.sc_id} )

		@response = {}
		#get report from sitecatalyst
		@response = @client.get_report report_desc

		report_data = Hash.new
		report_data['facebook_count'] = 0
		report_data['twitter_count'] = 0
		report_data['sc_segment_id'] = seg.id
		#get final report data from ['report']['data']['breakdown']

		unless @response['report']['data'][0].nil?
			data = @response['report']['data'][0]
			data['breakdown'].each do |item|
				if(item['name'] == 'facebook.com')
					report_data['facebook_count'] = report_data['facebook_count'] + item['counts'][0].to_i
				elsif(item['name'] == 'twitter.com' || item['name'] == 't.co')
					report_data['twitter_count'] = report_data['twitter_count'] + item['counts'][0].to_i
				end
			end
		end

		report_date = date_str.to_date
		existing_report = ScReferralTraffic.where(
			sc_segment_id: seg.id, 
			:created_at => report_date.beginning_of_day..report_date.end_of_day
			).take! rescue nil

		if existing_report
			#Update existing daily report
			report = existing_report.update(report_data)
			#existing_report.touch
		else
			#Save a new report
			report_data['created_at'] = report_date
			report_data['updated_at'] = Time.zone.now
			# report = ScReferralTraffic.new(report_data)
			report = ScReferralTraffic.find_or_create_by report_data
		end
		report
	end

	#get archive reports for a particular account
	def self.get_account_archive_reports account_id
		#get previous six months reports for archive
		server = ActionMailer::Base.default_url_options[:server]
		a = Account.find(account_id)
		a.sc_segments.each do |seg|
			if seg.sc_id
				archive_started = Time.zone.now
				success = get_archive_report seg
				archive_ended = Time.zone.now
				archive_total_seconds=(archive_ended-archive_started).to_i
				duration=Time.at(archive_total_seconds).utc.strftime("%H:%M:%S")
				msg = "#{server} : Account segments archival data fetched for Account #{a.id}. Started: #{archive_started.to_s(:db)} Duration: #{duration}"
				level = success ? 0 : 5
				log_error msg,level
			end
		end

	end

	#Get the current user's Sitecatalyst Enviroment (i.e. "https://api5.omniture.com/admin/1.4/rest/")
	def get_endpoint
		@response = @client.request("Company.GetEndpoint")
 		#render :text=>@response, :layout => false
	end


end