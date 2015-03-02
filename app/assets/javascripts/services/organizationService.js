 angular.module('organizationService', [])
    .factory('Organizations', function($location, $http, $q, $rootScope) {
       
        var organization = {
            

            create: function(name) {
                return $http.post('/api/organizations', {organization: {name: name } })
                .then(function(response) {
                //    console.log('Org Created!');
                });
                
            },
            getAllOrganizations: function() {
				return $http.get('/api/organizations').then(function(response) {
					organization = response;
					return organization;
				});
            },
            getOrganizationById: function(organizationId) {
            	return $http.get('api/organizations/' + organizationId).then(function(response) {
					organization = response;
					return organization;
				});
            },
            update: function(organizationId, name) {
            	console.log ('update: ' + organizationId + ' ' + name);
            	return $http.put('api/organizations/' + organizationId, {organization: {id: organizationId, name: name } })
				.then(function(response) {
                    //console.log('Org Updated!');
                });
            }
            
        };
        return organization;
    });
