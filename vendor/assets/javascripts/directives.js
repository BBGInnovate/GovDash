/**
 * Directives
 */

// Directive for opening modals
angular.module('directives', []).
  directive(['opendialog', function() {
      var openDialog = {
         link :   function(scope, element, attrs) {
            function openDialog() {
              var element = angular.element('#myModal');
              var ctrl = element.controller();
              ctrl.setModel(scope.blub);
              element.modal('show');
            }
            element.bind('click', openDialog);
       }
   }
   	  return openDialog;
   }])
   
   // This directive handles the password matching when admin is changing users password
   .directive('passwordMatch', [function () {
		return {
			restrict: 'A',
			scope:true,
			require: 'ngModel',
			link: function (scope, elem , attrs,control) {
				var checker = function () {
 
					//get the value of the first password
					var e1 = scope.$eval(attrs.ngModel);
 
					//get the value of the other password 
					var e2 = scope.$eval(attrs.passwordMatch);
					return e1 == e2;
				};
				scope.$watch(checker, function (n) {
 
					//set the form control to valid if both
					//passwords are the same, else invalid
					control.$setValidity("unique", n);
				});
			}
		};
	}])
	
	.directive('myModal', [function () {
		return {
			 restrict: 'A',
			 link: function(scope, element, attr) {
			   scope.modal = function(toggle) {
				   element.modal(toggle);
			   };
			 }
		} 
	}])
	
	// This directive handles the 'Back' button the view
	.directive('backButton', [function () {
		return {
			restrict: 'A',

			  link: function(scope, element, attrs) {
				element.bind('click', goBack);

				function goBack() {
				  history.back();
				  scope.$apply();
				}
			  }
		};
	}]);
