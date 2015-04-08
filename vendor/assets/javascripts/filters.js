/**
 * Filters
 */
 

angular.module('filters', []).
	// Display Facebook or Twitter icon
    filter('displayIcon', function () {
        return function (text) {
            return text.substring(0, text.length - 7).toLowerCase()

        };
    })
    // Display Positive or Negative Color
    .filter('valueColor', function () {
        return function (text) {
        	if (text != null) {
        		if (text.indexOf('-') > -1) {
        			text = 'down';
        		} else if(text.indexOf('N/A') > -1) {
        			text = 'na';
        		} else {
        			text = 'up';
        		}
            	return text;
            }

        };
    })
    // Truncate the word account from the field value
    .filter('truncate', function () {
        return function (text) {
            return text.substring(0, text.length - 7)

        };
    })
    // Filter for displaying roles name instead of ID
    .filter('displayRole', function () {
        return function (text) {
            switch(text) {
				case 1:
					return 'Administrator'
					break;
				case 2:
					return 'Analyst'
					break;
				case 3:
					return 'Service Chief'
					break;
				case 4:
					return 'Anonymous'
					break;		
				default:
					return 'Nobody'
			} 
        };
    })
     // Filter for displaying Status in UserList instead of true / false
    .filter('displayStatus', function () {
        return function (text) {
            if (text == true) {
            	return 'Active';
            } else {
            	return 'Inactive';
            }
        };
    })
     // Filter for displaying list of user selected Filters in 'My Filters' box
    .filter('removeCommaFromFilters', function () {
        return function (text) {
        	if (text) {
            	if (text.substring(text.length-2, text.length).indexOf (',') > -1 ) {
					text = text.slice(0, -2);
				}	
            }
            return text;
        };
    })
    // Custom date range display for tables
    .filter('customDateRange', function ($filter) {
        return function (text) {
        	Date.prototype.addHours= function(h){
				this.setHours(this.getHours()+h);
				return this;
			}
			
         	if (text != null) {
         		var startDate = new Date(text.substring(0,10));
         		startDate.addHours(4);
         		var endDate = new Date(text.substring(13,text.length));
         		endDate.addHours(4);
         		var _date = $filter('date')(startDate, 'mediumDate') + ' - ' + $filter('date')(endDate, 'mediumDate');
        
         	}
            return _date

        };
    })
    // Custom date range display for tables
    .filter('chartColor', function ($filter) {
        return function (text) {
        	switch(text) {
				case 'All':
					return '#6E7074'
					break;
				case 'Facebook':
					//return '#45619D'
					return '#084A94'
					break;
				case 'Twitter':
					return '#08AFC9'
					break;	
				default:
					return '#6E7074'
			} 
        };
    })
     // Display colors for piecharts
    .filter('sliceColors', function ($filter) {
        return function (chartTitle) {
        	var slices = {};
		
			if (chartTitle.indexOf('Facebook') > -1) {
				slices = {
					0: { color: '#0B3471' },
					1: { color: '#234D97' },
					2: { color: '#5A82B7' },
					3: { color: '#9AB1D2' }
				};
			} else if (chartTitle.indexOf('Twitter') > -1) { 
				slices = {
					0: { color: '#0088A4' },
					1: { color: '#08AFC9' },
					2: { color: '#1DBFD5' },
					3: { color: '#7BD1E0' }
				};
			}
			
			return slices;
        };
    })
     // Display regions / countries on Accounts popup and for 'Includes' section
    .filter('formatMap', function ($filter) {
        return function (arr) {
        	if (arr) {
        		var text = '';
        		for (key in arr) {
        			// Don't put 'All' in the full string
        			if (arr[key] != 'All') {
        				text += arr[key] + ', ';
        			}
        		}
        		if (text.substring(text.length-2, text.length).indexOf (',') > -1 ) {
					text = text.slice(0, -2);
				}	
        		return text;
        	}
        };
    })
      // Display regions / countries on Accounts popup and for 'Includes' section
    .filter('calcAllChangePercent', function ($filter) {
        return function (fbPercent, twPercent) {
        	if (fbPercent && twPercent) {
        		var fbPercentage = parseInt(fbPercent.slice(0, -2));
        		var twPercentage = parseInt(twPercent.slice(0, -2));
        		var percentage = (fbPercentage + twPercentage) / 2;
        		if (isNaN(percentage)) {
        			return 'N/A';
        		} else {
        			return percentage + ' %';
        		}
        	}
        };
    })
    // toString function for Array of values to be separated by commas
    .filter('toString', function () {
        return function (array) {
        	if (array) {
				var arrayString = '';
				for (var i = 0; i < array.length; i++) {
					arrayString += array[i] + ', ';
				}
				arrayString = arrayString.substring(0, arrayString.length - 2);
				return arrayString;
			}
        };
    })
	// returns array for social media colors by name
	.filter('socialMediaColors', function () {
		return function (socialMediaType) {
			if (socialMediaType) {
				var array = [];

				if (socialMediaType === 'fb') {
					array = ['#3278B3', '#5B93C2', '#84AED1', '#ADC9E0'];
				} else if (socialMediaType === 'tw') {
					array = ['#23B7E5', '#4FC6EA', '#7BD4EF', '#A7E2F4'];
				} else if (socialMediaType === 'yt') {
					array = ['#E36159', '#E87F7A', '#EE9F9B', '#F3BFBC'];
				}

				return array;
			}
		};
	})
	// returns the labels for social media account
	.filter('socialMediaLabels', function () {
		return function (socialMediaType) {
			if (socialMediaType) {
				var array = [];

				if (socialMediaType === 'fb') {
				//	array = ['comments', 'story_likes', 'shares', 'page_likes'];
					array = ['comments', 'story_likes', 'shares'];
				} else if (socialMediaType === 'tw') {
					array = ['retweets', 'mentions', 'favorites', 'followers'];
				} else if (socialMediaType === 'yt') {
					array = ['views', 'likes', 'comments', 'subscribers'];
				}

				return array;
			}
		};
	})
	// formats chart label properly
	.filter('labelFormat', function () {
		return function (label) {
			if (label) {
				if (label.indexOf('_') > -1) {
					var labels = label.split('_');
					return labels[0][0].toUpperCase() + labels[0].slice(1) + ' ' + labels[1][0].toUpperCase() + labels[1].slice(1);
				} else {
					return label[0].toUpperCase() + label.slice(1);
				}

			}
		};
	})
	// formats percent change on the tiles
	.filter('percentChange', function () {
		return function (label) {
			if (label) {
				label = label.replace(' ', '');
				if (label.indexOf('-') > -1) {
					return label.replace('-', '') + ' less than last week';
				} else {
					return label + ' greater than last week';
				}

			}
		};
	})
	// formats percent change on the account modal
	.filter('smLongNameProper', function () {
		return function (label) {
			if (label) {
				if (label === 'fb') {
					return 'Facebook';
				} else if (label === 'tw') {
					return 'Twitter';
				} else if (label === 'yt') {
					return 'YouTube';
				}

			}
		};
	})
	// formats date the proper way
	.filter('dateFormatMMDDYYYY', function () {
		return function (date) {
			if (date) {
				date = date.substring(0, 10);
				var dateArr = date.split('-');
				return dateArr[1] + '/' + dateArr[2] + '/' + dateArr[0];
			}
		};
	})
	// formats percent change on the tiles
	.filter('smLongName', function () {
		return function (label) {
			if (label) {
				if (label === 'fb') {
					return 'facebook';
				} else if (label === 'tw') {
					return 'twitter';
				} else if (label === 'yt') {
					return 'youtube';
				}

			}
		};
	});
