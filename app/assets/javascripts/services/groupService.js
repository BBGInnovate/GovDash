 angular.module('groupService', [])
    .factory('Groups', function($location, $http, $q, $rootScope) {
       
        var group = {
            

            create: function(name, description) {
            
                return $http.post('/api/groups', {group: {name: name, description: description } })
                .then(function(response) {
                //    console.log('Group Created!');
                });
                
            },
            getAllGroups: function() {
				return $http.get('/api/groups').then(function(response) {
					group = response;
					return group;
				});
            },
            getGroupById: function(groupId) {
            	return $http.get('api/groups/' + groupId).then(function(response) {
					group = response;
					return group;
				});
            },
            update: function(groupId, name, description) {
            	console.log ('update: ' + groupId + ' ' + name + '  ' + description);
            	return $http.put('api/groups/' + groupId, {group: {id: groupId, name: name, description: description } })
				.then(function(response) {
                    //console.log('Group Updated!');
                });
            }
            
        };
        return group;
    });
