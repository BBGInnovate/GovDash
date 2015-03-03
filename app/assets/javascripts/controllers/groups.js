function GroupsCtrl($scope, Groups, Organizations, Session, $routeParams, $rootScope, $location) {"use strict";

    Organizations.getAllOrganizations()
      .then(function(response) {
        $scope.organizations = response.data;
    });

  	$scope.create = function() {
  		Groups.create(this.name, this.description, this.selectedOrganization.id)
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
               //get all organizations
                Organizations.getAllOrganizations()
                  .then(function(response) {
                    $scope.organizations = response.data;
                     for (var i = 0; i < $scope.organizations.length; i++) {
                      //set the organization related to this group
                      if ($scope.organizations[i].id == $scope.group.organization_id) {
                         $scope.selectedOrganization = $scope.organizations[i];
                      }
                     }
                });
        });
  		
  	};
  	
  	$scope.update = function() {
  		Groups.update($routeParams.groupId, $scope.group.name, $scope.group.description, $scope.selectedOrganization.id)
            .then(function(response) {
               $location.path('groups');
        });
  		
  	};
  	
  	
}

 