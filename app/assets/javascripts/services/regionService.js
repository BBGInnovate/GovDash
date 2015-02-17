angular.module('regionService', [])
    .factory('Regions', function($location, $http, $q, $rootScope) {
       
        var region = {
            

            create: function(name, description) {
            
                return $http.post('/api/regions', {region: {name: name } })
                .then(function(response) {
                //    console.log('Region Created!');
                });
                
            },
            getAllRegions: function() {
				return $http.get('/api/regions').then(function(response) {
					region = response;
					return region;
				});
            },
            getRegionById: function(regionId) {
            	return $http.get('api/regions/' + regionId).then(function(response) {
					region = response;
					return region;
				});
            },
            update: function(regionId, name, description) {
           // 	console.log ('update: ' + regionId + ' ' + name + '  ' + description);
            	return $http.put('api/regions/' + regionId, {region: {id: regionId, name: name } })
				.then(function(response) {
                    //console.log('Region Updated!');
                });
            }
            
        };
        return region;
    });
