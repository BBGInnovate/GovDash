'use strict';

// This factory is used for pulling the initial data and handling arrays of objects
angular.module('apiService', []).factory('APIData', ['$http', '$q', function($http, $q){

	return {
		// This function will poll the initial data
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
		// This function will take in an array and return back the IDs of the array
		getIds: function (array) {
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
}]);

// This is the factory that will take the data passed in and query the back-end for data
angular.module('apiQueryService', [])
	.factory('APIQueryData', function($location, $http, APIData, $rootScope) {

		var data = {

			getData: function(queryData) {

				var countryIds = APIData.getIds(queryData.countries);
				var regionIds = APIData.getIds(queryData.regions);
				var languageIds = APIData.getIds(queryData.languages);
				var networkIds = APIData.getIds(queryData.networks);

				var startDate = moment(queryData.startDate, 'MM/DD/YYYY').format('YYYY/MM/DD');
				var endDate = moment(queryData.endDate, 'MM/DD/YYYY').format('YYYY/MM/DD');

				var period = queryData.period;

				// If 'Last Week' or 'Last Month' is selected, set startDate to null
				if (period === '1.week' || period === '1.month') {
					startDate = null;
				}

				return $http.post('/api/reports', {options: {source: "all", country_ids: countryIds, region_ids: regionIds, language_ids: languageIds, network_ids: networkIds, start_date: startDate, end_date: endDate, period: period } }).then(function(response) {
					data = response.data;

					console.log(data);

					// Initialize data here
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
						twTotalInteractions = response.data.twitter.values.period[0].totals;

						// Process Twitter Spark Chart Data
						for (var i = 0; i < response.data.twitter.values.trend.length; i++) {
							twSparkChart.push([response.data.twitter.values.trend[i].date.substring(5, 10), response.data.twitter.values.trend[i].totals]);
						}

						twPieChart = [
							{label: "Retweets", value: response.data.twitter.values.period[0].retweets},
							{label: "@Mentions", value: response.data.twitter.values.period[0].mentions},
							{label: "Favorites", value: response.data.twitter.values.period[0].favorites},
							{label: "Followers", value: response.data.twitter.values.period[0].followers}
						];

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

					$rootScope.accounts = fbAccounts.concat(twAccounts).concat(youtubeAccounts);


					var totalInteractions = fbTotalInteractions + twTotalInteractions + youtubeTotalInteractions;
					var barChartData = [{ y: 'Total Interactions', a: totalInteractions, b: fbTotalInteractions, c: twTotalInteractions, d: youtubeTotalInteractions }];



					// Build object to return to controller
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

