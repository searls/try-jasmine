var editor;

(function($){
	//Define the little iframe sandbox
	window.Sandbox = function(){
		var self = $('#sandbox').get(0).contentWindow;
		
		self.runSpecs = function() {
			self.jasmine.getEnv().addReporter(new self.jasmine.TrivialReporter());
			localStorage['specs'] = $('#specs').val();
			localStorage['src'] = $('#src').val();			
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

	window.tryIt = function() {
		var sandbox = Sandbox();	
		sandbox.runSpecs();
		sandbox.kill();
		$('.spec-runner').html($('body > .jasmine_reporter'));
	};
	
	var setUpDefaultSpecs = function() {
		var specs = $.trim($('#default-specs').html()),
				src = $.trim($('#default-src').html());
		if((localStorage['specs'] && specs !== localStorage['specs']) 
				|| (localStorage['src'] && src !== localStorage['src'])) {
			$('.clear-saved').show().delegate('.button','click',function() {
				delete localStorage['specs'];
				delete localStorage['src'];
				$(this).hide();				
				setUpDefaultSpecs();
			});	
		}
		$('#specs').val(localStorage['specs'] || specs);
		$('#src').val(localStorage['src'] || src);
                editor.getSession().setValue(localStorage['specs'] || specs);
	}
		
	//Eventy stuff
	$('.try-it.button').live('click',function(e){
		e.preventDefault();
                var code = editor.getSession().getValue();
                $('#specs').val(code);
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
	        //$('#specs').insertAtCaret($(this).data('snippet')).focus();
                editor.insert($(this).data('snippet'));
	});
    
       var setupCodeBox = function(){
                editor = ace.edit("editor");
                editor.setTheme("ace/theme/textmate");
                var JavaScriptMode = require("ace/mode/javascript").Mode;
                editor.getSession().setMode(new JavaScriptMode());
                $('#specs').hide();
       }
	
	//Dom-ready
	$(function(){
                setupCodeBox();
		setUpDefaultSpecs();
	});
	
})(jQuery);
