function GroupsCtrl($scope, Groups, Session, $routeParams, $rootScope, $location) {"use strict";

  	$scope.create = function() {
  	
  		Groups.create(this.name, this.description)
			.then(function(response) {
		   		$location.path('groups');
		});
		
		// Refresh list in header
		Groups.getAllGroups()
            .then(function(response) {
               $rootScope.groups = response.data;
        });
  	};
  	
  	$scope.list = function() {
  		  		
  		Groups.getAllGroups()
            .then(function(response) {
               $scope.groups = response.data;
        });
  		
  	};
  	
  	$scope.find = function() {
  		Groups.getGroupById($routeParams.groupId)
            .then(function(response) {
               $scope.group = response.data[0];
               //TODO: see accounts.js for examples populating the reference model
               var organizationId = $scope.group.organization_id;
        });
  		
  	};
  	
  	$scope.update = function() {
  		Groups.update($routeParams.groupId, $scope.group.name, $scope.group.description)
            .then(function(response) {
               $location.path('groups');
        });
  		
  	};
  	
  	
}

 