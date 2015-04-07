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
				element.addClass('back-button');
				element.addClass('label label-primary');

				function goBack() {
					history.back();
					scope.$apply();
				}
			}
		};
	}])
	.directive('sparkChart', ['$parse', '$filter', function($parse, $filter) {
		return {
			link: function(scope, element, attrs) {

				scope.$watch(attrs.data, function (newval, oldval) {
					//Flot Chart (Total Sales)
					var d1 = $parse(attrs.data)(scope);

					if (d1 && d1.length > 0) {
						var data = [];

						// Process Spark Chart Data
						for (var i = 0; i < d1.length; i++) {
							var dateFormatted = d1[i].date.substring(5, 10).replace('-', '/');
							data.push([dateFormatted, d1[i].totals]);
						}

						var colors = $filter('socialMediaColors')(attrs.socialmediatype);

						function plotWithOptions() {
							$.plot(element, [data], {
								series: {
									lines: {
										show: true,
										fill: true,
									//	fillColor: attrs.shadecolor,
										fillColor: colors[3],
										steps: false

									},
									points: {
										show: true,
										fill: false
									}
								},
								xaxis: {
									mode: "categories",
									tickLength: 0
								},
								grid: {
									color: '#fff',
									hoverable: true,
									autoHighlight: true
								},
								//colors: [attrs.pointcolor]
								colors: [colors[1]]
							});


						}

						$("<div id='tooltip'></div>").css({
							position: "absolute",
							display: "none",
							border: "1px solid #222",
							padding: "4px",
							color: "#fff",
							"border-radius": "4px",
							"background-color": "rgb(0,0,0)",
							opacity: 0.80
						}).appendTo("body");

						element.bind("plothover", function (event, pos, item) {

							var str = "(" + pos.x.toFixed(2) + ", " + pos.y.toFixed(2) + ")";
							$("#hoverdata").text(str);

							if (item) {
								var x = item.datapoint[0],
									y = item.datapoint[1];

								$("#tooltip").html("Interactions : " + y)
									.css({top: item.pageY + 5, left: item.pageX + 5})
									.fadeIn(350);
							} else {
								$("#tooltip").hide();
							}
						});

						plotWithOptions();
					} else {
						element.html('<p class="no-data-found">No data found</p>');
					}

				});


			}
		};
	}])
	.directive('barChart', ['$parse', function($parse) {
		return {
			link: function(scope, element, attrs) {

				scope.$watch(attrs.data, function (newval, oldval) {

					var data = $parse(attrs.data)(scope);

					if (data) {
						element.empty();

						$(window).resize(function() {
							window.m.redraw();
						});

						window.m = Morris.Bar({
							// ID of the element in which to draw the chart.
							element: element,
							// Chart data records -- each entry in this array corresponds to a point on
							// the chart.
							data: [{ y: 'Total Interactions',
								a: data.totalInteractions,
								b: data.fbInteractions,
								c: data.twInteractions,
								d: data.youtubeInteractions }],
							xkey: 'y',
							ykeys: ['a', 'b', 'c', 'd'],
							labels: ['All', 'Facebook', 'Twitter', 'YouTube'],
							barColors: ['#2BAAB1', '#3278B3', '#23B7E5', '#E36159'],
							resize: true,
							redraw: true
						});
					} else {
						element.html('<p class="no-data-found">No data found</p>');
					}

				});

			}
		};
	}])
	.directive('pieChart', ['$parse', '$filter', function($parse, $filter) {
		return {
			link: function(scope, element, attrs) {

				scope.$watch(attrs.data, function (newval, oldval) {

					var data = $parse(attrs.data)(scope);

					if (data && data.length === undefined) {
						// Get the colors and labels from the angular filters function
						// for the proper socialmediatype (facebook, twitter, youtube)
						var colors = $filter('socialMediaColors')(attrs.socialmediatype);
						var labels = $filter('socialMediaLabels')(attrs.socialmediatype);

						// If it's a modal, use the setTimeout to give the chart time to load
						// on the modal
						if (attrs.modal) {
							// Set Timeout for bootstrap modal
							setTimeout(function () {
								buildChart(element, data, labels, colors);
							}, 400);

						// This is for initial filter selection load
						} else {
							buildChart(element, data, labels, colors, attrs.socialmediatype);
						}


					} else {
						element.html('<p class="no-data-found">No data found</p>');
					}

				});

				function buildChart(element, data, labels, colors, socialMediaType) {
					var dataArr = [];

					// Facebook only has 3 pieces now
					if (socialMediaType === 'fb') {
						dataArr = [
							{label: $filter('labelFormat')(labels[0]), value: data[labels[0]]},
							{label: $filter('labelFormat')(labels[1]), value: data[labels[1]]},
							{label: $filter('labelFormat')(labels[2]), value: data[labels[2]]}
						];
					} else {
						dataArr =
						[
							{label: $filter('labelFormat')(labels[0]), value: data[labels[0]]},
							{label: $filter('labelFormat')(labels[1]), value: data[labels[1]]},
							{label: $filter('labelFormat')(labels[2]), value: data[labels[2]]},
							{label: $filter('labelFormat')(labels[3]), value: data[labels[3]]}
						];
					}

					// Build out Donut Chart
					Morris.Donut({
						element: element,
						data: dataArr,
						colors: [colors[0], colors[1], colors[2], colors[3]]
					});
				}



			}
		};
	}])
	.directive('checkboxGroup', [function() {
		return {
			restrict: "A",
			link: function(scope, elem, attrs) {
				// Determine initial checked boxes
				if (scope.array.indexOf(scope.item.id) !== -1) {
					elem[0].checked = true;
				}

				// Update array on click
				elem.bind('click', function() {
					var index = scope.array.indexOf(scope.item.id);
					// Add if checked
					if (elem[0].checked) {
						if (index === -1) scope.array.push(scope.item.id);
					}
					// Remove if unchecked
					else {
						if (index !== -1) scope.array.splice(index, 1);
					}
					// Sort and update DOM display
					scope.$apply(scope.array.sort(function(a, b) {
						return a - b
					}));
				});
			}
		}
	}])
	.directive('ngEnter', [function() {
		return function(scope, element, attrs) {
			element.bind("keydown keypress", function(event) {

				if(event.which === 13) {
					scope.$apply(function(){
						scope.$eval(attrs.ngEnter, {'event': event});
					});

					event.preventDefault();
				}
			});
		};
	}])
	.directive('countUp', [function() {
		return {
			link: function(scope, element, attrs) {

				scope.$watch(element[0].id, function (newval, oldval) {
					if (attrs.value) {
						var animation = new countUp(element[0].id, 0, attrs.value, 0, 2.5);
						animation.start();
					}
				});

			}
		};
	}])
	// Show the filter selection modal
	.directive('showModal', [function () {
		return {
			link: function ($scope, element, attrs) {
				element.bind('click', function () {
					$('#largeModal').modal('show');
				});
			}
		};
	}])
	.directive("modalShow", ['$parse', function ($parse) {
		return {
			restrict: "A",
			link: function (scope, element, attrs) {

				//Hide or show the modal
				scope.showModal = function (visible, elem) {
					if (!elem)
						elem = element;

					if (visible)
						$(elem).modal("show");
					else
						$(elem).modal("hide");
				};

				//Watch for changes to the modal-visible attribute
				scope.$watch(attrs.modalShow, function (newValue, oldValue) {
					scope.showModal(newValue, attrs.$$element);
				});

				/*
				//Update the visible value when the dialog is closed through UI actions (Ok, cancel, etc.)
				$(element).bind("hide.bs.modal", function () {
					$parse(attrs.modalShow).assign(scope, false);
					if (!scope.$$phase && !scope.$root.$$phase)
						scope.$apply();
				});
				*/
			}

		};
	}])
	.directive('datePicker', [function() {
		return {
			link: function(scope, element, attrs) {

				//Date & Time Picker
				$(element).datetimepicker({
					defaultDate: attrs.date,
					pickTime: false
				});
			}
		};
	}]);

