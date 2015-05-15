function UsersCtrl($scope, Session, $rootScope, Users, $routeParams, $location, Roles, RolesAPI) {"use strict";
    $scope.login = function(user) {
        $scope.authError = null;

        Session.login(user.email, user.password)
        .then(function(response) {
        /*
            if (!response) {
                $scope.authError = 'Credentials are not valid';
            } else {
                $scope.authError = 'Success!';
            }
            */
        }, function(response) {
         //   $scope.authError = 'Server offline, please try later';
         	  $scope.authError = 'Invalid username / password';
         	  $rootScope.loggedInUser = false;
        });
    };

    $scope.logout = function(user) {
		
    };

    $scope.register = function(user) {
        $scope.authError = null;

        Session.register(user.firstname, user.lastname, user.email, user.password, user.confirm_password)
            .then(function(response) {
               console.log(response);
            }, function(response) {
                var errors = '';
                $.each(response.data.errors, function(index, value) {
                    errors += index.substr(0,1).toUpperCase()+index.substr(1) + ' ' + value + ''
                });
                $scope.authError = errors;
            });
    };
    
    // lists all users
  	$scope.list = function() {
  		Users.getAllUsers()
            .then(function(response) {
               $scope.users = response;
               $scope.activeUser = $rootScope.email;
        });
  	};
  	
  	$scope.find = function() {
  		Users.getUserById($routeParams.userId)
            .then(function(response) {
               $scope.user = response.data[0];
             //  var roleId = $scope.user.role.id;
            
            	// Get all Roles and pre-select the one from the users record
               RolesAPI.getAllRoles()
					.then(function(response) {
					   $scope.roles = response;

					   $scope.selectedRole = $scope.user.roles;


			   });
 	
        });	
  	};
  	
  	$scope.update = function() {
  		Users.update($routeParams.userId, $scope.user.firstname, $scope.user.lastname, $scope.user.email, $scope.password1, $scope.selectedRole)
            .then(function(response) {
               $location.path('users');
        });
  	};
  	
  	// delete (set is_active = 0) account
  	$scope.confirmDelete = function() {
  		
  		var user = $scope.users[$scope.userIndex];
  		var status = 0; // inactive
  		Users.setActivity(user, status)
            .then(function(response) {
            	$scope.users[$scope.userIndex]['is_active'] = false;
        });
        
  		
  	};
  	
  	// activate (set is_active = 1) account
  	$scope.setActive = function() {
  		
  		var status = 1; // inactive
  		Users.setActivity($scope.user, status)
            .then(function(response) {
            	//$scope.users[$scope.userIndex]['is_active'] = false;
        });
        
  		
  	};
  	
  	// When user clicks on X (delete) button from list view
  	// get user name from $scope object so confirmation modal has the user name
  	$scope.getUserName = function(userIndex) {
  		$scope.userIndex = userIndex;
  		var userToDelete = $scope.users[userIndex];
  		$scope.firstName = userToDelete.firstname;
  		$scope.lastName = userToDelete.lastname;
  		$scope.email = userToDelete.email;
  	};
}

