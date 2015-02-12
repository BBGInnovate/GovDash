angular.module('roleService', ['ngResource'])
    .factory('Roles', function($resource) {
        return $resource('/api/record/roles', {}, {
            roles: { method: 'GET', isArray: true, cache: false},
            create: { method: 'POST' }
        });
        
       
    })
    .factory('RolesAPI', function($location, $http, $q, $rootScope) {
    
         var role = {
            getAllRoles: function() {
				return $http.get('/api/record/roles').then(function(response) {
					role = response.data;
					return role;
				});
            }
        };
        return role;
    });