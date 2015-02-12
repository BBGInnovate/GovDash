function CountriesCtrl($scope, Countries, Session, Regions, $routeParams, $rootScope, $location) {"use strict";
	
  	$scope.create = function() {

  		Countries.create(this.name, this.selectedRegion.id)
			.then(function(response) {
		   		$location.path('countries');
		});
  	};
  	
  	$scope.list = function() {
  	
  		Countries.getAllCountries()
            .then(function(response) {
               $scope.countries = response.data;
        });
  		
  	};
  	
  	$scope.find = function() {
  		Countries.getCountryById($routeParams.countryId)
            .then(function(response) {
               $scope.country = response.data[0];
        	   var regionId = $scope.country.region_id;
        	   
        	 // Load Regions for Countries and pre-select one from country record
			Regions.getAllRegions()
				.then(function(response) {
				   $scope.regions = response.data;
				   $scope.selectedRegion = $scope.regions[regionId - 1];
			});
        });
  		
  	};
  	
  	$scope.update = function() {
  		Countries.update($routeParams.countryId, $scope.country.name, $scope.selectedRegion.id)
            .then(function(response) {
               $location.path('countries');
        });
  		
  	};
  	
  	
  	$scope.loadRegions = function() {
  		// Load Regions for Countries
		Regions.getAllRegions()
			.then(function(response) {
			   $scope.regions = response.data;
			   $scope.selectedRegion = $scope.regions[0];
		});
  	};
  	
  	
}

 