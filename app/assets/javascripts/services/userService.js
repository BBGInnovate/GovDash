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
            update: function(userId, firstname, lastname, email, password, roles) {
            	return $http.put('api/users/' + userId, {user: {id: userId, firstname: firstname, lastname: lastname, email: email, password: password, password_confirmation: password, roles: roles } })
				.then(function(response) {
                    
                });
            },
            // this function sets the is_active field to either 0 or 1 based on whether
            // the user is making a user account active or inactive
            setActivity: function(user, status) {
            	return $http.put('api/users/' + user.id, {user: { id: user.id, firstname: user.firstname, lastname: user.lastname, is_active: status } })
				.then(function(response) {
                   
                });
              
            },
            resetPassword: function(email) {
                return $http.get('/api/users/forget_password?email=' + email)
                    .then(function(response) {
                        return response;
                    });
            },
            changePassword: function(user) {
                return $http.put('api/users/' + user.id, {"user":{"password": user.password, "password_confirmation": user.password_confirmation }} )
                    .then(function(response) {
                        return response;
                    });
            }
        };
        return user;
    });
