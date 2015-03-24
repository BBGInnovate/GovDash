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
		$scope.networks = response[2].networks;

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

	$scope.removeNetwork = function (index) {
		$scope.selectedNetworks.splice(index, 1);
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
			networks: $scope.selectedNetworks,
			startDate: $scope.startDate,
			endDate: $scope.endDate,
			period: period
		};

		APIQueryData.getData(queryData).then(function(response) {
			console.log(response);

			$scope.facebookInteractions = response.fbTotalInteractions;
			$scope.twitterInteractions = response.twTotalInteractions;
			$scope.youtubeInteractions = response.youtubeTotalInteractions;

			$scope.totalInteractions = $scope.facebookInteractions + $scope.twitterInteractions +
				$scope.youtubeInteractions;

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




	// This function is here so the tabs on the initial modal don't try to control
	// angular anchor routes
	$scope.do = function ($event) {
		$event.preventDefault();
	};


	$scope.findAccount = function (account, accountType) {
		console.log(account);

		var labels = $filter('socialMediaLabels')(accountType);
		var colors = $filter('socialMediaColors')(accountType);

		$scope.account = account;

		$scope.socialMediaType = accountType;
		$scope.accountColor = colors[0];



		var pieChartData = [
			{label: $filter('labelFormat')(labels[0]), value: account.values[0][labels[0]]},
			{label: $filter('labelFormat')(labels[1]), value: account.values[0][labels[1]]},
			{label: $filter('labelFormat')(labels[2]), value: account.values[0][labels[2]]},
			{label: $filter('labelFormat')(labels[3]), value: account.values[0][labels[3]]}
		];

		$scope.accountPieChartData = pieChartData;




	};


}

