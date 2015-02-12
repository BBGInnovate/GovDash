function RecordCtrl($scope, Session, Records, Roles, Networks, $rootScope) {"use strict";

    $scope.user = Session.requestCurrentUser();
    $scope.records = Records.index();

    $scope.roles = Roles.roles();

    $scope.logout = function() {
        Session.logout();
    };
    
    $rootScope.networkList = function() {
  		
  		//Networks.getAllNetworks()
  		
  		Networks.getAllNetworks()
            .then(function(response) {
               $rootScope.networks = response.data;
        });
  		
  	};
}

