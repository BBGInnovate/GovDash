angular.module('reportService', [])
    .factory('Reports', function($location, $http, $q, $rootScope, $filter) {
       
        var report = {
          
            getData: function(regionIds, countryIds, languageIds, groupIds, startDate, endDate) {
            
                return $http.post('/api/reports', {options: {source: "all", country_ids: countryIds, region_ids: regionIds, language_ids: languageIds, group_ids: groupIds, start_date: startDate, end_date: endDate } })
                .then(function(response) {
                
                	if (Object.getOwnPropertyNames(response.data).length > 0) {
                		var firstObj = response.data[Object.getOwnPropertyNames(response.data)[0]];
                		
                		// This report object is dynamically built based off of what is
                		// passed to it by the backend and it handles aggregations
                		// and chart data here so the controller only has to make calls
                		// to the functions with arrays and generate the charts / tables
                		var report = {};
                		
                		report.chart_data = {};
                		
                		if (response.data['facebook']) {
							var facebookObj = response.data['facebook'];
							var facebookTotals = facebookObj['values']['period'][0].totals;
							var facebookCurrData = facebookObj['values']['period'][0];
							var facebookTrendData = facebookObj['values']['trend'];
							report.facebook = {
								"change_percent": facebookCurrData['changes'].totals,
								"current_data": facebookObj['values']['period'][0],
								"accounts": facebookObj['values']['accounts'],
								"daily_trend": facebookTrendData
							};
						
							report.chart_data.facebook_breakdown_data = [
								 
									["", "Engagement Actions", { role: "style" } ],
									["Comments", facebookCurrData.comments, '#45619D'],
									["Story Likes", facebookCurrData.story_likes, '#45619D'],
									["Shares", facebookCurrData.shares, '#45619D'],
									["Page Likes", facebookCurrData.page_likes, '#45619D']
								
							
							];
							
							report.chart_data.amount_chart = [
								 
								["", "Engagement Actions", { role: "style" } ],
								["", 0 + facebookTotals, $filter('chartColor')('All')], 
								["", facebookTotals, $filter('chartColor')('Facebook')],					 
								["", 0, $filter('chartColor')('Twitter')]		
								
							
							];
							
							report.chart_data.daily_trend = {
								"all": facebookTrendData,
								"facebook": facebookTrendData,
								"twitter": []
							};
							
						}
						
						if (response.data['twitter']) {
					
							var twitterObj = response.data['twitter'];
							var twitterTotals = twitterObj['values']['period'][0].totals;
							var twitterCurrData = twitterObj['values']['period'][0];
							var twitterTrendData = twitterObj['values']['trend'];
							
							report.twitter = {
								"change_percent": twitterCurrData['changes'].totals,
								"current_data": twitterObj['values']['period'][0],
								"accounts": twitterObj['values']['accounts'],
								"daily_trend": twitterTrendData
							};
						
							
							report.chart_data.twitter_breakdown_data = [
								 
								["", "Engagement Actions", { role: "style" } ],
								["Retweets", twitterCurrData.retweets, '#55ACEE'],
								["@Mentions", twitterCurrData.mentions, '#55ACEE'],
								["Favorites", twitterCurrData.favorites, '#55ACEE'],
								["Followers", twitterCurrData.followers, '#55ACEE']
								
							
							];
							
							report.chart_data.amount_chart = [
								 
								["", "Engagement Actions", { role: "style" } ],
								["", 0 + twitterTotals, $filter('chartColor')('All')], 
								["", 0, $filter('chartColor')('Facebook')],					 
								["", twitterTotals, $filter('chartColor')('Twitter')]		
								
							
							];
							
							report.chart_data.daily_trend = {
								"all": twitterTrendData,
								"facebook": [],
								"twitter": twitterTrendData
							};
							
							
						
						}
						
						if (response.data['sitecatalyst']) {
						
							var siteCatalystObj = response.data['sitecatalyst'];
							var siteCatalystTotals = siteCatalystObj['values']['period'][0];
							var siteCatalystCurrData = siteCatalystObj['values']['period'][0];
							var siteCatalystTrendData = siteCatalystObj['values']['trend'];
							
							var siteCatalystChanges = [];
							if (siteCatalystCurrData) {
								siteCatalystChanges = siteCatalystCurrData['changes'];
							}
							
							
							// Break out sitecatalyst trend data into 3 separate arrays
							var siteCatalystFbTrendData = [];
							var siteCatalystTwTrendData = [];
							var siteCatalystAllTrendData = [];
							for (var i = 0; i < siteCatalystTrendData.length; i++) {
								siteCatalystFbTrendData.push({ 'date': siteCatalystTrendData[i].date, 'totals':  siteCatalystTrendData[i].facebook_count });
								siteCatalystTwTrendData.push({ 'date': siteCatalystTrendData[i].date, 'totals':  siteCatalystTrendData[i].twitter_count });
								siteCatalystAllTrendData.push({ 'date': siteCatalystTrendData[i].date, 'totals':  siteCatalystTrendData[i].totals });
							}
						
							report.sitecatalyst = {
								"change_percent": siteCatalystChanges,
								"current_data": siteCatalystObj['values']['period'][0],
								"accounts": siteCatalystObj['values']['accounts'],
								"daily_trend": siteCatalystTrendData
							};
							
							if (siteCatalystTotals) {
								report.chart_data.amount_chart_referrals = [
								 
									["", "Referrals", { role: "style" } ],
									["", siteCatalystTotals.totals, $filter('chartColor')('All')], 
									["", siteCatalystTotals.facebook_count, $filter('chartColor')('Facebook')],					 
									["", siteCatalystTotals.twitter_count, $filter('chartColor')('Twitter')]	
								
								];
							}
							
							report.chart_data.daily_trend_referrals = {
								"all": siteCatalystAllTrendData,
								"facebook": siteCatalystFbTrendData,
								"twitter": siteCatalystTwTrendData
							};
						
						}
					

						// Set dates
						var startDateText = firstObj['values']['period'][0]['period'].substring(0, 10);
						var endDateText = firstObj['values']['period'][0]['period'].substring(13, firstObj['values']['period'][0]['period'].length);
			
						var startDate = new Date(startDateText);
						startDate.setDate(startDate.getDate() + 1);	// add a day because date object takes previous date
					
						var endDate = new Date(endDateText);
						endDate.setDate(endDate.getDate() + 1);	// add a day because date object takes previous date
						
						report.startdate = new Date(startDate);
						report.enddate = new Date(endDate);
						report.countries = firstObj['countries'];
						report.regions = firstObj['regions'];
						
						// If both Facebook and Twitter data are returned
						if (response.data['facebook'] && response.data['twitter']) {
							
							var allDailyTrend = [];
							// Build all daily trend chart based on sum of fb and tw values
							for (var i = 0; i < facebookTrendData.length; i++) {
								allDailyTrend.push({
									date: facebookTrendData[i].date, 
									totals: facebookTrendData[i].totals + twitterTrendData[i].totals
								});
							};
					
							// If the FB Data doesn't exist, display Twitter data for 'ALL' data
							if (facebookTrendData.length == 0) {
								allDailyTrend = twitterTrendData;
			
							// If the Twitter Data doesn't exist, display FB data for 'ALL' data
							} else if (twitterTrendData == 0) {
								allDailyTrend = facebookTrendData;
							}
						
							report.chart_data.amount_chart = [
								 
								["", "Engagement Actions", { role: "style" } ],
								["", facebookTotals + twitterTotals, $filter('chartColor')('All')], 
								["", facebookTotals, $filter('chartColor')('Facebook')],					 
								["", twitterTotals, $filter('chartColor')('Twitter')]		
								
							
							];
							
							report.chart_data.daily_trend = {
								"all": allDailyTrend,
								"facebook": facebookTrendData,
								"twitter": twitterTrendData
							};
							
							
						
							
						}
			
					}
					
					return report;
                });
           
            }
            
        };
        return report;
    });
