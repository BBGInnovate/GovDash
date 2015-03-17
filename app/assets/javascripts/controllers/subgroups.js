function SubgroupsCtrl($scope, Subgroups, Groups, $routeParams, $rootScope, $location) {"use strict";
	
	//possible parent "groups"
	Groups.getAllGroups()
		.then(function(response) {
		   $scope.groups = response.data;
	});
  
  	$scope.create = function() {
  		Subgroups.create(this.name, this.description)
			.then(function(response) {
		   		$location.path('subgroups');
		});
		
		// Refresh list in header
		Subgroups.getAllSubgroups()
            .then(function(response) {
               $rootScope.subgroups = response.data;
        });
  	};
  	
  	$scope.list = function() {
  		  		
  		Subgroups.getAllSubgroups()
            .then(function(response) {
               $scope.subgroups = response.data;
        });
  		
  	};
  	
  	$scope.find = function() {
  		Subgroups.getSubgroupById($routeParams.subgroupId)
            .then(function(response) {
               $scope.subgroup = response.data[0];
               //get all groups
                /*Groups.getAllGroups()
                  .then(function(response) {
                    $scope.groups = response.data;
                     for (var i = 0; i < $scope.groups.length; i++) {
                      //set the group related to this subgroup
                      if ($scope.group[i].id == $scope.group.group_id) {
                         $scope.selectedGroup = $scope.group[i];
                      }
                     }
                });*/
        });
  		
  	};
  	
  	$scope.update = function() {
  		Subgroups.update($routeParams.subgroupId, $scope.subgroup.name, $scope.subgroup.description)
            .then(function(response) {
               $location.path('subgroups');
        });
  		
  	};
}

 