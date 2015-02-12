angular.module('dateService', [])
    .factory('Dates', function($location, $http, $q) {
       
        var date = {
            
            calcDates: function(range, origStartDate, origEndDate) {
            	var startDateObj;
				var endDateObj;
				
				
				if (range == 'week') {
					var d = new Date();

					// set to Monday of this week
					d.setDate(d.getDate() - (d.getDay() + 6) % 7);

					// set to previous Monday
					d.setDate(d.getDate() - 7);

					// create new date of day before
					startDateObj = new Date(d.getFullYear(), d.getMonth(), d.getDate() - 1);
					endDateObj = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 6);
			
				} else if (range == 'month') {
					var today = new Date();
					startDateObj = new Date(today.getFullYear(), today.getMonth() - 1, 1);
					endDateObj = new Date(today.getFullYear(), today.getMonth(), 0);
			
				} else if (range == 'quarter') {
					var today = new Date();
					var quarter = Math.floor((today.getMonth() + 3) / 3);
					var lastQuarter;
					if (quarter == 1) {
						lastQuarter = 4;
					} else {
						lastQuarter = quarter - 1;
					}
			
					var year = today.getFullYear();
					var lastYear = year - 1;
		
					if (lastQuarter == 1) {
						startDateObj = new Date(year,0,1);
						endDateObj = new Date(year,3,0);
					} else if (lastQuarter == 2) {
						startDateObj = new Date(year,3,1);
						endDateObj = new Date(year,6,0);
					} else if (lastQuarter == 3) {
						startDateObj = new Date(year,6,1);
						endDateObj = new Date(year,9,0);
					} else if (lastQuarter == 4) {
						startDateObj = new Date(lastYear,9,1);
						endDateObj = new Date(lastYear,12,0);
					}
			

				} else if (range == 'custom') {
					startDateObj = origStartDate;
					endDateObj = origEndDate;
		
					startDateObj.setDate(startDateObj.getDate() - 1);	
	
					// Date is off by a day
					endDateObj.setDate(endDateObj.getDate() - 1);	
		
			
				} 
		
				// Convert Date objects to YYYY-MM-DD for API call
				var startDate = startDateObj.toISOString().slice(0,10).replace(/-/g,"-");
				var endDate = endDateObj.toISOString().slice(0,10).replace(/-/g,"-");
		
		
				// 	Calculate difference in days
				//	var daysBack =  Math.floor(( second - first ) / 86400000);
		
		
				// Build Date object to return
            	var dateObj = {
    				startDate: startDate,
    				endDate: endDate
				};
                return dateObj;
           
            }
            
        };
        return date;
    });
