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
					//Flot Chart SparkLine
					var d1 = $parse(attrs.data)(scope);

					if (d1 && d1.length > 0) {
						var data = [];

						// Process Spark Chart Data
						for (var i = 0; i < d1.length; i++) {
							var dateFormatted = '';

							// if there is a date present, format it as a single date
							if (d1[i].date) {
								dateFormatted = d1[i].date.substring(5, 10).replace('-', '/');

							// this condition is met when there is a period of dates (03-01-2015 - 03-30-2015)
							// this only happens when the user requests a date range greater than 27 days
							} else {
								dateFormatted = d1[i].period.substring(5,10).replace('-', '/') + ' - ' + '<br>' + d1[i].period.substring(18,23).replace('-', '/');
							}

							var num = d1[i].totals;

							// if the data number is less than 0, set it to 0
							// to avoid negative number explanation in the chart
							if (num < 0) {
								num = 0;
							}
							data.push([dateFormatted, num]);
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
								var date = item.series.data[x][0];
								$("#tooltip").html("Interactions on " + date + ": " + y)
									.css({top: item.pageY + 5, left: item.pageX + 5})
									.fadeIn(350);
							} else {
								$("#tooltip").hide();
							}
						});

						// If there are too many data points, hide the x-axis
						// the tooltip will suffice
						setTimeout(function () {
							if (data.length > 12) {
								$('.flot-x-axis').hide();
							} else {
								$('.flot-x-axis').show();
							}
						}, 100);


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

					if (data && data.totalInteractions !== 0) {
						element.empty();



						var dataArr = [];
						var yKeys = [];
						var labels = [];
						var barColors = [];

						// If it's an array being passed through (SiteCatalyst Trend Data)
						if (data.length !== undefined) {
							for (var i = 0; i < data.length; i++) {
								var dateString = '';

								// if this is a period based date (03-01-2015 - 03-30-2015)
								if (data[i].period) {
									dateString = data[i].period.substring(5,10).replace('-', '/') + ' - ' + data[i].period.substring(18,23).replace('-', '/');

								// standard date (03-25-2015)
								} else {
									dateString = moment(data[i].date, 'YYYY-MM-DD').format('MM/DD/YYYY').slice(0,-5)
								}

								dataArr.push({ y: dateString, a: data[i].facebook_count, b: data[i].twitter_count });
							}
							yKeys = ['a', 'b'];
							labels = ['Facebook', 'Twitter'];
							barColors = ['#3278B3', '#23B7E5'];

						// Otherwise normal bar chart
						} else {
							// Chart with YouTube
							if (data.youtubeInteractions || data.youtubeInteractions === 0) {
								dataArr = [{
									y: 'Total Interactions',
									a: data.fbInteractions,
									b: data.twInteractions,
									c: data.youtubeInteractions
								}];

								yKeys = ['a', 'b', 'c'];
								labels = ['Facebook', 'Twitter', 'YouTube'];
								barColors = ['#3278B3', '#23B7E5', '#E36159'];

								isMainChart = true;

							// chart without youtube
							} else {
								dataArr = [{
									y: 'Total Interactions',
									a: data.fbInteractions,
									b: data.twInteractions
								}];

								yKeys = ['a', 'b'];
								labels = ['Facebook', 'Twitter'];
								barColors = ['#3278B3', '#23B7E5'];
							}

							$(window).resize(function() {
								window.m.redraw();

								setTimeout(function () {
									addLabels(dataArr);
								}, 500);


							});
						}




						window.m = Morris.Bar({
							// ID of the element in which to draw the chart.
							element: element,
							// Chart data records -- each entry in this array corresponds to a point on
							// the chart.
							data: dataArr,
							xkey: 'y',
							ykeys: yKeys,
							labels: labels,
							barColors: barColors,
							resize: true,
							redraw: true,
							horizontal: true,
							hideHover: 'always'
						});


						addLabels(dataArr);


					} else {
						element.html('<p class="no-data-found">No data found</p>');
					}

				});

				function addLabels(dataArr) {

					if (dataArr[0].a && dataArr[0].b && dataArr[0].c) {
						// if labels exist, empty those first
						$('.morris-bars-custom-labels').empty();

						var totalInteractions = dataArr[0].a + dataArr[0].b + dataArr[0].c;
						var fbPercentage = Math.round((dataArr[0].a / totalInteractions) * 100) + '%';
						var twPercentage = Math.round((dataArr[0].b / totalInteractions) * 100) + '%';
						var ytPercentage = Math.round((dataArr[0].c / totalInteractions) * 100) + '%';

						var xPosOne = ($('rect')[0].width.baseVal.value + $('rect')[0].x.baseVal.value) + 10;
						var xPosTwo = ($('rect')[1].width.baseVal.value + $('rect')[1].x.baseVal.value) + 10;
						var xPosThree = ($('rect')[2].width.baseVal.value + $('rect')[2].x.baseVal.value) + 10;
						var fbValue = dataArr[0].a.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") + ' (' + fbPercentage + ')';
						var twValue = dataArr[0].b.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") + ' (' + twPercentage + ')';
						var ytValue = dataArr[0].c.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",") + ' (' + ytPercentage + ')';
						$('rect')[0].outerHTML += '<svg class="morris-bars-custom-labels" x="' + xPosOne + '" y="55.375" height="30" width="200"><text x="0" y="15" fill="#3278B3">' + fbValue + '</text></svg>';
						$('rect')[1].outerHTML += '<svg class="morris-bars-custom-labels" x="' + xPosTwo + '" y="97.375" height="30" width="200"><text x="0" y="15" fill="#23B7E5">' + twValue + '</text></svg>';
						$('rect')[2].outerHTML += '<svg class="morris-bars-custom-labels" x="' + xPosThree + '" y="141.375" height="30" width="200"><text x="0" y="15" fill="#E36159">' + ytValue + '</text></svg>';
					}



				}

			}
		};
	}])
	.directive('pieChart', ['$parse', '$filter', function($parse, $filter) {
		return {
			link: function(scope, element, attrs) {

				scope.$watch(attrs.data, function (newval, oldval) {

					var data = $parse(attrs.data)(scope);

					if (data && data.length === undefined) {
						element.empty();

						// Get the colors and labels from the angular filters function
						// for the proper socialmediatype (facebook, twitter, youtube)
						var colors = $filter('socialMediaColors')(attrs.socialmediatype);
						var labels = $filter('socialMediaLabels')(attrs.socialmediatype);

						// If it's a modal, use the setTimeout to give the chart time to load
						// on the modal
						if (attrs.modal) {
							// Set Timeout for bootstrap modal
							setTimeout(function () {
								buildChart(element, data, labels, colors, attrs.socialmediatype);
							}, 400);

						// This is for initial filter selection load
						} else {
							buildChart(element, data, labels, colors, attrs.socialmediatype);
						}

						/*
						// remove pie chart data not found message if exists
						$('.pie-chart-data').remove();
						*/

					} else {
						element.html('<p class="no-data-found">No data found</p>');
					}

				});

				function buildChart(element, data, labels, colors, socialMediaType) {

					var dataArray = [
						{label: $filter('labelFormat')(labels[0]), value: data[labels[0]]},
						{label: $filter('labelFormat')(labels[1]), value: data[labels[1]]},
						{label: $filter('labelFormat')(labels[2]), value: data[labels[2]]},
						{label: $filter('labelFormat')(labels[3]), value: data[labels[3]]}
					];

					// if it's YouTube, remove last element since YouTube only has 3 engagement actions
					if (socialMediaType === 'yt') {
						dataArray.splice(3, 1);
					}

					// Build out Donut Chart
					Morris.Donut({
						element: element,
						data: dataArray,
						formatter: function (y, value) {
							var percentage = Math.round((value.value / data.totals) * 100);

							// add commas to number
							var num = y.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
							return num + '   ('+percentage+'%)';
						},
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
	}])
	.directive('flotPieChart', ['$parse', function($parse) {
		return {
			link: function(scope, element, attrs) {


				var data = $parse(attrs.data)(scope);

				if (data && data.totalInteractions !== 0) {
					element.empty();

					$(window).resize(function () {
						window.m.redraw();
					});




					var dataArr = [
						{label: "Facebook", data: data.fbInteractions, color: '#3278B3' },
						{label: "Twitter", data: data.twInteractions, color: '#23B7E5' },
						{label: "YouTube", data: data.youtubeInteractions, color: '#E36159' }
					];



					$.plot(element, dataArr, {
						series: {
							pie: {
								show: true
							}
						},
						legend: {
							show: false
						}
					});


				} else {
					element.html('<p class="no-data-found">No data found</p>');
				}

			}






		};
	}])
	// Show the filter selection modal
		.directive('exportCsv', [function () {
			return {
				link: function ($scope, element, attrs) {
					element.bind('click', function () {
					//	console.log(attrs);
					//	var data = [["Name Actions Followers Favorites Retweets Mentions"], ["voalearningenglish 434 434 0 0 0"]];
					//	console.log(data);

						// this is a special javascript function to mimic a space character
						// this is needed because this CSV breaks on traditional space characters
						var spaceChar = ' ';

						var filterCriteria = '';
						$('.page-sub-header span').each(function() {
							filterCriteria += $(this).text() + ' | ' + spaceChar;
						});

						// remove extra comma
						filterCriteria = filterCriteria.substring(0, filterCriteria.length - 2);
						

						var i = 0;
						var dataArr = [];
						var dataString = '';
						var csvContent = "data:text/csv;charset=utf-8,";

						csvContent += 'Included' + spaceChar + 'filters: | ' + filterCriteria;

						// Loop through each table and structure the stringified row
						// into an array
						$('.table tr').each(function() {
							var text = $(this).text().trim().replace('Data Since:', '');

							// replace spaces with special space character to work in CSV
							text = text.replace(/ /g, spaceChar).replace(/,/g , '');


							text = text.replace('Name', 'Name,Data' + spaceChar + 'Since');

							// Replace header characters
							if (i === 0) {
								//text = text.replace('Name', 'Name Data' + spaceChar + 'Since');
								text = text.replace('New Fans', 'New' + spaceChar + 'Fans');
								text = text.replace('Story Likes', 'Story' + spaceChar + 'Likes');

								text = text.replace('New Followers', 'New' + spaceChar + 'Followers');

								text = text.replace('Video Likes', 'Video' + spaceChar + 'Likes');
								text = text.replace('New Subscribers', 'New' + spaceChar + 'Subscribers');
							}


							// insert commas to separate values
							var rowData = text.replace(/\s\s+/g, ',');

							var rowDataArr = [rowData];
						//	console.log(i+ ' | ' + rowData);
							dataArr.push(rowDataArr);

							i++;
						});

						dataArr.forEach(function(infoArray, index){

							dataString = infoArray.join(",");

							// start of a new social media platform account list
							if (infoArray[0].indexOf('Name') > -1) {

								var socialMediaPlatform = '';
								if (infoArray[0].indexOf('Fans') > -1) {
									socialMediaPlatform = 'Facebook';
								} else if (infoArray[0].indexOf('Followers') > -1) {
									socialMediaPlatform = 'Twitter';
								} else if (infoArray[0].indexOf('Video') > -1) {
										socialMediaPlatform = 'YouTube';
								}

								csvContent += "\n" + "\n" + [socialMediaPlatform] + "\n" + "\n";
							}

							csvContent += index <= i ? dataString+ "\n" : dataString;



						});



						//Then you can use JavaScript's window.open and encodeURI functions to download the CSV file like so:

					//	var encodedUri = encodeURI(csvContent);
					//	window.open(encodedUri);

						//Edit:
						//	If you want to give your file a specific name, you have to do things a little differently
						// since this is not supported accessing a data URI using the window.open method.
						// In order to achieve this, you can create a hidden <a> DOM node and set its download
						// attribute as follows:

						var d = new Date();
						var todayDate = d.getMonth()+1 + '-' + d.getDate() + '-' + (d.getYear() + 1900);

						var encodedUri = encodeURI(csvContent);
						var link = document.getElementById('export-data');
						link.setAttribute("href", encodedUri);
						link.setAttribute("download", "BBGDashReport_"+todayDate+".csv");

						//link.click(); // This will download the data file named "my_data.csv".
					});
				}
			};
	}]);

