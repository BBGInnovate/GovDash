'use strict';

angular.module('apiService', []).factory('APIData', ['$http', '$q', function($http, $q){


	return {
		getInitialData: function () {
			return $q.all([
				// $q will keep the list of promises in a array
				$http.get('/api/regions'),
				$http.get('/api/languages'),
				$http.get('/api/organizations' ),
				$http.get('/api/countries')
			]).then(function (results) {
				// once all the promises are completed .then() will be executed
				// and results will have the object that contains the data
				var aggregatedData = [];
				var listData = ['regions', 'languages', 'organizations', 'countries'];
				var listCount = 0;

				angular.forEach(results, function (result) {
					if (result) {
						if (listCount == 0) {
							aggregatedData.push({ 'regions' : result.data});
						} else if (listCount == 1) {
							aggregatedData.push({ 'languages' : result.data});
						} else if (listCount == 2) {
							aggregatedData.push({ 'organizations' : result.data});
						} else if (listCount == 3) {
							aggregatedData.push({ 'countries' : result.data});
						}


						listCount++;
					}

				});

				return aggregatedData;
			});
		},
		getData: function(countries, languages) {
			/*
			var countryIds = GetArray.byId(countries);
			var languageIds = [];
			var networkIds = [];
			var regionIds = [];
			*/


			/* Spark Chart Data */
			var d1 = [];
			for (var i = 0; i <= 31; i += 1) {
				d1.push([i, parseInt(Math.random() * 999)]);
			}

			var d2 = [];
			for (var i = 0; i <= 31; i += 1) {
				d2.push([i, parseInt(Math.random() * 999)]);
			}

			var d3 = [];
			for (var i = 0; i <= 31; i += 1) {
				d3.push([i, parseInt(Math.random() * 999)]);
			}

			/* Bar Chart Data */
			var facebookInteractions = parseInt(Math.random() * 999);
			var twitterInteractions = parseInt(Math.random() * 999);
			var youtubeInteractions = parseInt(Math.random() * 999);
			var totalInteractions = facebookInteractions + twitterInteractions + youtubeInteractions;


			var barChartData = [{ y: 'Total Interactions', a: totalInteractions, b: facebookInteractions, c: twitterInteractions, d: youtubeInteractions }];

			var fbPieChartData = [
				{label: "Comments", value: parseInt(Math.random() * 99)},
				{label: "Story Likes", value: parseInt(Math.random() * 99)},
				{label: "Shares", value: parseInt(Math.random() * 99)},
				{label: "Page Likes", value: parseInt(Math.random() * 99)}
			];

			var twPieChartData = [
				{label: "Retweets", value: parseInt(Math.random() * 99)},
				{label: "@Mentions", value: parseInt(Math.random() * 99)},
				{label: "Favorites", value: parseInt(Math.random() * 99)},
				{label: "Followers", value: parseInt(Math.random() * 99)}
			];

			var youtubePieChartData = [
				{label: "Views", value: parseInt(Math.random() * 99)},
				{label: "Likes", value: parseInt(Math.random() * 99)},
				{label: "Comments", value: parseInt(Math.random() * 99)},
				{label: "Subscriptions", value: parseInt(Math.random() * 99)}
			];

			var data = {
				chartOne: d1,	// Facebook Spark Chart
				chartTwo: d2,	// Twitter Spark Chart
				chartThree: d3,	// YouTube Spark Chart
				barChartData: barChartData,
				fbPieChartData: fbPieChartData,
				twPieChartData: twPieChartData,
				youtubePieChartData: youtubePieChartData
			};



			return data;
			/*
			 return $http.post('http://govdash-lb-1074229924.us-east-1.elb.amazonaws.com/api/reports', {options: {source: "all", country_ids: countryIds, region_ids: regionIds, language_ids: languageIds } }).then(function(response) {

			 //return $http.post('/api/reports', {options: {source: "all", country_ids: countryIds, region_ids: regionIds, language_ids: languageIds, network_ids: networkIds, start_date: startDate, end_date: endDate } }).then(function(response) {
			 return response.data;
			 }, function(err) {
			 console.log(err);
			 });
			 */
		},
		getIds: function (array) {
			var ids = [];
			for (var i = 0; i < array.length; i++) {
				ids.push(array[i].id);
			}
			return ids;
		},
		getPostData: function () {
			var data = {};
			//$http.post('/api/reports', {options: {source: "all", country_ids: countryIds, region_ids: regionIds, language_ids: languageIds, network_ids: networkIds, start_date: startDate, end_date: endDate } }).then(function(response) {
			$http.post('/api/reports', {options: {source: "all", country_ids: [1] }}).then(function(response) {
				var apiData = response.data;

				var fbDailyTrend = [];
				for (var i = 0; i <= apiData.facebook.values.trend; i++) {
					fbDailyTrend.push([i, apiData.facebook.values.trend[i].totals]);
				}

				data = response.data;


			}, function(err) {
				console.log(err);
			});

			return data;
		}

	};
}]);

