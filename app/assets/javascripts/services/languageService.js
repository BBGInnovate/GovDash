angular.module('languageService', [])
    .factory('Languages', function($location, $http, $q, $rootScope) {
       
        var languages = {
            
            getAllLanguages: function() {
				return $http.get('/api/languages').then(function(response) {
					languages = response;
					return languages;
				});
            }
           
            
        };
        return languages;
    });
