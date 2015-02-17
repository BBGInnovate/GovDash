angular.module('userService', [])
    .factory('Users', function($location, $http, $q) {
       
        var user = {
       
            getAllUsers: function () {
            	return $http.get('/api/users').then(function(response) {
            		return response.data;
                });
            },
            getUserById: function(userId) {
            	return $http.get('api/users/' + userId).then(function(response) {
					user = response;
					return user;
				});
            },
            update: function(userId, firstname, lastname, email, password, roleId) {
            	return $http.put('api/users/' + userId, {user: {id: userId, firstname: firstname, lastname: lastname, email: email, password: password, password_confirmation: password, role_id: roleId } })
				.then(function(response) {
                    
                });
            },
            // this function sets the is_active field to either 0 or 1 based on whether
            // the user is making a user account active or inactive
            setActivity: function(user, status) {
            	return $http.put('api/users/' + user.id, {user: { id: user.id, firstname: user.firstname, lastname: user.lastname, is_active: status } })
				.then(function(response) {
                   
                });
              
            }
            
        };
        return user;
    });
