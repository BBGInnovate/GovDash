function AppCtrl($scope, Session, $location, $rootScope) {"use strict";
    $scope.$on('event:unauthorized', function(event) {
        console.log('unauthorized');
    });
    $scope.$on('event:authenticated', function(event) {
        console.log('authenticated');
         $scope.loggedIn = true;
    });
    
    $scope.logout = function() {
        Session.logout();
    };
/*
	$scope.goHome = function () {
		console.log($location);
		if ($rootScope.loggedInUser === true) {
			$location.path('/#');
		} else {
			$location.path('/users/login');
		}
	};
*/


}