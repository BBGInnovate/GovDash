$(document).ready(function() {
	$('#modal-wizard').modal('show');

	// don't route when clicking on tabs
	$('.wizard-tabs').click(function(event) {
	   event.preventDefault();
	});

	
	$('#tabsleft').bootstrapWizard({'tabClass': 'nav nav-tabs', 'debug': false, onShow: function(tab, navigation, index) {
		//	console.log('onShow');
		}, onNext: function(tab, navigation, index) {
		//	console.log('onNext');
		}, onPrevious: function(tab, navigation, index) {
		//	console.log('onPrevious');
		}, onLast: function(tab, navigation, index) {
		//	console.log('onLast');
		}, onTabClick: function(tab, navigation, index) {
		//	console.log('onTabClick');
		
		}, onTabShow: function(tab, navigation, index) {
		//	console.log('onTabShow');
			// Show the finish here button on every page but welcome page
			if (index > 0) {
				$('.finish-here').show();
			} else {
				$('.finish-here').hide();
			}
		
				
			var $total = navigation.find('li').length;
			var $current = index+1;
			var $percent = (($current/($total)) * 100) - 25;
			$('#tabsleft').find('.bar').css({width:$percent+'%'});
		
			// If it's the last tab then hide the last button and show the finish instead
			if($current >= $total) {
				$('#tabsleft').find('.pager .next').hide();
				$('.finish-here').hide();
				$('#tabsleft').find('.pager .finish').show();
				$('#tabsleft').find('.pager .finish').removeClass('disabled');
			} else {
				$('#tabsleft').find('.pager .next').show();
				$('#tabsleft').find('.pager .finish').hide();
			}
			
			// If on the Results page, hide finish button
			if (index == 3) {
				$('#tabsleft').find('.pager .next').hide();
				$('.finish-here').hide();
				$('.finish').show();
				
			
			} 
			
			// If on the Results page, hide finish button
			if (index == 4) {
				$('.finish').hide();
				$('.bar').css('width', '100%');
			} 
		
	  }});
	  
	// user clicks region link
	$('#location-item').click(function(event) {
	   event.preventDefault();
	   $('#tabsleft').bootstrapWizard('show', 1);
	});  
	// user clicks language link
	$('#language-item').click(function(event) {
	   event.preventDefault();
	   $('#tabsleft').bootstrapWizard('show', 2);
	});  
	
	// user clicks region link
	$('#entity-item').click(function(event) {
	   event.preventDefault();
	   $('#tabsleft').bootstrapWizard('show', 3);
	});  
	  
	// user clicks wizard link
	$('#wizard-item').click(function(event) {
		event.preventDefault();
	   $('#tabsleft').bootstrapWizard('next');
	});
	
	// user clicks finish here
	$('#finish-here').click(function(event) {
		event.preventDefault();
	   $('#tabsleft').bootstrapWizard('show', 4);
	});
	
	$('.finish-here').hide();
	
			
			
});