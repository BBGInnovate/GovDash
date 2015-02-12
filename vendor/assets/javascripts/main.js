var network = {
  init : function() {
      $("#submit").click(function() {
        var url = $('form[action]').attr('action');
        $('input[name="authenticity_token"]').remove();
        var data = $('form["id"]').serialize();
        var m = $('form[method]').attr('method');
        if ( m == 'post') {
          $.post(url, data, network.done);
        } else {
        	 $.put(url, data, network.done);
        }
        return false;
      });
  },
  done : function(resp){
      var obj = jQuery.parseJSON(resp);
      $('#notice').html(obj.error);
  }
}

var retrieve = {
  init : function() {
  	    var input="a[id^='as_admin__accounts-fetch-'],a[id^='as_admin__error_logs-fetch-']"; 
      $(input).on('click', function() {
      	  var str = 'It may take a few minutes to run. Continue?';
      	  if (!confirm(str))
      	    return false;

         var url = $(this).attr('href');
         myid = this;
         $(myid).css('cursor','wait');
         $.get(url, {}, function(data) {
            $('#fetch').remove();
            var obj = jQuery.parseJSON(data);
            $(".active-scaffold-header").append(obj.text);
            if (obj.status==1) {
              klass = "green-light";
              img = "green.png";
            } else {
              klass = "red-ligh"
              img = "red.png"
            }
            $('#red-green_'+obj.id).attr({"class":klass, "src":"/assets/"+img });
            $(myid).css('cursor','pointer');
            $("html, body").animate({ scrollTop: 0 }, "slow");
            $('#fetch').fadeOut(8000);
            // location.reload();
            if (('row' in obj) && myid.id.match(/as_admin__error_logs/)) {
              $("#as_admin__error_logs-tbody").prepend(obj.row);
            }
         });
         blinkeffect('img.red-light');
         return false;
      });
  }, 
}

function blinkeffect(selector) {
        $(selector).fadeOut('slow', function() {
                $(this).fadeIn('slow', function() {
                        blinkeffect(this);
                });
        });
}

