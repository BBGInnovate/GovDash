//= require jquery-1.11.1.min
//= require angular.min
//= require bootstrap-simplify.min
//= require angular-strap.min
//= require angular-route
//= require angular-resource
//= require angular-idle.min
//= require filters
//= require directives
//= require services/reportService
//= require services/sessionService
//= require services/recordService
//= require services/roleService
//= require services/organizationService
//= require services/groupService
//= require services/subgroupService
//= require services/accountService
//= require services/regionService
//= require services/countryService
//= require services/accountTypeService
//= require services/mediaTypeService
//= require services/languageService
//= require services/userService
//= require services/dateService
//= require services/segmentService
//= require services/apiService
//= require controllers/app
//= require controllers/record
//= require controllers/home
//= require controllers/users
//= require controllers/organizations
//= require controllers/groups
//= require controllers/subgroups
//= require controllers/accounts
//= require controllers/regions
//= require controllers/countries
//= require controllers/segments
//= require active_scaffold
//= require moment
//= require bootstrap-datetimepicker
//= require jquery.flot.min
//= require jquery.flot.pie.min
//= require jquery.flot.categories
//= require jquery.flot.resize
//= require rapheal.min
//= require morris.min
//= require skycons
//= require modernizr.min
//= require countUp.min
//= require jquery.noty.packaged.min
//= require angucomplete-alt.min
//= require simplify
//= require main


