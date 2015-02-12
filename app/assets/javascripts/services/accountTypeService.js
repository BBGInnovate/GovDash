angular.module('accountTypeService', [])
    .factory('AccountTypes', function($location, $http, $q, $rootScope) {
       
        var accountType = {
            
            getAllAccountTypes: function() {
				return $http.get('/api/account_types').then(function(response) {
					accountType = response;
					return accountType;
				});
            }
           
            
        };
        return accountType;
    });