angular.module('apiService2', [])
	.factory('APIData2', function($location, $http) {

		var data = {

			getData: function() {
				return $http.post('/api/reports', {options: {source: "all", language_ids:[9], period:"1.week", end_date:"2015-03-18" }}).then(function(response) {
					data = response.data;

					console.log(data);

					var fbTotalInteractions = 0;
					var twTotalInteractions = 0;
					var youtubeTotalInteractions = 0;

					var fbSparkChart = [];
					var twSparkChart = [];
					var youtubeSparkChart = [];

					var fbPieChart = [];
					var twPieChart = [];
					var youtubePieChart = [];

					var fbAccounts = [];
					var twAccounts = [];
					var youtubeAccounts = [];

					// If Facebook data exists
					if (response.data.facebook) {
						fbTotalInteractions = response.data.facebook.values.period[0].totals;

						// Process FB Spark Chart Data
						for (var i = 0; i < response.data.facebook.values.trend.length; i++) {
							fbSparkChart.push([response.data.facebook.values.trend[i].date.substring(5, 10), response.data.facebook.values.trend[i].totals]);
						}

						// Process FB Breakdown Pie Chart
						fbPieChart = [
							{label: "Comments", value: response.data.facebook.values.period[0].comments},
							{label: "Story Likes", value: response.data.facebook.values.period[0].story_likes},
							{label: "Shares", value: response.data.facebook.values.period[0].shares},
							{label: "Page Likes", value: response.data.facebook.values.period[0].page_likes}
						];

						// Process Account Data
						for (var i = 0; i < response.data.facebook.values.accounts.length; i++) {
							fbAccounts.push(response.data.facebook.values.accounts[i]);
						}



					}

					// If Twitter data exists
					if (response.data.twitter) {
						// Process Twitter Spark Chart Data
						for (var i = 0; i < response.data.twitter.values.trend.length; i++) {
							twSparkChart.push([response.data.twitter.values.trend[i].date.substring(5, 10), response.data.twitter.values.trend[i].totals]);
						}

						// Process Account Data
						for (var i = 0; i < response.data.twitter.values.accounts.length; i++) {
							twAccounts.push(response.data.twitter.values.accounts[i]);
						}
					}

					// If YouTube data exists
					if (response.data.youtube) {
						youtubeTotalInteractions = response.data.youtube.values.period[0].totals;

						// Process YouTube Spark Chart Data
						for (var i = 0; i < response.data.youtube.values.trend.length; i++) {
							youtubeSparkChart.push([response.data.youtube.values.trend[i].date.substring(5, 10), response.data.youtube.values.trend[i].totals]);
						}

						// Process YouTube Breakdown Pie Chart
						youtubePieChart = [
							{label: "Views", value: response.data.youtube.values.period[0].views},
							{label: "Likes", value: response.data.youtube.values.period[0].likes},
							{label: "Comments", value: response.data.youtube.values.period[0].comments},
							{label: "Subscribers", value: response.data.youtube.values.period[0].subscribers}
						];

						// Process Account Data
						for (var i = 0; i < response.data.youtube.values.accounts.length; i++) {
							youtubeAccounts.push(response.data.youtube.values.accounts[i]);
						}
					}


					var totalInteractions = fbTotalInteractions + twTotalInteractions + youtubeTotalInteractions;
					var barChartData = [{ y: 'Total Interactions', a: totalInteractions, b: fbTotalInteractions, c: twTotalInteractions, d: youtubeTotalInteractions }];


					var formattedData = {
						fbTotalInteractions: fbTotalInteractions,
						twTotalInteractions: twTotalInteractions,
						youtubeTotalInteractions: youtubeTotalInteractions,
						barChartData: barChartData,
						fbSparkChart: fbSparkChart,
						twSparkChart: twSparkChart,
						youtubeSparkChart: youtubeSparkChart,
						fbBreakdownChart: fbPieChart,
						twBreakdownChart: twPieChart,
						youtubeBreakdownChart: youtubePieChart,
						fbAccounts: fbAccounts,
						twAccounts: twAccounts,
						youtubeAccounts: youtubeAccounts
					};



					return formattedData;
				});
			}

		};
		return data;
	});

/*
angular.module('apiService', []).factory('GetArray', function(){


	return {

		byId: function (array) {
			var ids = [];
			if (array) {
				for (var i = 0; i < array.length; i++) {
					ids.push(array[i].id);
				}
				return ids;
			} else {
				return [];
			}

		}

	};
});
	*/