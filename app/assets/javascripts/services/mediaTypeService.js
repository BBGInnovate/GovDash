angular.module('mediaTypeService', [])
    .factory('MediaTypes', function($location, $http, $q, $rootScope) {
       
        var mediaType = {
            
            getAllMediaTypes: function() {
				return $http.get('/api/media_types').then(function(response) {
					mediaType = response;
					return mediaType;
				});
            }
           
            
        };
        return mediaType;
    });
