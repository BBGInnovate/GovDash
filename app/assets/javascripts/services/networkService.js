/*
angular.module('networkService', ['ngResource'])
    .factory('Networks', function($resource) {
        return $resource('/api/networks.json', {}, {
            index: { method: 'GET', isArray: true}
        });
    });
    
    .factory('CreateNetwork', function(name, description){
    	console.log(name);
    	console.log(description);
 /*
		return $http.post('/api/users', {user: {firstname: firstname, lastname: lastname, email: email, password: password, password_confirmation: confirm_password} })
		.then(function(response) {
			service.currentUser = response.data;
			if (service.isAuthenticated()) {
				$location.path('/record');
			}
		});
    (/     
    }); 
 */
 
 angular.module('networkService', [])
    .factory('Networks', function($location, $http, $q, $rootScope) {
       
        var network = {
            

            create: function(name, description) {
            
                return $http.post('/api/networks', {network: {name: name, description: description } })
                .then(function(response) {
                //    console.log('Network Created!');
                });
                
            },
            getAllNetworks: function() {
				return $http.get('/api/networks').then(function(response) {
					network = response;
					return network;
				});
            },
            getNetworkById: function(networkId) {
            	return $http.get('api/networks/' + networkId).then(function(response) {
					network = response;
					return network;
				});
            },
            update: function(networkId, name, description) {
            	console.log ('update: ' + networkId + ' ' + name + '  ' + description);
            	return $http.put('api/networks/' + networkId, {network: {id: networkId, name: name, description: description } })
				.then(function(response) {
                    //console.log('Network Updated!');
                });
            }
            
        };
        return network;
    });
