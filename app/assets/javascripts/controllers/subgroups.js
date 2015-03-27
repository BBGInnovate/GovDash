function SubgroupsCtrl($scope, Subgroups, Groups, $routeParams, $rootScope, $location) {"use strict";
	
  	//possible parent "groups"
  	Groups.getAllGroups()
  	 	.then(function(response) {
  	 	   $scope.groups = response.data;
  	 });
  
  	$scope.create = function() {

      var groups = [];
      for (var i = 0; i < this.selectedGroups.length; i++) {
        groups.push(this.selectedGroups[i].id);
      }

  		Subgroups.create(this.name, this.description, groups)
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
               //init array of selected groups
               var selectedGroups = [];
               //get all groups
                Groups.getAllGroups()
                  .then(function(response) {
                    $scope.groups = response.data;
                    if($scope.subgroup.related_groups) {
                      //set the scope.groups objects that match related_groups to selectedGroups
                      for (var i = 0; i < $scope.groups.length; i++) {
                        for (var j = 0; j < $scope.subgroup.related_groups.length; j++) {
                          if ($scope.groups[i].id == $scope.subgroup.related_groups[j].id){
                            selectedGroups.push($scope.groups[i]);
                          }
                        }
                      }
                    } 
                    $scope.selectedGroups = selectedGroups;
                });
        });
  		
  	};
  	
  	$scope.update = function() {
      //init array of "select groups" id's
      var groups = [];
      for (var i = 0; i < $scope.selectedGroups.length; i++) {
        groups.push($scope.selectedGroups[i].id);
      }
      console.log(groups);
  		Subgroups.update($routeParams.subgroupId, $scope.subgroup.name, $scope.subgroup.description, groups)
            .then(function(response) {
               $location.path('subgroups');
        });
  		
  	};
}

 