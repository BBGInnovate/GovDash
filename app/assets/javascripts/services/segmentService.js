angular.module('segmentService', [])
    .factory('Segments', function($location, $http, $q, $rootScope) {
       
        var segment = {
            

            create: function(name, sc_id) {
            
                return $http.post('/api/segments', {sc_segment: {name: name, sc_id: sc_id} })
                .then(function(response) {
                //    console.log('Segment Created!');
                });
                
            },
            getAllSegments: function() {
				return $http.get('/api/segments').then(function(response) {
					segment = response;
					return segment;
				});
            },
            getSegmentById: function(segmentId) {
            	return $http.get('api/segments/' + segmentId).then(function(response) {
					segment = response;
					return segment;
				});
            },
            update: function(segmentId, name, sc_id) {
            	return $http.put('api/segments/' + segmentId, {sc_segment: {id: segmentId, name: name, sc_id: sc_id } })
				.then(function(response) {
                    //console.log('Segment Updated!');
                });
            },
            setInactive: function(segmentId, name, sc_id) {
            	return $http.delete('api/segments/' + segmentId, {sc_segment: {id: segmentId, name: name, sc_id: sc_id } })
				.then(function(response) {
                   
                });
            }
            
        };
        return segment;
    });
