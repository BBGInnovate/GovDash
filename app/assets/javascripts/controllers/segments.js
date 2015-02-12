function SegmentsCtrl($scope, Segments, $routeParams, $location) {"use strict";

  	$scope.create = function() {
  	
  		Segments.create(this.name, this.sc_id)
			.then(function(response) {
		   		$location.path('segments');
		});
	
  	};
  	
  	$scope.list = function() {
  		
  		//Segments.getAllSegments()
  		
  		Segments.getAllSegments()
            .then(function(response) {
               $scope.segments = response.data;
        });
  		
  	};
  	
  	$scope.find = function() {
  		Segments.getSegmentById($routeParams.segmentId)
            .then(function(response) {
               $scope.segment = response.data[0];
        });
  		
  	};
  	
  	$scope.update = function() {
  		Segments.update($routeParams.segmentId, $scope.segment.name, $scope.segment.sc_id)
            .then(function(response) {
               $location.path('segments');
        });
  		
  	};
  	
  	  	// delete (set is_active = 0) account
  	$scope.confirmDelete = function() {
  		
  		var segment = $scope.segments[$scope.segmentIndex];
  		
  		Segments.setInactive(segment.id, segment.sc_id)
            .then(function(response) {
               $scope.segments.splice( $scope.segmentIndex, 1 );
        });
        
  			
  	};
  	
  	// When user clicks on X (delete) button from list view
  	// get segment name from $scope object so confirmation modal has the segment name
  	$scope.getSegmentName = function(segmentIndex) {
  	
  		$scope.segmentIndex = segmentIndex;
  		var segmentToDelete = $scope.segments[segmentIndex];
  		$scope.segmentName = segmentToDelete.name;
  		
  	};
 	
  	
}

 