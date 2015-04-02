"use strict";

function HomeCtrl($scope, APIData, APIQueryData, $filter) {

	// Initialize start and end dates
	$scope.endDate = moment().format('L');
	$scope.startDate =  moment($scope.endDate,"MM/DD/YYYY").subtract(6,'day').format('MM/DD/YYYY');

	// get all data on page load
	APIData.getInitialData().then(function(response) {

		$scope.regions = response[0].regions;
		$scope.languages = response[1].languages;
		$scope.groups = response[2].groups;
		$scope.countries = response[3].countries;
		$scope.organizations = response[4].organizations;
		$scope.subgroups = response[5].subgroups;

		// this is a placeholder for the subgroups that gets filtered down
		$scope.allSubgroups = response[5].subgroups;

		$scope.$watchCollection('selectedOrganizations', function(newVal, oldVal) {
			if (newVal) {
				$scope.selectedGroups = [];
				$scope.selectedSubgroups = [];

				$scope.subgroups = $scope.allSubgroups;
			}

		});

		$scope.$watchCollection('selectedGroups', function(newVal, oldVal) {
			if (newVal && newVal.length > 0) {
				$scope.subgroups = newVal[0].related_subgroups;
			}

		});

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

	$scope.removeOrganization = function () {
		$scope.selectedOrganizations = null;
		$scope.subgroups = $scope.allSubgroups;
	};

	$scope.removeGroup = function (index) {
		$scope.selectedGroups.splice(index, 1);
		$scope.subgroups = $scope.allSubgroups;
	};

	$scope.removeSubgroup = function (index) {
		$scope.selectedSubgroups.splice(index, 1);
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
			organizations: $scope.selectedOrganizations,
			groups: $scope.selectedGroups,
			subgroups: $scope.selectedSubgroups,
			startDate: $scope.startDate,
			endDate: $scope.endDate,
			period: period
		};

		APIQueryData.getData(queryData).then(function(response) {

			if (response.fbAccounts.length === 0 && response.twAccounts.length === 0 &&
				response.youtubeAccounts.length === 0) {

				// Display notification
				noty({
					text: 'No results found',
					type: 'error',
					layout: 'topCenter',
					timeout: '5000'
				});

			}

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
		var colors = $filter('socialMediaColors')(accountType);
		var labels = $filter('socialMediaLabels')(accountType);

		$scope.account = account;

		$scope.socialMediaType = accountType;
		$scope.accountColor = colors[0];

		$scope.accountPieChartData = $scope.account.values[0];
		$scope.accountSparkChartData = $scope.account.trend;

		// Header names for account modal
		$scope.accountBlockOne = $filter('labelFormat')(labels[0]);
		$scope.accountBlockTwo = $filter('labelFormat')(labels[1]);
		$scope.accountBlockThree = $filter('labelFormat')(labels[2]);
		$scope.accountBlockFour = $filter('labelFormat')(labels[3]);

		// Header values for account modal
		$scope.accountBlockOneData = $scope.account.values[0][labels[0]];
		$scope.accountBlockTwoData = $scope.account.values[0][labels[1]];
		$scope.accountBlockThreeData = $scope.account.values[0][labels[2]];
		$scope.accountBlockFourData = $scope.account.values[0][labels[3]];



	};






	// This function is here so the tabs on the initial modal don't try to control
	// angular anchor routes
	$scope.do = function ($event) {
		$event.preventDefault();
	};





}