angular.module('radd', ['sessionService','recordService', 'roleService', 'regionService',
	'countryService', 'organizationService', 'groupService', 'subgroupService', 'accountService',
	'accountTypeService', 'mediaTypeService', 'languageService', 'reportService', 'userService',
	'dateService', 'apiService', 'apiQueryService', 'segmentService', '$strap.directives', 'directives', 'filters', 'ngRoute', 'angucomplete-alt', 'ngIdle'])


	.config(['$httpProvider', function($httpProvider){
		$httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content');

		var interceptor = ['$location', '$rootScope', '$q', function($location, $rootScope, $q) {
			function success(response) {
				return response
			};

			// this function for unauthorized
			function error(response) {
				if (response.status == 401) {
					$rootScope.$broadcast('event:unauthorized');
					$location.path('/users/login');
					return response;
				};
				return $q.reject(response);
			};

			return function(promise) {
				return promise.then(success, error);
			};
		}];
		$httpProvider.responseInterceptors.push(interceptor);

	}])
	.config(['$routeProvider', function($routeProvider){
		$routeProvider
			// .when('/', {templateUrl:'/record/index.html', controller:RecordCtrl})
			.when('/', {templateUrl:'/home/index.html', controller:HomeCtrl})
			.when('/record', {templateUrl:'/record/index.html', controller:RecordCtrl})
			.when('/users/login', {templateUrl:'/users/login.html', controller:UsersCtrl})
			.when('/users/forgotpassword', {templateUrl:'/users/forgotpassword.html', controller:UsersCtrl})
			.when('/users/register', {templateUrl:'/users/register.html', controller:UsersCtrl})
			.when('/config', {templateUrl:'/config/index.html'})
			.when('/config/resetpassword', {templateUrl:'/config/resetpassword.html', controller:UsersCtrl})
			.when('/organizations/create/', {templateUrl:'/organizations/create.html', controller:OrganizationsCtrl})
			.when('/organizations', {templateUrl:'/organizations/list.html', controller:OrganizationsCtrl})
			.when('/organizations/edit/:organizationId', {templateUrl:'/organizations/edit.html', controller:OrganizationsCtrl})
			.when('/groups/create/', {templateUrl:'/groups/create.html', controller:GroupsCtrl})
			.when('/groups', {templateUrl:'/groups/list.html', controller:GroupsCtrl})
			.when('/groups/edit/:groupId', {templateUrl:'/groups/edit.html', controller:GroupsCtrl})
			.when('/subgroups/create/', {templateUrl:'/subgroups/create.html', controller:SubgroupsCtrl})
			.when('/subgroups', {templateUrl:'/subgroups/list.html', controller:SubgroupsCtrl})
			.when('/subgroups/edit/:subgroupId', {templateUrl:'/subgroups/edit.html', controller:SubgroupsCtrl})
			.when('/accounts', {templateUrl:'/accounts/list.html', controller:AccountsCtrl})
			.when('/accounts/create/', {templateUrl:'/accounts/create.html', controller:AccountsCtrl})
			.when('/accounts/edit/:accountId', {templateUrl:'/accounts/edit.html', controller:AccountsCtrl})
			.when('/regions/create/', {templateUrl:'/regions/create.html', controller:RegionsCtrl})
			.when('/regions', {templateUrl:'/regions/list.html', controller:RegionsCtrl})
			.when('/regions/edit/:regionId', {templateUrl:'/regions/edit.html', controller:RegionsCtrl})
			.when('/countries/create/', {templateUrl:'/countries/create.html', controller:CountriesCtrl})
			.when('/countries', {templateUrl:'/countries/list.html', controller:CountriesCtrl})
			.when('/countries/edit/:countryId', {templateUrl:'/countries/edit.html', controller:CountriesCtrl})
			.when('/segments/create/', {templateUrl:'/segments/create.html', controller:SegmentsCtrl})
			.when('/segments', {templateUrl:'/segments/list.html', controller:SegmentsCtrl})
			.when('/segments/edit/:segmentId', {templateUrl:'/segments/edit.html', controller:SegmentsCtrl})
			.when('/users', {templateUrl:'/users/list.html', controller:UsersCtrl})
			.when('/users/edit/:userId', {templateUrl:'/users/edit.html', controller:UsersCtrl})
			.when('/faq', {templateUrl:'/home/faq.html'})
			.when('/welcome', {templateUrl:'/home/welcome.html'})
		;
	}])

	.config(['KeepaliveProvider', 'IdleProvider', function(KeepaliveProvider, IdleProvider) {
		IdleProvider.idle(1500);
		IdleProvider.timeout(60);
		KeepaliveProvider.interval(10);
	}])

	// register listener to watch for route changes
	.run(function ($rootScope, $location, Session, $timeout, Idle) {
	//	commented out for now
	//	Idle.watch();

		$rootScope.headerRedirect = '';

		// watch loggedInUser and control headerRedirect which is the header logo's redirect anchor reference
		// used in angular.html.erb file
		$rootScope.$watch('loggedInUser', function () {
			if ($rootScope.loggedInUser === true) {
				$rootScope.headerRedirect = '#';
			} else {
				$rootScope.headerRedirect = '#/users/login'
			}
		});

		// capture the user's original path in the event they are trying to access a
		// page where a user needs to be authenticated
		$rootScope.$on('$locationChangeStart',function(evt, absNewUrl, absOldUrl) {
			if (absOldUrl.indexOf('login') === -1) {
				$rootScope.origPath = absOldUrl;


			}
/*

			//setInterval(function () {
				var sessionAlert = confirm('Your session will timeout in 5 minutes. Press OK to renew your session or cancel to logout');
				if (sessionAlert == true) {
					alert('Your session is renewed!');
				} else {

					$('a:contains("Logout")')[2].click();
					$('.modal-backdrop').hide();


				}
			//}, 5000);
			*/

		});


		// if they are trying to access a page other than register page, check authentication
		if ($location.$$path.indexOf('register') === -1 && $location.$$path.indexOf('login') === -1 && $location.$$path.indexOf('forgotpassword') === -1) {

			// call back-end to check session
			Session.checkUserLoggedIn()
				.then(function (response) {
					// if no session was found, redirect user to login screen and reset all
					// $rootScope angular parameters related to an authenticated user
					if (response.info == null) {
						$location.path("/users/login");
						$rootScope.loggedInUser = false;
						$rootScope.email = null;
						$rootScope.user = null;

					// if the user was found, set the $rootScope parameters for the views
					// to accomodate accordingly
					} else if (response.info == 'Logged in') {
						$rootScope.loggedInUser = true;
						$rootScope.email = response.user.email;
						$rootScope.isAdmin = response.user['is_admin'];
						$rootScope.user = response.user;
					} else if (response.info == 'Logged in with temporary password') {
						$rootScope.loggedInUser = true;
						$rootScope.email = response.user.email;
						$rootScope.isAdmin = response.user['is_admin'];
						$rootScope.user = response.user;
						$location.path("/config/resetpassword");
					}

					// if a user with subrole_id 2 (viewer) is trying to go to config page, redirect
					// them to home
					if ($location.path().indexOf('config') > -1 && $rootScope.user.subrole_id === 2) {
						$location.path("/");
					}


					// this event will fire every time the route changes
					$rootScope.$on("$routeChangeStart", function (event, next, current) {

						if (!$rootScope.loggedInUser) {
							// no logged user, we should be going to the login route
							if (next.templateUrl === "/users/login.html" || next.templateUrl === "/users/register.html" || next.templateUrl === "/users/forgotpassword.html") {
								// don't redirect anon users on the login or register routes
							} else {
								// redirect all dashboard routes to login
								$location.path("/users/login");
							}

						}

						// Only ADMIN users can access user based pages
						if (next.templateUrl) {
							if (next.templateUrl.indexOf('/users/') > -1 &&
								next.templateUrl != "/users/login.html" && next.templateUrl != "/users/register.html" && next.templateUrl != "/users/forgotpassword.html" && $rootScope.isAdmin === false) {
								$location.path("/config");


							// if a subrole_id of 2 (viewer only) tries to access any page other than home, redirect them
							// to home page
							} else if (next.templateUrl !== '/home/index.html' && next.templateUrl !== '/home/faq.html' && $rootScope.user && $rootScope.user.subrole_id === 2) {
								$location.path('/');

							}
						}

					});

			});
		}

		$rootScope.events = [];

		$rootScope.$on('IdleStart', function() {
			// the user appears to have gone idle
		});

		$rootScope.$on('IdleWarn', function(e, countdown) {
			// follows after the IdleStart event, but includes a countdown until the user is considered timed out
			// the countdown arg is the number of seconds remaining until then.
			// you can change the title or display a warning dialog from here.
			// you can let them resume their session by calling Idle.watch()

			$('#timing-out').modal('show');
			$rootScope.countdown = countdown;

		});

		$rootScope.$on('IdleTimeout', function() {
			// the user has timed out (meaning idleDuration + timeout has passed without any activity)
			// this is where you'd log them

			$('#timing-out').modal('hide');
			$('#largeModal').modal('hide');
			setTimeout(function () {
				$('a:contains("Logout")')[2].click();
			}, 1000)

		});

		$rootScope.$on('IdleEnd', function() {
			// the user has come back from AFK and is doing stuff. if you are warning them, you can use this to hide the dialog
			$('#timing-out').modal('hide');
		});

		$rootScope.$on('Keepalive', function() {
			// do something to keep the user's session alive
/*
			// call back-end to check session
			Session.checkUserLoggedIn()
				.then(function (response) {
					console.log(response);
				});
				*/
		});



	});


  
  
  
  
  
  
