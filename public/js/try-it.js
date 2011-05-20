(function($){
	window.Sandbox = function(){
		var self = frames[0];
		
		self.eval = function(source) {
			self.document.write(
				'<script>'+
					source +
				'<\/script>');
		};
		self.runSpecs = function() {
			self.jasmine.getEnv().addReporter(new self.jasmine.TrivialReporter());
			self.eval($('#specs').val());
			self.eval($('#src').val());				
			self.jasmine.getEnv().execute();
		}
		self.kill = function() {
			$('iframe').get(0).src = $('iframe').attr('src');
		};
		
		return self;		
	};
	
	window.tryIt = function() {
		var sandbox = Sandbox();
		sandbox.runSpecs();
		sandbox.kill();
		$('.spec-runner').html($('body > .jasmine_reporter'));		
	};
	$('.try-it.button').live('click',tryIt);
	
	$(function(){
		$('#specs').val($.trim($('#default-specs').html()));
		$('#src').val($.trim($('#default-src').html()));
	});
})(jQuery);