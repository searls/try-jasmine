(function($){
	jasmine.getEnv().addReporter(new jasmine.TrivialReporter());
	
	
	
	$('.try-it.button').live('click',function(e) {
		$('.jasmine_reporter').remove();
		
		eval($('#specs').val());
		eval($('#src').val());
		
	  jasmine.getEnv().execute();
		$('.jasmine_reporter').appendTo('#spec-runner');
	});
})(jQuery);