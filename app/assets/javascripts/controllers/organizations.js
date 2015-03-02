function OrganizationsCtrl($scope, Organizations, Session, $routeParams, $rootScope, $location) {"use strict";

  	$scope.create = function() {
  	
  		Organizations.create(this.name)
			.then(function(response) {
		   		$location.path('organizations');
		});
		
		// Refresh list in header
		Organizations.getAllOrganizations()
            .then(function(response) {
               $rootScope.organizations = response.data;
        });
  	};
  	
  	$scope.list = function() {
  		  		
  		Organizations.getAllOrganizations()
            .then(function(response) {
               $scope.organizations = response.data;
        });
  		
  	};
  	
  	$scope.find = function() {
  		Organizations.getOrganizationById($routeParams.organizationId)
            .then(function(response) {
               $scope.organization = response.data[0];
        });
  		
  	};
  	
  	$scope.update = function() {
  		Organizations.update($routeParams.organizationId, $scope.organization.name)
            .then(function(response) {
               $location.path('organizations');
        });
  		
  	};
  	
  	
}

 