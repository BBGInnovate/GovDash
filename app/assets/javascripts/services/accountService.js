angular.module('accountService', [])
    .factory('Accounts', function($location, $http, $q, $rootScope) {
       
        var account = {
            
            create: function(name, description, object_name, socialMediaAccount, groupId, serviceId, languageId, regionIds, countryIds, accountTypeId, segmentIds) {
                return $http.post('/api/accounts', {account: {name: name, description: description, object_name: object_name, media_type_name: socialMediaAccount, group_id: groupId, service_id: serviceId, language_id: languageId, region_ids: regionIds, country_ids: countryIds, account_type_id: accountTypeId, sc_segment_ids: segmentIds } })
                .then(function(response) {
                //    console.log('Account Created!');
                });
                
            },
            getAllAccounts: function() {
				return $http.get('/api/accounts').then(function(response) {
					account = response;
					return account;
				});
            },
            getAccountById: function(accountId) {
            	return $http.get('api/accounts/' + accountId).then(function(response) {
					account = response;
					return account;
				});
            },
            update: function(accountId, name, description, object_name, socialMediaAccount, groupId, serviceId, languageId, regionIds, countryIds, accountTypeId, segmentIds) {
            	return $http.put('api/accounts/' + accountId, {account: { id: accountId, name: name, description: description, object_name: object_name, media_type_name: socialMediaAccount, group_id: groupId, service_id: serviceId, language_id: languageId, region_ids: regionIds, country_ids: countryIds, account_type_id: accountTypeId, sc_segment_ids: segmentIds } })
				.then(function(response) {
                    //console.log('Account Updated!');
                });
            },
            
            setInactive: function(accountId, name, description, object_name, socialMediaAccount, groupId, serviceId, languageId, regionIds, countryIds, accountTypeId) {
            	return $http.put('api/accounts/' + accountId, {account: { id: accountId, name: name, description: description, object_name: object_name, media_type_name: socialMediaAccount, group_id: groupId, service_id: serviceId, language_id: languageId, region_ids: regionIds, country_ids: countryIds, account_type_id: accountTypeId, is_active: 0 } })
				.then(function(response) {
                   
                });
            },
            
            getAllDataForAccounts: function() {
            	return $http.get('/api/accounts/lookups').then(function(response) {
					account = response;
					return account;
				});
            }
            
        };
        return account;
    });
