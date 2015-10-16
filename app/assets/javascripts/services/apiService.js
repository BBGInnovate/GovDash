'use strict';

// This factory is used for pulling the initial data and handling arrays of objects
angular.module('apiService', []).factory('APIData', ['$http', '$q', function($http, $q){

	return {
		// This function will poll the initial data
		getInitialData: function (userRole) {
			return $q.all([
				// $q will keep the list of promises in a array
				$http.get('/api/regions'),
				$http.get('/api/languages'),
				$http.get('/api/groups' ),
				$http.get('/api/countries'),
				$http.get('/api/organizations'),
				$http.get('/api/subgroups')
				//$http.get('/api/accounts')
			]).then(function (results) {
				// once all the promises are completed .then() will be executed
				// and results will have the object that contains the data
				var aggregatedData = [];
				var listData = ['regions', 'languages', 'groups', 'countries', 'organizations', 'subgroups', 'accounts'];
				var listCount = 0;

				// array used to hold the ids of the organization the user belongs to
				var organizationIds = [];

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
						} else if (listCount == 4) {
							var organizations = [];

							// if multiple user roles, they are split by comma
							var userRoles = userRole.split(',');

							for (var i = 0; i < result.data.length; i++) {
								for (var j = 0; j < userRoles.length; j++) {
									if (result.data[i].name.indexOf(userRoles[j]) > -1) {
										organizations.push(result.data[i]);
										organizationIds.push(result.data[i].id);
									}

								}

							}

							aggregatedData.push({ 'organizations' : organizations });
						} else if (listCount == 5) {
							var subgroups = [];

							// loop through organizationIds
							for (var k = 0; k < organizationIds.length; k++) {
								// loop through subgroups
								for (var i = 0; i < result.data.length; i++) {
									// loop through subgroups's related groups array
									for (var j = 0; j < result.data[i].related_groups.length; j++) {
										// if the current organizationId is equal to the current subgroup's current
										// related group, push it to subgroups array
										if (organizationIds[k] === result.data[i].related_groups[j].organization_id) {
											subgroups.push(result.data[i]);
										}
									}
								}
							}
							aggregatedData.push({ 'subgroups' : subgroups});
						} /*else if (listCount == 6) {
							aggregatedData.push({ 'accounts' : result.data});
						}
						*/

						listCount++;
					}

				});

				// re-establish the subgroups based on organization
				var groups = [];

				// loop through organizationIds
				for (var i = 0; i < organizationIds.length; i++) {
					// loop through the current groups
					for (var j = 0; j < aggregatedData[2].groups.length; j++) {

						// if the user's organizationId matches the groups organizationId
						if (organizationIds[i] === aggregatedData[2].groups[j].organization_id) {
							groups.push(aggregatedData[2].groups[j]);
						}
					}
				}

				// set the aggregated data group to new subgroups
				aggregatedData[2].groups = groups;


				return aggregatedData;
			});
		},
		// This function will take in an array and return back the IDs of the array
		getIds: function (array) {
			var ids = [];
			if (array) {
				// for singular JSON object not in array
				if (array.length == undefined) {
					return [array.id];
				// when array of objects is passed in, just grab IDs
				} else {
					for (var i = 0; i < array.length; i++) {
						ids.push(array[i].id);
					}
					return ids;
				}
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
				// pass arrays to getIds function to only return ID of each object in array
				var countryIds = APIData.getIds(queryData.countries);
				var regionIds = APIData.getIds(queryData.regions);
				var languageIds = APIData.getIds(queryData.languages);
				var organizationIds = APIData.getIds(queryData.organizations);
				var groupIds = APIData.getIds(queryData.groups);
				var subgroupIds = APIData.getIds(queryData.subgroups);
				var accountIds = APIData.getIds(queryData.accounts);

				// structure dates for API
				var startDate = moment(queryData.startDate, 'MM/DD/YYYY').format('YYYY/MM/DD');
				var endDate = moment(queryData.endDate, 'MM/DD/YYYY').format('YYYY/MM/DD');

				var period = queryData.period;

				// If 'Last Week' or 'Last Month' is selected, set startDate to null
				// and pass in just endDate with period value
				if (period === '1.week' || period === '1.month') {
					startDate = null;
				}

				// Query API service passing in all parameters
				return $http.post('/api/reports', {options: {source: "all", country_ids: countryIds,
					region_ids: regionIds, language_ids: languageIds, organization_ids: organizationIds,
					group_ids: groupIds, subgroup_ids: subgroupIds, account_ids: accountIds, start_date: startDate, end_date: endDate,
					period: period } }).then(function(response) {


					data = response.data;

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

					var startDate = '';
					var endDate = '';

					var scTotalActions = 0;
					var scFbActions = 0;
					var scTwActions = 0;
					var scTrend = [];
					var scTotalTrendActions = 0;
					var hasLastPeriod = true;

				//	var dataSinceArray = [];

					var lastPeriodDate = '';

					//var minDate = '';

					// If Facebook data exists
					if (response.data.facebook) {
						fbTotalInteractions = response.data.facebook.values.period[0].totals;

						fbSparkChart = response.data.facebook.values.trend;

						fbPieChart = response.data.facebook.values.period[0];

						fbAccounts = response.data.facebook.values.accounts;

						fbPercentChange = response.data.facebook.values.period[0].changes.totals;

						startDate =  moment(response.data.facebook.values.period[0].period.substring(0,10), 'YYYY-MM-DD').format('MM/DD/YYYY');
						endDate =  moment(response.data.facebook.values.period[0].period.substring(13,24), 'YYYY-MM-DD').format('MM/DD/YYYY');

						var lastPeriodStartDateString = moment(response.data.facebook.values.period[0].previous_period.substring(0,10), 'YYYY-MM-DD').format('MM/DD/YYYY');
						var lastPeriodEndDateString = moment(response.data.facebook.values.period[0].previous_period.substring(13,24), 'YYYY-MM-DD').format('MM/DD/YYYY');

				//		var lastPeriodStartDate = new Date(lastPeriodStartDateString);
				//		var lastPeriodEndDate = new Date(lastPeriodEndDateString);

						//lastPeriodDate = Math.ceil((lastPeriodEndDate.getTime() - lastPeriodStartDate.getTime()) / (1000*60*60*24));
						lastPeriodDate = lastPeriodStartDateString + ' - ' + lastPeriodEndDateString;

						//lastPeriodDate = response.data.facebook.values.period[0].previous_period;

						/*
						// gather up all of the data collect started for minimum date selection
						for (var i = 0; i < fbAccounts.length; i++) {
							dataSinceArray.push(new Date(fbAccounts[i].profile.data_collect_started.substring(0, 10)));
						}
						*/

						numAccounts++;

					}

					// If Twitter data exists
					if (response.data.twitter) {
						twTotalInteractions = response.data.twitter.values.period[0].totals;

						twSparkChart = response.data.twitter.values.trend;

						twPieChart = response.data.twitter.values.period[0];

						twAccounts = response.data.twitter.values.accounts;

						twPercentChange = response.data.twitter.values.period[0].changes.totals;

						startDate =  moment(response.data.twitter.values.period[0].period.substring(0,10), 'YYYY-MM-DD').format('MM/DD/YYYY');
						endDate =  moment(response.data.twitter.values.period[0].period.substring(13,24), 'YYYY-MM-DD').format('MM/DD/YYYY');

						var lastPeriodStartDateString = moment(response.data.twitter.values.period[0].previous_period.substring(0,10), 'YYYY-MM-DD').format('MM/DD/YYYY');
						var lastPeriodEndDateString = moment(response.data.twitter.values.period[0].previous_period.substring(13,24), 'YYYY-MM-DD').format('MM/DD/YYYY');

					//	var lastPeriodStartDate = new Date(lastPeriodStartDateString);
					//	var lastPeriodEndDate = new Date(lastPeriodEndDateString);

						//lastPeriodDate = Math.ceil((lastPeriodEndDate.getTime() - lastPeriodStartDate.getTime()) / (1000*60*60*24));
						lastPeriodDate = lastPeriodStartDateString + ' - ' + lastPeriodEndDateString;

					//	lastPeriodDate = response.data.twitter.values.period[0].previous_period;

						/*
						// gather up all of the data collect started for minimum date selection
						for (var i = 0; i < twAccounts.length; i++) {
							dataSinceArray.push(new Date(twAccounts[i].profile.data_collect_started.substring(0, 10)));
						}
						*/


						numAccounts++;

					}

					// If YouTube data exists
					if (response.data.youtube) {
						youtubeTotalInteractions = response.data.youtube.values.period[0].totals;

						youtubeSparkChart = response.data.youtube.values.trend;

						youtubePieChart = response.data.youtube.values.period[0];

						youtubeAccounts = response.data.youtube.values.accounts;

						youtubePercentChange = response.data.youtube.values.period[0].changes.totals;

						startDate =  moment(response.data.youtube.values.period[0].period.substring(0,10), 'YYYY-MM-DD').format('MM/DD/YYYY');
						endDate =  moment(response.data.youtube.values.period[0].period.substring(13,24), 'YYYY-MM-DD').format('MM/DD/YYYY');

						var lastPeriodStartDateString = moment(response.data.youtube.values.period[0].previous_period.substring(0,10), 'YYYY-MM-DD').format('MM/DD/YYYY');
						var lastPeriodEndDateString = moment(response.data.youtube.values.period[0].previous_period.substring(13,24), 'YYYY-MM-DD').format('MM/DD/YYYY');

					//	var lastPeriodStartDate = new Date(lastPeriodStartDateString);
					//	var lastPeriodEndDate = new Date(lastPeriodEndDateString);

					//	lastPeriodDate = Math.ceil((lastPeriodEndDate.getTime() - lastPeriodStartDate.getTime()) / (1000*60*60*24));
						lastPeriodDate = lastPeriodStartDateString + ' - ' + lastPeriodEndDateString;


						//lastPeriodDate = response.data.youtube.values.period[0].previous_period;

						/*
						// gather up all of the data collect started for minimum date selection
						for (var i = 0; i < youtubeAccounts.length; i++) {
							dataSinceArray.push(new Date(youtubeAccounts[i].profile.data_collect_started.substring(0, 10)));
						}
						*/



						numAccounts++;

					}

					// If SiteCatalyst data exists
					if (response.data.sitecatalyst) {
						scTotalActions = response.data.sitecatalyst.values.period[0].totals;

						scFbActions = response.data.sitecatalyst.values.period[0].facebook_count;

						scTwActions = response.data.sitecatalyst.values.period[0].twitter_count;

						scTrend = response.data.sitecatalyst.values.trend;


						for (var i = 0; i < scTrend.length; i++) {
							scTotalTrendActions += scTrend[i].totals;
						}

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


					var scBarChartData = {
						totalInteractions: scTotalActions,
						fbInteractions: scFbActions,
						twInteractions: scTwActions

					};

					if (lastPeriodDate.length > 0 && moment(lastPeriodDate.substring(0, 10)).isBefore('04/01/2015')) {
						hasLastPeriod = false;
					}


					/*

					if (dataSinceArray.length > 0) {
						minDate = new Date(Math.min.apply(null, dataSinceArray));
					}
					*/

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
						youtubeAccounts: youtubeAccounts,
						scBarChartData: scBarChartData,
						scTrend: scTrend,
						scTotalTrendActions: scTotalTrendActions,
						startDate: startDate,
						endDate: endDate,
						lastPeriodDate: lastPeriodDate,
						hasLastPeriod: hasLastPeriod
						//minDate: minDate
					};






					return formattedData;
				});
			},

			getAccountsByGroupAndSubgroupIds: function (groupIdsArray, subgroupIdsArray) {
				// Query API service passing in all parameters
				var queryString = '';

				// Stringify the groupIds
				var groupIds = '';
				if (groupIdsArray) {
					for (var i = 0; i < groupIdsArray.length; i++) {
						groupIds += groupIdsArray[i].id + ',';
					}
					groupIds = groupIds.substring(0, groupIds.length - 1);
					//console.log('Groups: ' + groupIds);
					if (groupIds.length > 0) {
						queryString += '&group_id=' + groupIds;
					}
				}


				// Stringify the subgroupIds

				var subgroupIds = '';
				if (subgroupIdsArray) {
					for (var i = 0; i < subgroupIdsArray.length; i++) {
						subgroupIds += subgroupIdsArray[i].id + ',';
					}
					subgroupIds = subgroupIds.substring(0, subgroupIds.length - 1);
				//	console.log('Subgroups: ' + subgroupIds);
					if (subgroupIds.length > 0) {
						queryString += '&subgroup_id='+subgroupIds;
					}
				}




				return $http.get('/api/accounts?' + queryString).then(function(response) {
					return response.data;
				});

			}

		};
		return data;
	});

