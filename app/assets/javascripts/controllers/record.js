function RecordCtrl($scope, Session, Records, Roles, Groups, $rootScope) {"use strict";

    $scope.user = Session.requestCurrentUser();
    $scope.records = Records.index();

    $scope.roles = Roles.roles();

    $scope.logout = function() {
        Session.logout();
    };
    
    $rootScope.groupList = function() {
  		  		
  		Groups.getAllGroups()
            .then(function(response) {
               $rootScope.groups = response.data;
        });
  		
  	};
}

