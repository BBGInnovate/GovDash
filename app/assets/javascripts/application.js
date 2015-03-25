//= require jquery-1.11.1.min
//= require angular.min
//= require bootstrap-simplify.min
//= require angular-strap.min
//= require angular-route
//= require angular-resource
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
//= require jquery.flot.categories
//= require jquery.flot.resize
//= require rapheal.min
//= require morris.min
//= require skycons
//= require modernizr.min
//= require countUp.min
//= require simplify
//= require main


angular.module('radd', ['sessionService','recordService', 'roleService', 'regionService',
	'countryService', 'organizationService', 'groupService', 'subgroupService', 'accountService',
	'accountTypeService', 'mediaTypeService', 'languageService', 'reportService', 'userService',
	'dateService', 'apiService', 'apiQueryService', 'segmentService', '$strap.directives', 'directives', 'filters', 'ngRoute'])


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
			.when('/users/register', {templateUrl:'/users/register.html', controller:UsersCtrl})
			.when('/config', {templateUrl:'/config/index.html'})
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
			.when('/users/edit/:userId', {templateUrl:'/users/edit.html', controller:UsersCtrl});
	}])

	// register listener to watch for route changes
	.run(function ($rootScope, $location, Session, $timeout) {
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

		Session.checkUserLoggedIn()
			.then(function(response) {
				if (response.info == null) {
					$location.path("/users/login");
					$rootScope.loggedInUser = false;
					$rootScope.email = null;
				} else if (response.info == 'Logged in') {
					$rootScope.loggedInUser = true;
					$rootScope.email = response.user.email;
				}

				// this event will fire every time the route changes
				$rootScope.$on("$routeChangeStart", function (event, next, current) {

					if (!$rootScope.loggedInUser) {
						// no logged user, we should be going to the login route
						if (next.templateUrl === "/users/login.html" || next.templateUrl === "/users/register.html") {
							// don't redirect anon users on the login or register routes
						} else {
							// redirect all dashboard routes to login
							$location.path("/users/login");
						}

					}

					// Only ADMIN users can access user based pages
					if (next.templateUrl) {
						if (next.templateUrl.indexOf('/users/') > -1 &&
							next.templateUrl != "/users/login.html" && next.templateUrl != "/users/register.html" && $rootScope.userRole != 'Administrator') {
							$location.path("/config");
						}
					}

				});

			});


	});


  
  
  
  
  
  
