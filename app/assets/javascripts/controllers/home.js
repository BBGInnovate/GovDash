"use strict";

function HomeCtrl($scope, APIData, APIQueryData, $filter) {

	// Initialize start and end dates
	$scope.endDate = moment().format('L');
	$scope.startDate =  moment($scope.endDate,"MM/DD/YYYY").subtract(6,'day').format('MM/DD/YYYY');

	// When content loads, display and initialize modal
	$scope.$on('$viewContentLoaded', loadModal);

	// get all data on page load
	APIData.getInitialData().then(function(response) {

		$scope.countries = response[3].countries;
		$scope.regions = response[0].regions;
		$scope.languages = response[1].languages;
		$scope.groups = response[2].groups;

	});


	// Remove functions for wizard builder
	$scope.removeRegion = function (index) {
		$scope.selectedRegions.splice(index, 1);
	};

	$scope.removeCountry = function (index) {
		$scope.selectedCountries.splice(index, 1);
	};

	$scope.removeLanguage = function (index) {
		$scope.selectedLanguages.splice(index, 1);
	};

	$scope.removeGroup = function (index) {
		$scope.selectedGroups.splice(index, 1);
	};


	// Function that makes the API call and returns data / assigns it
	// 'period' is the date period (current, last week, last month, etc.)
	$scope.finish = function (period) {

		// If period is 'custom', grab the calendar dates and set them to scope
		// variables using jQuery
		if (period === 'custom') {
			$scope.startDate =  $('#start-date').val();
			$scope.endDate = $('#end-date').val();
		}


		// Build out object to send to Angular Service
		var queryData = {
			regions: $scope.selectedRegions,
			countries: $scope.selectedCountries,
			languages: $scope.selectedLanguages,
			groups: $scope.selectedGroups,
			startDate: $scope.startDate,
			endDate: $scope.endDate,
			period: period
		};

		APIQueryData.getData(queryData).then(function(response) {
			console.log(response);

			// Top 4 boxes Interactions
			$scope.facebookInteractions = response.fbTotalInteractions;
			$scope.facebookPercentChange = response.fbPercentChange;

			$scope.twitterInteractions = response.twTotalInteractions;
			$scope.twitterPercentChange = response.twPercentChange;

			$scope.youtubeInteractions = response.youtubeTotalInteractions;
			$scope.youtubePercentChange = response.youtubePercentChange;

			$scope.totalInteractions = $scope.facebookInteractions + $scope.twitterInteractions +
				$scope.youtubeInteractions;

			$scope.totalPercentChange = response.totalPercentChange;

			// Bar Chart Data
			$scope.barChartData = response.barChartData;

			// Spark Chart Data
			$scope.fbSparkChart = response.fbSparkChart;
			$scope.twSparkChart = response.twSparkChart;
			$scope.youtubeSparkChart = response.youtubeSparkChart;

			// Pie Chart Breakdown Data
			$scope.fbPieChartData = response.fbBreakdownChart;
			$scope.twPieChartData = response.twBreakdownChart;
			$scope.youtubePieChartData = response.youtubeBreakdownChart;

			// Account Table Data
			$scope.fbAccounts = response.fbAccounts;
			$scope.twAccounts = response.twAccounts;
			$scope.youtubeAccounts = response.youtubeAccounts;

		});


	};

	$scope.findAccount = function (account, accountType) {
		console.log(account);

		var colors = $filter('socialMediaColors')(accountType);
		var labels = $filter('socialMediaLabels')(accountType);

		$scope.account = account;

		$scope.socialMediaType = accountType;
		$scope.accountColor = colors[0];

		$scope.accountPieChartData = $scope.account.values[0];
		$scope.accountSparkChartData = $scope.account.trend;

		$scope.accountBlockOne = $filter('labelFormat')(labels[0]);
		$scope.accountBlockTwo = $filter('labelFormat')(labels[1]);
		$scope.accountBlockThree = $filter('labelFormat')(labels[2]);
		$scope.accountBlockFour = $filter('labelFormat')(labels[3]);



	};




	// This function is here so the tabs on the initial modal don't try to control
	// angular anchor routes
	$scope.do = function ($event) {
		$event.preventDefault();
	};





}

