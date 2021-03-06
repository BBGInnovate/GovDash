function AccountsCtrl($scope, Accounts, $routeParams, $rootScope, $location, $filter) {"use strict";

	// create an account
  	$scope.create = function() {

		var languages = [];
		for (var i = 0; i < this.selectedLanguage.length; i++) {
			languages.push(this.selectedLanguage[i].id);
		}
  	
  		var regions = [];
  		for (var i = 0; i < this.selectedRegion.length; i++) {
  			regions.push(this.selectedRegion[i].id);
  		}

		var groups = [];
		for (var i = 0; i < this.selectedGroup.length; i++) {
			groups.push(this.selectedGroup[i].id);
		}

  		var subgroups = [];
  		for (var i = 0; i < this.selectedSubgroup.length; i++) {
  			subgroups.push(this.selectedSubgroup[i].id);
  		}
  		
  		var countries = [];
		for (var i = 0; i < this.selectedCountry.length; i++) {
  			countries.push(this.selectedCountry[i].id);
  		}
  		
  		var segments = [];
		if (this.selectedSegment) {
			for (var i = 0; i < this.selectedSegment.length; i++) {
				segments.push(this.selectedSegment[i].id);
			}
		}

  		
  		Accounts.create(this.name, this.description, this.object_name, 
  		this.selectedMediaType.name, groups, subgroups,
			languages, regions, countries, this.selectedAccountType.id, segments)
			.then(function(response) {
				// an error returned from the backend
				if (response.data.error) {

					var errorMsg = JSON.parse(response.data.error).username[0];

					// add border on input color
					$('#object_name').addClass('error-input');

					// Display notification
					noty({
						text: errorMsg,
						type: 'error',
						layout: 'topCenter',
						timeout: '5000'
					});

				// scroll to top of page
				document.body.scrollTop = document.documentElement.scrollTop = 0;



				} else {
					$location.path('accounts');
				}
		});
	

  	};
  	
  	// lists all accounts
  	$scope.list = function() {
  		var orderBy = $filter('orderBy');
  		$scope.limit = 50;
		$scope.offset = 0;

  		Accounts.getAllAccounts($scope.limit, $scope.offset).then(function(response) {
		   $scope.accounts = response.data;

		   // Handles array for sorting table
		   $scope.order = function(predicate, reverse) {
				$scope.accounts = orderBy($scope.accounts, predicate, reverse);
		   };

			// get all account names for search purposes
		   Accounts.getAllAccountNames().then(function(response) {
		   		$scope.allAccounts = response.data;

			    $scope.$watch('selectedAccount', function () {
				   if ($scope.selectedAccount) {
					   $location.path('/accounts/edit/' + $scope.selectedAccount.originalObject.id);
				   }
			    });

		   });
        });


		$scope.previousPage = function () {
			$scope.offset -= $scope.limit;
			Accounts.getAllAccounts($scope.limit, $scope.offset)
				.then(function(response) {
					$scope.accounts = response.data;

					// Handles array for sorting table
					$scope.order = function(predicate, reverse) {
						$scope.accounts = orderBy($scope.accounts, predicate, reverse);
					};

					// scroll to top of table
					document.getElementById('accounts-table').scrollIntoView();
				});
		};

        $scope.nextPage = function () {
			$scope.offset += $scope.limit;
			Accounts.getAllAccounts($scope.limit, $scope.offset)
				.then(function(response) {
					$scope.accounts = response.data;

					// Handles array for sorting table
					$scope.order = function(predicate, reverse) {
						$scope.accounts = orderBy($scope.accounts, predicate, reverse);
					};

					// scroll to top of table
					document.getElementById('accounts-table').scrollIntoView();

				});
		};
		
		 
       
  	};
  	
  	
  	// Populates data elements for editing an account
  	$scope.find = function() {
  		Accounts.getAccountById($routeParams.accountId)
            .then(function(response) {
               $scope.account = response.data[0];
          //     var organizationId = $scope.account.organization_id;
               var groupIds = $scope.account.group_ids;
               var subgroupIds = $scope.account.subgroup_ids;
               var regionIds = $scope.account.region_ids;
               var countryIds = $scope.account.country_ids;
               var accountTypeId = $scope.account.account_type_id;
               var mediaType = $scope.account.media_type_name;
               var languageIds = $scope.account.language_ids;
               var segmentIds = $scope.account.segment_ids;
            
               var mediaTypeId;
             
           
			   if (mediaType.indexOf('Facebook') > -1) {
					mediaTypeId = 1;
			   } else if (mediaType.indexOf('Twitter') > -1) {
					mediaTypeId = 2;
			   } else if (mediaType.indexOf('Youtube') > -1) {
				   mediaTypeId = 3;
			   }
             
           
			   // Load all data for Accounts
			   
			   // The looping that occurs in the promise below is because the API
			   // brings out the data in alphabetical order and the selected element
			   // in the Angular dropdown needs to be found. The Ids are provided in the 
			   // individual objects object (groupId, subgroupIds, etc.) 
				Accounts.getAllDataForAccounts()
					.then(function(response) {
					   $scope.allData = response.data;
			  /*
					   var organizations = $scope.allData[0];
					   organizations.shift();
					   $scope.organizations = organizations;
					   for (var i = 0; i < $scope.organizations.length; i++) {
							if ($scope.organizations[i].id == organizationId) {
								 $scope.selectedOrganization = $scope.organizations[i];
							}
					   }
				*/
					   var groups = $scope.allData[1];
					   groups.shift();
					   $scope.groups = groups;
					   var selectedGroups = [];
					   for (var i = 0; i < $scope.groups.length; i++) {
						   for (var j = 0; j < groupIds.length; j++) {
							   if ($scope.groups[i].id == groupIds[j]) {
							 	   selectedGroups.push($scope.groups[i]);
							   }
						   }
					   }
					   $scope.selectedGroups = selectedGroups;
			   			
					   var subgroups = $scope.allData[2];
					   subgroups.shift();
					   $scope.subgroups = subgroups;
					   var selectedSubgroups = [];
					   for (var i = 0; i < $scope.subgroups.length; i++) {
					   		for (var j = 0; j < subgroupIds.length; j++) {
					   			if ($scope.subgroups[i].id == subgroupIds[j]) {
					   				selectedSubgroups.push($scope.subgroups[i]);
					   			}
					   		}
					   }
					   $scope.selectedSubgroup = selectedSubgroups;

					   var regions = $scope.allData[3];
					   regions.shift();
					   $scope.regions = regions;
					   var selectedRegions = [];
					   for (var i = 0; i < $scope.regions.length; i++) {
					   		for (var j = 0; j < regionIds.length; j++) {
					   			if ($scope.regions[i].id == regionIds[j]) {
					   				selectedRegions.push($scope.regions[i]);
					   			}
					   		}
					   }
					   $scope.selectedRegion = selectedRegions;
			   
					   var accountTypes = $scope.allData[4];
					   accountTypes.shift();
					   $scope.accountTypes = accountTypes;
					   for (var i = 0; i < $scope.accountTypes.length; i++) {
							if ($scope.accountTypes[i].id == accountTypeId) {
								 $scope.selectedAccountType = $scope.accountTypes[i];
							}
					   }
			   
					   var mediaTypes = $scope.allData[5];
					   mediaTypes.shift();
					   $scope.mediaTypes = mediaTypes;
					   for (var i = 0; i < $scope.mediaTypes.length; i++) {
							if ($scope.mediaTypes[i].id == mediaTypeId) {
								 $scope.selectedMediaType = $scope.mediaTypes[i];
							}
					   }
			   
					   var countries = $scope.allData[6];
					   countries.shift();
					   $scope.countries = countries;
					   var selectedCountries = [];
					   for (var i = 0; i < $scope.countries.length; i++) {
					   		for (var j = 0; j < countryIds.length; j++) {
					   			if ($scope.countries[i].id == countryIds[j]) {
					   				selectedCountries.push($scope.countries[i]);
					   			}
					   		}
					   }
					   $scope.selectedCountry = selectedCountries;



					   var languages = $scope.allData[7];
					   languages.shift();
					   $scope.languages = languages;
					   var selectedLanguages = [];
					   for (var i = 0; i < $scope.languages.length; i++) {
						   for (var j = 0; j < languageIds.length; j++) {
							   if ($scope.languages[i].id == languageIds[j]) {
								   selectedLanguages.push($scope.languages[i]);
							   }
						   }
					   }
					   $scope.selectedLanguages = selectedLanguages;
					   
					   var segments = $scope.allData[8];
					   segments.shift();
					   $scope.segments = segments;
					   var selectedSegments = [];
					   for (var i = 0; i < $scope.segments.length; i++) {
					   		for (var j = 0; j < segmentIds.length; j++) {
					   			if ($scope.segments[i].id == segmentIds[j]) {
					   				selectedSegments.push($scope.segments[i]);
					   			}
					   		}
					   }
					   $scope.selectedSegment = selectedSegments;



						// This scope watch function handles the many to many group -> subgroup relationship
						$scope.$watch('selectedGroups', function() {
							$scope.subgroups = subgroups;
							if ($scope.selectedGroups) {
								var ids = [];
								// Loop through the selected groups
								for (var i = 0; i < $scope.selectedGroups.length; i++) {
									// If the selected item has subgroup ids
									if ($scope.selectedGroups[i].subgroup_ids) {
										for (var j = 0; j < $scope.selectedGroups[i].subgroup_ids.length; j++) {
											ids.push($scope.selectedGroups[i].subgroup_ids[j]);
										}
									}

								}

								// Place holder array for new ids
								var newIds = [];

								// if there were IDs found from the groups
								if (ids.length > 0) {
									// Loop through all the subgroups
									for (var i = 0; i < $scope.subgroups.length; i++) {
										// Now loop through all of the IDs that were accumulated from previous loop
										for (var j = 0; j < ids.length; j++) {
											// If there was an ID match
											if ($scope.subgroups[i].id === ids[j]) {
												// Push to newIds array to assign later to $scope.subgroups
												newIds.push($scope.subgroups[i]);
											}
										}

									}
									// Assign $scope.subgroups to the accumulated Ids
									$scope.subgroups = newIds;
								} else {
									// If there were no subgroup Ids for the selected group, set $scope.subgroups to empty
									if (newIds.length === 0) {
										$scope.subgroups = [];
										// Otherwise, reset $scope.subgroups to the full list of subgroups
									} else {
										$scope.subgroups = subgroups;
									}

								}
							}
						});
					   
				
				});
		
        });
        
       
  		
  	};
  	
  	$scope.update = function() {
  		var subgroups = [];
  		for (var i = 0; i < $scope.selectedSubgroup.length; i++) {
  			subgroups.push($scope.selectedSubgroup[i].id);
  		}

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

		var groups = [];
		for (var i = 0; i < this.selectedGroups.length; i++) {
			groups.push(this.selectedGroups[i].id);
		}

		var languages = [];
		for (var i = 0; i < this.selectedLanguages.length; i++) {
			languages.push(this.selectedLanguages[i].id);
		}

  		Accounts.update($routeParams.accountId, $scope.account.name, 
  		$scope.account.description, $scope.account.object_name, $scope.selectedMediaType.name,
  		groups, subgroups, languages,
  		regions, countries, $scope.selectedAccountType.id, segments)
            .then(function(response) {
               $location.path('accounts');
        });
  		
  	};
  	
  	// Populates data elements for Account creation
  	$scope.populateDataElements = function() {
		// Load all data for Accounts
		Accounts.getAllDataForAccounts().then(function(response) {
		   $scope.allData = response.data;
/*
		   var organizations = $scope.allData[0];
			organizations.shift();
		   $scope.organizations = organizations;
*/
		   var groups = $scope.allData[1];
		   groups.shift();
		   $scope.groups = groups;

		   var subgroups = $scope.allData[2];
		   subgroups.shift();
		   $scope.subgroups = subgroups;

		   var regions = $scope.allData[3];
		   regions.shift();
		   $scope.regions = regions;
		   $scope.selectedRegion = $scope.regions[0];

		   var accountTypes = $scope.allData[4];
		   accountTypes.shift();
		   $scope.accountTypes = accountTypes;
//			   $scope.selectedAccountType = $scope.accountTypes[0];

		   var mediaTypes = $scope.allData[5];
		   mediaTypes.shift();
		   $scope.mediaTypes = mediaTypes;
//			   $scope.selectedMediaType = $scope.mediaTypes[0];

		   var countries = $scope.allData[6];
		   countries.shift();
		   $scope.countries = countries;
		   $scope.selectedCountry = $scope.countries[0];

		   var languages = $scope.allData[7];
		   languages.shift();
		   $scope.languages = languages;
//			   $scope.selectedLanguage = $scope.languages[0];

		   var segments = $scope.allData[8];
		   segments.shift();
		   $scope.segments = segments;
//			   $scope.selectedSegment = $scope.segments[0];


			// This scope watch function handles the many to many group -> subgroup relationship
		   $scope.$watch('selectedGroup', function() {
			   $scope.subgroups = subgroups;
			   if ($scope.selectedGroup) {
				   var ids = [];
				   // Loop through the selected groups
				   for (var i = 0; i < $scope.selectedGroup.length; i++) {
					   // If the selected item has subgroup ids
					   if ($scope.selectedGroup[i].subgroup_ids) {
						   for (var j = 0; j < $scope.selectedGroup[i].subgroup_ids.length; j++) {
							   ids.push($scope.selectedGroup[i].subgroup_ids[j]);
						   }
					   }

				   }

				   // Place holder array for new ids
				   var newIds = [];

				   // if there were IDs found from the groups
				   if (ids.length > 0) {
					   // Loop through all the subgroups
					   for (var i = 0; i < $scope.subgroups.length; i++) {
						   // Now loop through all of the IDs that were accumulated from previous loop
						   for (var j = 0; j < ids.length; j++) {
							   // If there was an ID match
							   if ($scope.subgroups[i].id === ids[j]) {
								   // Push to newIds array to assign later to $scope.subgroups
								   newIds.push($scope.subgroups[i]);
							   }
						   }

					   }
						// Assign $scope.subgroups to the accumulated Ids
					   $scope.subgroups = newIds;
				   } else {
					   // If there were no subgroup Ids for the selected group, set $scope.subgroups to empty
					   if (newIds.length === 0) {
						   $scope.subgroups = [];
					   // Otherwise, reset $scope.subgroups to the full list of subgroups
					   } else {
						   $scope.subgroups = subgroups;
					   }

				   }
			   }
		   });
			
		});
		
  	};
  	
  	// delete (set is_active = 0) account
  	$scope.confirmDelete = function() {
  		
  		var account = $scope.accounts[$scope.accountIndex];
  		
  		Accounts.setInactive(account.id, account.name, 
  		account.description, account.object_name, account.media_type_name, 
  		account.organization_id, account.group_id, account.subgroup_ids, account.language_id, 
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
		$scope.socialMediaPlatform = accountToDelete.media_type_name;
  		
  	};

}

 