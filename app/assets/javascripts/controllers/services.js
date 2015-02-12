function ServicesCtrl($scope, Services) {"use strict";

	Services.getAllServices()
		.then(function(response) {
		   $scope.services = response.data;
	});
  
}

 