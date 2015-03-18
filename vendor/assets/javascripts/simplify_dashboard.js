$(function	()	{

  	//Flot Chart (Total Sales)
	var d1 = [];
	for (var i = 0; i <= 10; i += 1) {
		//d1.push([i, parseInt(Math.random() * 30)]);
		d1 = [[0,Math.floor(Math.random()*900) + 100],
			[1,Math.floor(Math.random()*900) + 100],
			[2,Math.floor(Math.random()*900) + 100],
			[3,Math.floor(Math.random()*900) + 100],
			[4,Math.floor(Math.random()*900) + 100],
			[5,Math.floor(Math.random()*900) + 100],
			[6,Math.floor(Math.random()*900) + 100],
			[7,Math.floor(Math.random()*900) + 100],
			[8,Math.floor(Math.random()*900) + 100],
			[9,Math.floor(Math.random()*900) + 100],
			[10,Math.floor(Math.random()*900) + 100]];
	}

	function plotWithOptions() {
		/*
		$.plot("#placeholder", [d1], {
			series: {
				lines: {
					show: true,
					fill: true,
					fillColor: '#eee',
					steps: false,
					
				},
				points: { 
					show: true, 
					fill: false 
				}
			},

			grid: {
				color: '#fff',
				hoverable: true,
    			autoHighlight: true,
			},
			colors: [ '#bbb'],
		});
		*/

		$.plot("#placeholder2", [d1], {
			series: {
				lines: {
					show: true,
					fill: true,
					fillColor: '#C0D2E0',
					steps: false

				},
				points: {
					show: true,
					fill: false
				}
			},

			grid: {
				color: '#fff',
				hoverable: true,
				autoHighlight: true
			},
			colors: [ '#3278B3']
		});

		$.plot("#placeholder3", [d1], {
			series: {
				lines: {
					show: true,
					fill: true,
					fillColor: '#C5E1EA',
					steps: false

				},
				points: {
					show: true,
					fill: false
				}
			},

			grid: {
				color: '#fff',
				hoverable: true,
				autoHighlight: true
			},
			colors: [ '#23B7E5']
		});


		$.plot("#placeholder4", [d1], {
			series: {
				lines: {
					show: true,
					fill: true,
					fillColor: '#E5C0BE',
					steps: false

				},
				points: {
					show: true,
					fill: false
				}
			},

			grid: {
				color: '#fff',
				hoverable: true,
				autoHighlight: true
			},
			colors: [ '#E36159']
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
		opacity: 0.90
	}).appendTo("body");

	$("#placeholder2, #placeholder3, #placeholder4").bind("plothover", function (event, pos, item) {

		var str = "(" + pos.x.toFixed(2) + ", " + pos.y.toFixed(2) + ")";
		$("#hoverdata").text(str);
	
		if (item) {
			var x = item.datapoint[0],
				y = item.datapoint[1];
			
				$("#tooltip").html("Interactions : " + y)
				.css({top: item.pageY+5, left: item.pageX+5})
				.fadeIn(200);
		} else {
			$("#tooltip").hide();
		}
	});

	plotWithOptions();

	//Morris Chart (Total Visits)
	var totalVisitChart = Morris.Bar({
	  element: 'totalSalesChart',
	  data: [
		  /*
	    { y: '2008', a: 100, b: 90 },
	    { y: '2009', a: 75,  b: 65 },
	    { y: '2010', a: 50,  b: 40 },
	    { y: '2011', a: 75,  b: 65 },
	    { y: '2012', a: 50,  b: 40 },
	    { y: '2013', a: 75,  b: 65 },
	    { y: '2014', a: 100, b: 90 }
	    */
		  { y: 'Interactions', b: 751, c: 129, d: 124}
		  /*
		  { y: 'Facebook', a: 751 },
		  { y: 'Twitter', a: 129 },
		  { y: 'YouTube', a: 124 },
		  */
	  ],
	  xkey: 'y',
	 // ykeys: ['a', 'b', 'c','d'],
	 // labels: ['Total Interactions', 'Facebook', 'Twitter', 'YouTube'],
	    ykeys: ['b', 'c','d'],
		labels: ['Facebook', 'Twitter', 'YouTube'],
	  barColors: ['#3278B3', '#23B7E5', '#E36159'],
	  grid: false,
	  gridTextColor: '#777'
	});
	

	//Datepicker
	$('#calendar').DatePicker({
		flat: true,
		date: '2014-06-07',
		current: '2014-06-07',
		calendars: 1,
		starts: 1
	});

	//Skycon
	var icons = new Skycons({"color": "white"});
    icons.set("skycon1", "sleet");
    icons.set("skycon2", "partly-cloudy-day");
    icons.set("skycon3", "wind");
    icons.set("skycon4", "clear-day");
    icons.play();

	//Scrollable Chat Widget
	$('#chatScroll').slimScroll({
		height:'230px'
	});

	//Chat notification
	setTimeout(function() {
		$('.chat-notification').find('.badge').addClass('active');
		$('.chat-alert').addClass('active');
	}, 3000);

	setTimeout(function() {
		$('.chat-alert').removeClass('active');
	}, 8000);
	
	$(window).resize(function(e)	{
		// Redraw All Chart
		setTimeout(function() {
			totalVisitChart.redraw();
			plotWithOptions();
		},500);
	});

	$('#sidebarToggleLG').click(function()	{
		// Redraw All Chart
		setTimeout(function() {
			totalVisitChart.redraw();
			plotWithOptions();
		},500);
	});

	$('#sidebarToggleSM').click(function()	{
		// Redraw All Chart
		setTimeout(function() {
			totalVisitChart.redraw();
			plotWithOptions();
		},500);
	});
});
