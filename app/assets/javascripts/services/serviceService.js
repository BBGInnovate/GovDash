angular.module('serviceService', [])
    .factory('Services', function($location, $http, $q, $rootScope) {
       
        var service = {
            

            create: function(name, description) {
            
                return $http.post('/api/services', {service: {name: name, description: description } })
                .then(function(response) {
                //    console.log('Service Created!');
                });
                
            },
            getAllServices: function() {
				return $http.get('/api/services').then(function(response) {
					service = response;
					return service;
				});
            },
            getServiceById: function(serviceId) {
            	return $http.get('api/services/' + serviceId).then(function(response) {
					service = response;
					return service;
				});
            },
            update: function(serviceId, name, description) {
            	//console.log ('update: ' + serviceId + ' ' + name + '  ' + description);
            	return $http.put('api/services/' + serviceId, {service: {id: serviceId, name: name, description: description } })
				.then(function(response) {
                    //console.log('Service Updated!');
                });
            }
            
        };
        return service;
    });
