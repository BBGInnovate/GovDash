function AccountsCtrl($scope, Accounts, $routeParams, $rootScope, $location, $filter) {"use strict";

	// create an account
  	$scope.create = function() {
  	
  		var regions = [];
  		for (var i = 0; i < this.selectedRegion.length; i++) {
  			regions.push(this.selectedRegion[i].id);
  		}
  		
  		var countries = [];
		for (var i = 0; i < this.selectedCountry.length; i++) {
  			countries.push(this.selectedCountry[i].id);
  		}
  		
  		var segments = [];
		for (var i = 0; i < this.selectedSegment.length; i++) {
  			segments.push(this.selectedSegment[i].id);
  		}
  		
  		
  		
  						// name field				 // object_name field
  		Accounts.create(this.name, this.description, this.object_name, 
  		this.selectedMediaType.name, this.selectedGroup.id,  this.selectedSubgroup.id, 
  		this.selectedLanguage.id, regions, countries, this.selectedAccountType.id,
  		segments)
			.then(function(response) {
		   		$location.path('accounts');
		});
	

  	};
  	
  	// lists all accounts
  	$scope.list = function() {
  		var orderBy = $filter('orderBy');
  		
  		Accounts.getAllAccounts()
            .then(function(response) {
               $scope.accounts = response.data;
               
               // Handles array for sorting table
               $scope.order = function(predicate, reverse) {
			   		$scope.accounts = orderBy($scope.accounts, predicate, reverse);
			   };
			
        });
       
		
		 
       
  	};
  	
  	
  	// Populates data elements for editing an account
  	$scope.find = function() {
  		Accounts.getAccountById($routeParams.accountId)
            .then(function(response) {
               $scope.account = response.data[0];
               var groupId = $scope.account.group_id;
               var subgroupId = $scope.account.subgroup_id;
               var regionIds = $scope.account.region_ids;
               var countryIds = $scope.account.country_ids;
               var accountTypeId = $scope.account.account_type_id;
               var mediaType = $scope.account.media_type_name;
               var languageId = $scope.account.language_id;
               var segmentIds = $scope.account.segment_ids;
            
               var mediaTypeId;
             
           
			   if (mediaType.indexOf('Facebook') > -1) {
					mediaTypeId = 1;
			   } else if (mediaType.indexOf('Twitter') > -1) {
					mediaTypeId = 2;
			   }
             
           
			   // Load all data for Accounts
			   
			   // The looping that occurs in the promise below is because the API
			   // brings out the data in alphabetical order and the selected element
			   // in the Angular dropdown needs to be found. The Ids are provided in the 
			   // individual objects object (groupId, subgroupId, etc.) 
				Accounts.getAllDataForAccounts()
					.then(function(response) {
					   $scope.allData = response.data;
			  
					   var groups = $scope.allData[0];
					   groups.shift();
					   $scope.groups = groups;
					   for (var i = 0; i < $scope.groups.length; i++) {
							if ($scope.groups[i].id == groupId) {
								 $scope.selectedGroup = $scope.groups[i];
							}
					   }
			   			
			   		   //TODO: how to handle more than one subgroup
					   var subgroups = $scope.allData[1];
					   subgroups.shift();
					   $scope.subgroups = subgroups;
					   for (var i = 0; i < $scope.subgroups.length; i++) {
							if ($scope.subgroups[i].id == subgroupId) {
								 $scope.selectedSubgroup = $scope.subgroups[i];
							}
					   }
		
			   
					   var regions = $scope.allData[2];
					   regions.shift();
					   $scope.regions = regions;
					   var selectedRegions = [];
					   /*
					   // Loop through the regionIds and push them to objects so 
					   // Angular can pre-populate the select dropdown
					   for (var i = 0; i < regionIds.length; i++) {
							selectedRegions.push($scope.regions[regionIds[i] - 1]);
					   }
					   $scope.selectedRegion = selectedRegions;
					   */
					   for (var i = 0; i < $scope.regions.length; i++) {
					   		for (var j = 0; j < regionIds.length; j++) {
					   			if ($scope.regions[i].id == regionIds[j]) {
					   				selectedRegions.push($scope.regions[i]);
					   			}
					   		}
					   }
					   $scope.selectedRegion = selectedRegions;
			   
					   var accountTypes = $scope.allData[3];
					   accountTypes.shift();
					   $scope.accountTypes = accountTypes;
					   for (var i = 0; i < $scope.accountTypes.length; i++) {
							if ($scope.accountTypes[i].id == accountTypeId) {
								 $scope.selectedAccountType = $scope.accountTypes[i];
							}
					   }
			   
					   var mediaTypes = $scope.allData[4];
					   mediaTypes.shift();
					   $scope.mediaTypes = mediaTypes;
					   for (var i = 0; i < $scope.mediaTypes.length; i++) {
							if ($scope.mediaTypes[i].id == mediaTypeId) {
								 $scope.selectedMediaType = $scope.mediaTypes[i];
							}
					   }
			   
					   var countries = $scope.allData[5];
					   countries.shift();
					   $scope.countries = countries;
					   var selectedCountries = [];
					   /*
					   // Loop through the countryIds and push them to objects so 
					   // Angular can pre-populate the select dropdown
					   for (var i = 0; i < countryIds.length; i++) {
							selectedCountries.push($scope.countries[countryIds[i] - 1]);
					   }
					   $scope.selectedCountry = selectedCountries;
					   */
					   for (var i = 0; i < $scope.countries.length; i++) {
					   		for (var j = 0; j < countryIds.length; j++) {
					   			if ($scope.countries[i].id == countryIds[j]) {
					   				selectedCountries.push($scope.countries[i]);
					   			}
					   		}
					   }
					   $scope.selectedCountry = selectedCountries;
			  
			  
			   
					   var languages = $scope.allData[6];
					   languages.shift();
					   $scope.languages = languages;
					   for (var i = 0; i < $scope.languages.length; i++) {
							if ($scope.languages[i].id == languageId) {
								 $scope.selectedLanguage = $scope.languages[i];
							}
					   }
					   
					   var segments = $scope.allData[7];
					   segments.shift();
					   $scope.segments = segments;
					   var selectedSegments = [];
					   /*
					   // Loop through the segmentIds and push them to objects so 
					   // Angular can pre-populate the select dropdown
					   for (var i = 0; i < segmentIds.length; i++) {
							selectedSegments.push($scope.segments[segmentIds[i] - 1]);
					   }
					   $scope.selectedSegment = selectedSegments;
					   */
					   for (var i = 0; i < $scope.segments.length; i++) {
					   		for (var j = 0; j < segmentIds.length; j++) {
					   			if ($scope.segments[i].id == segmentIds[j]) {
					   				selectedSegments.push($scope.segments[i]);
					   			}
					   		}
					   }
					   $scope.selectedSegment = selectedSegments;
			  
					   
				
				});
		
        });
        
       
  		
  	};
  	
  	$scope.update = function() {
  		var regions = [];
  		for (var i = 0; i < $scope.selectedRegion.length; i++) {
  			regions.push($scope.selectedRegion[i].id);
  		}
  		
  		var countries = [];
		for (var i = 0; i < $scope.selectedCountry.length; i++) {
  			countries.push($scope.selectedCountry[i].id);
  		}
  		
  		var segments = [];
		for (var i = 0; i < this.selectedSegment.length; i++) {
  			segments.push(this.selectedSegment[i].id);
  		}
  		
  		Accounts.update($routeParams.accountId, $scope.account.name, 
  		$scope.account.description, $scope.account.object_name, $scope.media_type_name, 
  		$scope.selectedGroup.id, $scope.selectedSubgroup.id, $scope.selectedLanguage.id, 
  		regions, countries, $scope.selectedAccountType.id, segments)
            .then(function(response) {
               $location.path('accounts');
        });
  		
  	};
  	
  	// Populates data elements for Account creation
  	$scope.populateDataElements = function() {
		// Load all data for Accounts
		Accounts.getAllDataForAccounts()
			.then(function(response) {
			   $scope.allData = response.data;
			  
			   var groups = $scope.allData[0];
			   groups.shift();
			   $scope.groups = groups;
			   
			   var subgroups = $scope.allData[1];
			   subgroups.shift();
			   $scope.subgroups = subgroups;
			   
			   var regions = $scope.allData[2];
			   regions.shift();
			   $scope.regions = regions;
			   $scope.selectedRegion = $scope.regions[0];
			   
			   var accountTypes = $scope.allData[3];
			   accountTypes.shift();
			   $scope.accountTypes = accountTypes;
//			   $scope.selectedAccountType = $scope.accountTypes[0];
			   
			   var mediaTypes = $scope.allData[4];
			   mediaTypes.shift();
			   $scope.mediaTypes = mediaTypes;
//			   $scope.selectedMediaType = $scope.mediaTypes[0];
			   
			   var countries = $scope.allData[5];
			   countries.shift();
			   $scope.countries = countries;
			   $scope.selectedCountry = $scope.countries[0];
			   
			   var languages = $scope.allData[6];
			   languages.shift();
			   $scope.languages = languages;
//			   $scope.selectedLanguage = $scope.languages[0];
			   
			   var segments = $scope.allData[7];
			   segments.shift();
			   $scope.segments = segments;
//			   $scope.selectedSegment = $scope.segments[0];
			
		});
		
  	};
  	
  	// delete (set is_active = 0) account
  	$scope.confirmDelete = function() {
  		
  		var account = $scope.accounts[$scope.accountIndex];
  		
  		Accounts.setInactive(account.id, account.name, 
  		account.description, account.object_name, account.media_type_name, 
  		account.group_id, account.subgroup_id, account.language_id, 
  		account.region_ids, account.country_ids, account.account_type_id)
            .then(function(response) {
               $scope.accounts.splice( $scope.accountIndex, 1 );
        });
        
  			
  	};
  	
  	// When user clicks on X (delete) button from list view
  	// get account name from $scope object so confirmation modal has the account name
  	$scope.getAccountName = function(accountIndex) {
  	
  		$scope.accountIndex = accountIndex;
  		var accountToDelete = $scope.accounts[accountIndex];
  		$scope.accountName = accountToDelete.name;
  		
  	};
  	
  
}

 