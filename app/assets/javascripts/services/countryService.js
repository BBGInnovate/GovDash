angular.module('countryService', [])
    .factory('Countries', function($location, $http, $q, $rootScope) {
       
        var country = {
            

            create: function(name, regionId) {
                return $http.post('/api/countries', {country: {name: name, region_id: regionId } })
                .then(function(response) {
                
                });
            },
            getAllCountries: function() {
				return $http.get('/api/countries').then(function(response) {
					country = response;
					return country;
				});
            },
            getCountryById: function(countryId) {
            	return $http.get('api/countries/' + countryId).then(function(response) {
					country = response;
					return country;
				});
            },
            update: function(countryId, name, regionId) {
            	return $http.put('api/countries/' + countryId, {country: {id: countryId, name: name, region_id: regionId } })
				.then(function(response) {
                    
                });
            }
            
        };
        return country;
    });
