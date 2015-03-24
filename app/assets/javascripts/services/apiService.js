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
				$http.get('/api/groups' ),
				$http.get('/api/countries')
			]).then(function (results) {
				// once all the promises are completed .then() will be executed
				// and results will have the object that contains the data
				var aggregatedData = [];
				var listData = ['regions', 'languages', 'groups', 'countries'];
				var listCount = 0;

				angular.forEach(results, function (result) {
					if (result) {
						if (listCount == 0) {
							aggregatedData.push({ 'regions' : result.data});
						} else if (listCount == 1) {
							aggregatedData.push({ 'languages' : result.data});
						} else if (listCount == 2) {
							aggregatedData.push({ 'groups' : result.data});
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
				var groupIds = APIData.getIds(queryData.groups);

				var startDate = moment(queryData.startDate, 'MM/DD/YYYY').format('YYYY/MM/DD');
				var endDate = moment(queryData.endDate, 'MM/DD/YYYY').format('YYYY/MM/DD');

				var period = queryData.period;

				// If 'Last Week' or 'Last Month' is selected, set startDate to null
				if (period === '1.week' || period === '1.month') {
					startDate = null;
				}

				return $http.post('/api/reports', {options: {source: "all", country_ids: countryIds, region_ids: regionIds, language_ids: languageIds, group_ids: groupIds, start_date: startDate, end_date: endDate, period: period } }).then(function(response) {
					data = response.data;

					console.log(data);

					var numAccounts = 0;

					// Initialize data here
					var fbTotalInteractions = 0;
					var twTotalInteractions = 0;
					var youtubeTotalInteractions = 0;

					var fbPercentChange = '';
					var twPercentChange = '';
					var youtubePercentChange = '';

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

						fbSparkChart = response.data.facebook.values.trend;

						fbPieChart = response.data.facebook.values.period[0];

						fbAccounts = response.data.facebook.values.accounts;

						fbPercentChange = response.data.facebook.values.period[0].changes.totals;

						numAccounts++;

					}

					// If Twitter data exists
					if (response.data.twitter) {
						twTotalInteractions = response.data.twitter.values.period[0].totals;

						twSparkChart = response.data.twitter.values.trend;

						twPieChart = response.data.twitter.values.period[0];

						twAccounts = response.data.twitter.values.accounts;

						twPercentChange = response.data.twitter.values.period[0].changes.totals;

						numAccounts++;

					}

					// If YouTube data exists
					if (response.data.youtube) {
						youtubeTotalInteractions = response.data.youtube.values.period[0].totals;

						youtubeSparkChart = response.data.youtube.values.trend;

						youtubePieChart = response.data.youtube.values.period[0];

						youtubeAccounts = response.data.youtube.values.accounts;

						youtubePercentChange = response.data.youtube.values.period[0].changes.totals;

						numAccounts++;

					}

					var totalInteractions = fbTotalInteractions + twTotalInteractions + youtubeTotalInteractions;
					var barChartData = {
						totalInteractions: totalInteractions,
						fbInteractions: fbTotalInteractions,
						twInteractions: twTotalInteractions,
						youtubeInteractions: youtubeTotalInteractions
					};

					var totalPercentChange = (Math.round((parseInt(fbPercentChange.replace(' ', '').replace('%', '') || 0) +
						parseInt(twPercentChange.replace(' ', '').replace('%', '') || 0) +
						parseInt(youtubePercentChange.replace(' ', '').replace('%', '') || 0)) / numAccounts)).toString() + ' %';



					// Build object to return to controller
					var formattedData = {
						totalPercentChange: totalPercentChange,
						fbTotalInteractions: fbTotalInteractions,
						fbPercentChange: fbPercentChange,
						twTotalInteractions: twTotalInteractions,
						twPercentChange: twPercentChange,
						youtubeTotalInteractions: youtubeTotalInteractions,
						youtubePercentChange: youtubePercentChange,
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

