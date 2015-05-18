angular.module('sessionService', [])
    .factory('Session', function($location, $http, $q, $rootScope) {
        // Redirect to the given url (defaults to '/')
        function redirect(url) {
            url = url || '/';
          //  $location.path(url);
            $location.path('users/login');
        }
        var service = {
            login: function(email, password) {
                return $http.post('/api/sessions', {user: {email: email, password: password} })
                    .then(function(response) {
                        service.currentUser = response.data.user;
                        
                        $rootScope.loggedInUser = true;
                        $rootScope.email = response.data.user['email'];
                        $rootScope.userRole = response.data.user['role']['name'];
						$rootScope.isAdmin = response.data.user['is_admin'];

                        if (service.isAuthenticated()) {
                            //$location.path(response.data.redirect);
                           // $location.path('/record');
							$location.path('/');
                        }
                    });
            },

            logout: function(redirectTo) {
                $http.delete('/api/sessions').then(function(response) {
                    $http.defaults.headers.common['X-CSRF-Token'] = response.data.csrfToken;
                    service.currentUser = null;
                    $rootScope.loggedInUser = false;
                    $rootScope.userRole = null;
                    redirect(redirectTo);
                });
            },

            register: function(firstname, lastname, email, password, confirm_password) {
                return $http.post('/api/users', {user: {firstname: firstname, lastname: lastname, email: email, password: password, password_confirmation: confirm_password} })
                .then(function(response) {
                    service.currentUser = response.data;
                    if (service.isAuthenticated()) {
                        $location.path('/');
                    }
                });
            },
            requestCurrentUser: function() {
                if (service.isAuthenticated()) {
                    return $q.when(service.currentUser);
                } else {
                    return $http.get('/api/users').then(function(response) {
                        service.currentUser = response.data.user;
                        return service.currentUser;
                    });
                }
            },

            currentUser: null,

            isAuthenticated: function(){
                return !!service.currentUser;
            }, 
            // this function is used for page reloads (refresh)... if the user refreshes
            // the page, make a quick API call to see if the server still authenticates
            // the user
            checkUserLoggedIn: function() {
            	return $http.post('/api/sessions').then(function(response) {
            	//	console.log(response);
            		if (response.status != 401) {
            			$rootScope.userRole = response.data['user']['role']['name'];
            		}
            		return response.data;
                });
            }
        };
        return service;
    });
