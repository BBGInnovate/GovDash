function RegionsCtrl($scope, Regions, Session, $routeParams, $rootScope, $location) {"use strict";

  	$scope.create = function() {
  	
  		Regions.create(this.name)
			.then(function(response) {
		   		$location.path('regions');
		});
		
		// Refresh list in header
		Regions.getAllRegions()
            .then(function(response) {
               $rootScope.regions = response.data;
        });
  	};
  	
  	$scope.list = function() {
  		
  		//Regions.getAllRegions()
  		
  		Regions.getAllRegions()
            .then(function(response) {
               $scope.regions = response.data;
        });
  		
  	};
  	
  	$scope.find = function() {
  		Regions.getRegionById($routeParams.regionId)
            .then(function(response) {
               $scope.region = response.data[0];
        });
  		
  	};
  	
  	$scope.update = function() {
  		Regions.update($routeParams.regionId, $scope.region.name)
            .then(function(response) {
               $location.path('regions');
        });
  		
  	};
  	
  	
}

 