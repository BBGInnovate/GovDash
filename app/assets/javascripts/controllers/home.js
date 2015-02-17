function HomeCtrl($scope, Languages, Regions, Countries, Networks, Session, Accounts, Reports, Dates, $routeParams, $filter, $parse, $rootScope) {"use strict";
	//$scope.user = Session.requestCurrentUser();
	
    $scope.logout = function() {
        Session.logout();
    };
    
	// Initial GET requests for page load
    $scope.getData = function() {

  		Regions.getAllRegions()
            .then(function(response) {
               $scope.regions = response.data;
        });
  		
  		Countries.getAllCountries()
            .then(function(response) {
               $scope.countries = response.data;
        });
        
        Languages.getAllLanguages()
            .then(function(response) {
               $scope.languages = response.data;
         
        });
        
        Networks.getAllNetworks()
            .then(function(response) {
               $scope.networks = response.data;
        });
        
        
  	};
  	
  	$scope.removeRegion = function(idx) {
  		$scope.selectedRegion.splice( idx, 1 );
  	};
  	
  	$scope.removeCountry = function(idx) {
  		$scope.selectedCountry.splice( idx, 1 );
  	};
  	
  	$scope.removeLanguage = function(idx) {
  		$scope.selectedLanguage.splice( idx, 1 );
  	};
  	
  	$scope.removeNetwork = function(idx) {
  		$scope.selectedNetwork.splice( idx, 1 );
  	};
  	
  	$scope.selectAllCountries = function() {
  		var allObj = $scope.countries[0];
  		$scope.selectedCountry = [{ title: 'All', originalObject: allObj } ];
  	};
  	
  	// Process the finalized selections
  	$scope.finish = function() {
  		$scope.dataReturned = null;
  				
   		$scope.filterText = '';
  		
  		var regions = [];
  		if ($scope.selectedRegion != null) {
			for (var i = 0; i < $scope.selectedRegion.length; i++) {
				regions.push($scope.selectedRegion[i].id);
				$scope.filterText += $scope.selectedRegion[i].name  + ', ';
			}
  		}
  		
  		var countries = [];
  		if ($scope.selectedCountry != null) {
			for (var i = 0; i < $scope.selectedCountry.length; i++) {
				countries.push($scope.selectedCountry[i]['originalObject'].id);
				$scope.filterText += $scope.selectedCountry[i]['originalObject'].name + ', ';
			}
  		}
  		
  		var languages = [];
  		if ($scope.selectedLanguage != null) {
			for (var i = 0; i < $scope.selectedLanguage.length; i++) {
				languages.push($scope.selectedLanguage[i]['originalObject'].id);
				$scope.filterText += $scope.selectedLanguage[i]['originalObject'].name + ', ';
			}
  		}
  		
  		var networks = [];
  		if ($scope.selectedNetwork != null) {
			for (var i = 0; i < $scope.selectedNetwork.length; i++) {
				networks.push($scope.selectedNetwork[i].id);
				$scope.filterText += $scope.selectedNetwork[i].name + ', ';
			}
  		}
  
        Reports.getData(regions, countries, languages, 
  		networks, null, null) // Last two nulls are startDate and endDate
            .then(function(response) {
        		// Call function to populate tables / charts
            	$scope.populateData(response);
            	
            	// Set the filters
            	$scope.selectedNetworks = networks;
            	$scope.selectedCountries = countries;
            	$scope.selectedLanguages = languages;
            	$scope.selectedRegions = regions;
        });
        
    
  	};
  	
  	$scope.populateData = function(data) {
  		$scope.siteCatalystReports = false;
  		if (data) {
  			$scope.pieChartDisplayText = '+Show More';
  			
			// Set Dates
			$scope.a = data['startdate'];
			$scope.b = data['enddate'];
			
			// Calculate 'Compared To' dates
			var oneDay = 24*60*60*1000; // hours*minutes*seconds*milliseconds
			var firstDate = $scope.a;
			var secondDate = $scope.b;
			
			var diffDays = Math.round(Math.abs((firstDate.getTime() - secondDate.getTime())/(oneDay))) + 1;
			
			var compareStartDate = new Date((firstDate.getMonth() + 1) + '/' + firstDate.getDate() + '/' + firstDate.getFullYear()); 
 			$scope.compareStartDate = compareStartDate.setDate(compareStartDate.getDate() - diffDays);
 			
 			var compareEndDate = new Date((secondDate.getMonth() + 1) + '/' + secondDate.getDate() + '/' + secondDate.getFullYear()); 
 			$scope.compareEndDate = compareEndDate.setDate(compareEndDate.getDate() - diffDays);
 			
			// Set Countries and Regions
			$scope.includedCountries = data['countries'];
			$scope.includedRegions = data['regions'];
			
			// Initialize array for Facebook and Twitter Accounts
			$scope.fbAccounts = [];
			$scope.twAccounts = [];
			
			
			// Totals Percentages for Engagement Actions Amount chart
			// These calculations are broken by whether data exists 
			// for the accounts or not
			$scope.hasPercentages = false;
			if (data['facebook'] && data['twitter']) {
				$scope.fbAccounts = data['facebook']['accounts'];
				$scope.twAccounts = data['twitter']['accounts'];
				
				$scope.hasPercentages = true;
				$scope.allChangePercent = $filter('calcAllChangePercent')(data['facebook']['change_percent'],
					data['twitter']['change_percent']);
				$scope.fbChangePercent = data['facebook']['change_percent'];
				$scope.twChangePercent = data['twitter']['change_percent'];
			}
		
			// Facebook only exists, populate Twitter values as 'N/A' for percentages
			if (data['facebook'] && !data['twitter']) {
				$scope.fbAccounts = data['facebook']['accounts'];
				
				$scope.allChangePercent = $filter('calcAllChangePercent')(data['facebook']['change_percent'],
					data['facebook']['change_percent']);
				$scope.fbChangePercent = data['facebook']['change_percent'];
				$scope.twChangePercent = 'N/A';
			}
			
			// Twitter only exists, populate Facebook values as 'N/A' for percentages
			if (data['twitter'] && !data['facebook']) {
				$scope.twAccounts = data['twitter']['accounts'];
				
				$scope.allChangePercent = $filter('calcAllChangePercent')(data['twitter']['change_percent'],
					data['twitter']['change_percent']);
				$scope.twChangePercent = data['twitter']['change_percent'];
				$scope.fbChangePercent = 'N/A';
			}
			
		
		
			// Amount Chart
			$scope.amountChart = [];
			if (data['chart_data']['amount_chart']) {
				$scope.amountChart = data['chart_data']['amount_chart'];
				$scope.processBarChart('amountChart', 'Amount', $scope.amountChart); 
			}
			
			// Facebook Breakdown Data
			$scope.processPieChart('amountChartFacebook', 'Facebook', data['chart_data']['facebook_breakdown_data']); 
		
			// Twitter Breakdown Data
			$scope.processPieChart('amountChartTwitter', 'Twitter', data['chart_data']['twitter_breakdown_data']); 
		
		
			// Daily Trend Charts
			$scope.allDailyTrend = [];
			$scope.fbDailyTrend = [];
			$scope.twDailyTrend = [];
			if (data['chart_data']['daily_trend']) {
				$scope.allDailyTrend = data['chart_data']['daily_trend']['all'];
				$scope.fbDailyTrend = data['chart_data']['daily_trend']['facebook'];
				$scope.twDailyTrend = data['chart_data']['daily_trend']['twitter'];
				$scope.processLineChart('allTrend', 'All', $scope.allDailyTrend);
				$scope.processLineChart('fbTrend', 'Facebook', $scope.fbDailyTrend);
				$scope.processLineChart('twTrend', 'Twitter', $scope.twDailyTrend);
			}
		
			
			// If SiteCatalyst Data exists
			if (data['sitecatalyst']) {
				// SiteCatalyst Charts
				$scope.processBarChart('amountChartReferrals', 'Amount', data['chart_data']['amount_chart_referrals']); 
				// Totals Percentages for Engagement Actions Amount chart
				$scope.allChangePercentReferrals = data['sitecatalyst']['change_percent']['totals'];
				$scope.fbChangePercentReferrals = data['sitecatalyst']['change_percent']['facebook'];
				$scope.twChangePercentReferrals = data['sitecatalyst']['change_percent']['twitter'];
			
				// SiteCatalyst Trend Charts
				$scope.allDailyTrendReferral = data['chart_data']['daily_trend_referrals']['all'];
				$scope.fbDailyTrendReferral = data['chart_data']['daily_trend_referrals']['facebook'];
				$scope.twDailyTrendReferral = data['chart_data']['daily_trend_referrals']['twitter'];
			
				$scope.processLineChart('allDailyTrendReferral', 'All', $scope.allDailyTrendReferral);
				$scope.processLineChart('fbDailyTrendReferral', 'Facebook', $scope.fbDailyTrendReferral);
				$scope.processLineChart('twDailyTrendReferral', 'Twitter', $scope.twDailyTrendReferral);
				
				$scope.siteCatalystReports = true;
			}
		
		
			// Hide the pie charts by default
			$scope.showPieCharts = false;
			
			// Variables for handling different HTML segments to show
			$scope.dataReturned = 'Both';
			$scope.reportDone = true;
			
			// Hide modal
			$scope.modal('hide');
			
			
		} else {	// No data returned
		
			$scope.dataReturned = false;
	
		}
  	};	
  
  	
  	$scope.processLineChart = function(chartName, yAxis, dataArr) {
  	
		var data = [];
		var labelAxis = 'Engagement Actions';
		
		// If the chart is a SiteCatalyst chart, change the axis label to Visits
		// DASH-208
		if (chartName.indexOf('Referral') > -1) {
			labelAxis = 'Referrals';
		}

		data.push(["", labelAxis, { role: "style" } ]);
	
		for (var i = 0; i < dataArr.length; i++) {	
			data.push([$filter('date')(dataArr[i].date), dataArr[i].totals, $filter('chartColor')(yAxis)]);
		}
				
  		
  		$scope[ chartName ] = {};
  		
  		$scope[ chartName ].data = data;
  
		$routeParams.chartType = 'LineChart';
		$scope[ chartName ].type = $routeParams.chartType;
		
		$scope[ chartName ].formatters = {
		  number : [{
			columnNum: 1,
			"pattern": "#,###"
		  }]
		};
	
		$scope[ chartName ].options = {
		//	'title': yAxis,
			'hAxis': { 
				textPosition: 'none' 
			},
			'vAxis': { 
				textPosition: 'none' 
			},
			'legend': {
				position: 'none'
			},
			'series': {
				0: {
					type: 'area',
					color: $filter('chartColor')(yAxis)
				}
        	},
        	'backgroundColor': 'transparent',
        	'chartArea': {
        		left: '8%',
        		right: '8%',
        		width: '90%',
        		height: '70%'
        	}
		}
  	};
  
  	$scope.processBarChart = function(chartName, chartTitle, data) {
  	
  		$scope[ chartName ] = {};
        
		$scope[ chartName ].data = data;
    
		$scope[ chartName ].view = {
			columns: [0, 1,
			   { 
			   	 calc: "stringify",
				 sourceColumn: 1,
				 type: "string",
				 role: "annotation" 
			   },
			   2]
		};
		
		$scope[ chartName ].formatters = {
		  number : [{
			columnNum: 1,
			"pattern": "#,###"
		  }]
		};
		
		$routeParams.chartType = 'BarChart';
		$scope[ chartName ].type = $routeParams.chartType;
		$scope[ chartName ].options = {
			'hAxis': { 
				textPosition: 'none' 
			},
			'legend': {
				position: 'none'
			},
			'backgroundColor': 'transparent',
			'colors': [$filter('chartColor')(chartTitle)]
		}
		
		
  	};
  	
  	$scope.processPieChart = function(chartName, chartTitle, data) {
  	
  		$scope[ chartName ] = {};
        
		$scope[ chartName ].data = data;
    
		$scope[ chartName ].view = {
			columns: [0, 1,
			   { 
			   	 calc: "stringify",
				 sourceColumn: 1,
				 type: "string",
				 role: "annotation" 
			   },
			   2]
		};
		
		$scope[ chartName ].formatters = {
		  number : [{
			columnNum: 1,
			"pattern": "#,###"
		  }]
		};
		
		$routeParams.chartType = 'PieChart';
		$scope[ chartName ].type = $routeParams.chartType;
		
		// grab the slice colors from Angular Filters
		var slices = $filter('sliceColors')(chartTitle);
		
		$scope[ chartName ].options = {
			'hAxis': { 
				textPosition: 'none' 
			},
			'pieSliceText': 'none',
			'slices': slices
		}
		
	};
	
	// This function is for the hide / show of the detailed Engagement Actions
	// charts (pie charts)
	$scope.pieChartDisplay = function() {
		if ($scope.showPieCharts == false) {
  			$scope.showPieCharts = true;
  			$scope.pieChartDisplayText = '-Show Less';
  		} else {
  			$scope.showPieCharts = false;
  			$scope.pieChartDisplayText = '+Show More';
  		}	
  	};
  	
  	$rootScope.showFilterModal = function() {
        $scope.modal('show');
  	};
  	
  	$scope.getAccountReport = function(platform, index) {
  		$scope.account;
  		
  		$scope.fansOrFollowers;
  		$scope.storyLikesOrFavorites;
  		
  		$scope.fansOrFollowersVal;
  		$scope.fansOrFollowersDelta;
  		
  		$scope.storyLikesOrFavoritesVal;
  		$scope.storyLikesOrFavoritesDelta;
  		
  		var breakdownData = [];
	
  		if (platform == 'Facebook') {
  			$scope.account = $scope.fbAccounts[ index ];
  			$scope.fansOrFollowers = 'New Fans';
  			$scope.storyLikesOrFavorites = 'Story Likes';
  			
			$scope.fansOrFollowersVal = $scope.account['values'][0].page_likes;
			$scope.fansOrFollowersDelta = $scope.account['values'][0]['changes'].page_likes.replace(' ', '');
		
			$scope.storyLikesOrFavoritesVal = $scope.account['values'][0].story_likes;
			$scope.storyLikesOrFavoritesDelta = $scope.account['values'][0]['changes'].story_likes.replace(' ', '');
			
			breakdownData.push(
				["", "Engagement Actions", { role: "style" } ],
				["Comments", $scope.account['values'][0].comments, '#45619D'],
				["Story Likes", $scope.account['values'][0].story_likes, '#45619D'],
				["Shares", $scope.account['values'][0].shares, '#45619D'],
				["Page Likes", $scope.account['values'][0].page_likes, '#45619D']
			);
			
			
  			
  		} else if (platform == 'Twitter') {
  			$scope.account = $scope.twAccounts[ index ];
  			$scope.fansOrFollowers = 'New Followers';
  			$scope.storyLikesOrFavorites = 'Favorites';
  			
  			$scope.fansOrFollowersVal = $scope.account['values'][0].followers;
			$scope.fansOrFollowersDelta = $scope.account['values'][0]['changes'].followers.replace(' ', '');
		
			$scope.storyLikesOrFavoritesVal = $scope.account['values'][0].favorites;
			$scope.storyLikesOrFavoritesDelta = $scope.account['values'][0]['changes'].favorites.replace(' ', '');
			
			breakdownData.push(
				["", "Engagement Actions", { role: "style" } ],
				["Retweets", $scope.account['values'][0].retweets, '#55ACEE'],
				["@Mentions", $scope.account['values'][0].mentions, '#55ACEE'],
				["Favorites", $scope.account['values'][0].favorites, '#55ACEE'],
				["Followers", $scope.account['values'][0].followers, '#55ACEE']
			);
  		}
  		

  		$scope.processLineChart('accountTrendChart', platform, $scope.account.trend);
  		$scope.processPieChart('accountPieChart', platform, breakdownData);
  		
  	
  		
  		$scope.engagementActions = $scope.account['values'][0].totals;
  		$scope.engagementActionsDelta = '5 %'.replace(' ', '');
  	};
  	
  	
  	$scope.selectDates = function(range) {
  		// Call Date service to determine start and end dates based on range
  		// $scope.a is the current start date and $scope.b is the current end date
  		var dateReturned = Dates.calcDates(range, $scope.a, $scope.b);

        // temporary hide datepicker
        $('body').trigger('click');

        // Show loading modal
        $('#loading-modal').modal('show');


        Reports.getData($scope.selectedRegions, $scope.selectedCountries, $scope.selectedLanguages,
		$scope.selectedNetworks, dateReturned.startDate, dateReturned.endDate)
			.then(function(response) {
				$scope.populateData(response);

                // hide loading modal
                $('#loading-modal').modal('hide');


		});
	
  	};
  	
  	$scope.print = function() {
  		$scope.showPieCharts = true;
  		$scope.pieChartDisplayText = '-Show Less';
  		setTimeout(print, 500);
			function print() {
				window.print();
			}
		
  	};
  
  
  	
  	
}

