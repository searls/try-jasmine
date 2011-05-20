(function($){
	jasmine.getEnv().addReporter(new jasmine.TrivialReporter());
	$('.try-it.button').live('click',function(e) {
	  jasmine.getEnv().execute();
	});
})(jQuery);