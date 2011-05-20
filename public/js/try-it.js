(function($){
	//Define the little iframe sandbox
	window.Sandbox = function(){
		var self = $('#sandbox').get(0).contentWindow;
		
		self.runSpecs = function() {
			self.jasmine.getEnv().addReporter(new self.jasmine.TrivialReporter());
			self.eval($('#specs').val());
			self.eval($('#src').val());				
			self.jasmine.getEnv().execute();
		}
		self.kill = function() {
			$('#sandbox').get(0).src = $('#sandbox').attr('src');
			self = $('#sandbox').get(0).contentWindow;
		};		
		return self;		
	};
	
	//Populate default templates
	$(function(){
		$('#specs').val($.trim($('#default-specs').html()));
		$('#src').val($.trim($('#default-src').html()));
	});
	
	window.tryIt = function() {
		var sandbox = Sandbox();	
		sandbox.runSpecs();
		sandbox.kill();
		$('.spec-runner').html($('body > .jasmine_reporter'));
	};
	
	
	//Eventy stuff
	$('.try-it.button').live('click',function(e){
		e.preventDefault();
		tryIt();
	});
	$('body').live('keypress',function(e){
		if(e.metaKey === true && e.keyCode === 13) {
			//^ if you hit ctrl+Enter or cmd+Enter
			e.preventDefault();
			tryIt();
		}
	});
	$('.source').live('keydown',function(e) {
		if(e.keyCode === 9) { //TAB			
			e.preventDefault();
			if(e.shiftKey !== true) {
				$(this).insertAtCaret('  ');	
			}
		}
	});
	$('.button.insert').live('click',function(e) {
		e.preventDefault();
		$('#specs').insertAtCaret($(this).data('snippet')).focus();
		
	});
	
})(jQuery);