function NetworksCtrl($scope, Networks, Session, $routeParams, $rootScope, $location) {"use strict";

  	$scope.create = function() {
  	
  		Networks.create(this.name, this.description)
			.then(function(response) {
		   		$location.path('networks');
		});
		
		// Refresh list in header
		Networks.getAllNetworks()
            .then(function(response) {
               $rootScope.networks = response.data;
        });
  	};
  	
  	$scope.list = function() {
  		
  		//Networks.getAllNetworks()
  		
  		Networks.getAllNetworks()
            .then(function(response) {
               $scope.networks = response.data;
        });
  		
  	};
  	
  	$scope.find = function() {
  		Networks.getNetworkById($routeParams.networkId)
            .then(function(response) {
               $scope.network = response.data[0];
        });
  		
  	};
  	
  	$scope.update = function() {
  		Networks.update($routeParams.networkId, $scope.network.name, $scope.network.description)
            .then(function(response) {
               $location.path('networks');
        });
  		
  	};
  	
  	
}

 