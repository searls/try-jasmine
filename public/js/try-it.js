(function($){
	window.tryIt = function() {
		var sandbox = Sandbox();	
		sandbox.runSpecs();
		sandbox.kill();
		$('.spec-runner').html($('body > .jasmine_reporter'));
	};

	//Define the little iframe sandbox
	window.Sandbox = function(){
		var self = $('#sandbox').get(0).contentWindow;
		
		self.runSpecs = function() {
			hideErrors();
			self.jasmine.getEnv().addReporter(new self.jasmine.TrivialReporter());
			run('specs');
			run('src');
			self.jasmine.getEnv().execute();
		}
		self.kill = function() {
			$('#sandbox').get(0).src = $('#sandbox').attr('src');
			self = $('#sandbox').get(0).contentWindow;
		};		
		
		var run = function(name) {
			var script = $('#'+name).val();
			localStorage[name] = script;
			try {
				self.eval(script);
			} catch(e) {
				//Well, maybe it's just coffeescript.
				try {
					self.eval(CoffeeScript.compile(script, { bare: true }));
				} catch(coffeeError) {
					showError(name);
					self.kill();	
				}
			}
		}
		
		var hideErrors = function() {
			$('.flash').html('').hide();
			$('textarea.error, .runner-wrap').removeClass('error');
		};
		
		var showError = function(name) {
			$('.flash').fadeIn().append("<li>Uh oh, it looks like your JavaScript "+(name === 'specs' ? 'specs have' : 'source has')+" a parse error!</li>");
			$('.runner-wrap, #'+name).addClass('error');
		};
		
		return self;		
	};

	var templates = {
		stillDefault: function(name) {
			return this.getDefault(name) === $('#'+name).val();
		},
		getDefault: function(name) {
			return $.trim($('#default-'+name).text());
		},
		renderDefault: function(name) {
			var script = this.getDefault(name);
			if((localStorage[name] && script !== localStorage[name])) {
				$('.clear-saved').show();
			}
			$('#'+name).val(localStorage[name] || script);		
		},
		init: function() {
			this.renderDefault('specs');
			this.renderDefault('src');
		},
		goCoffee: function() {
			if((this.stillDefault('specs') && this.stillDefault('src'))
					|| confirm('overwrite your code with a sampling of CoffeeScript?')) {
				$('#specs').val(this.getDefault('coffee-specs'));
				$('#src').val(this.getDefault('coffee-src'));
			}
		}		
	};
		
	//Eventy stuff
	$('.try-it.button').live('click',function(e){
		e.preventDefault();
		tryIt();
	});
	$('body').live('keypress',function(e){
		if(e.which == 13 && (e.ctrlKey || e.metaKey)) {
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
	$('.clear-saved').live('click',function() {
		delete localStorage['specs'];
		delete localStorage['src'];
		$(this).hide();				
		templates.init();
	});
	$('.coffee.button').live('click',function(e){
		e.preventDefault();
		templates.goCoffee();
	});
	
	//Dom-ready
	$(function(){
		templates.init();
	});
	
})(jQuery);