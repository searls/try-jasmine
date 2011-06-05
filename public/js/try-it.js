(function($){
  window.tryIt = function() {
    $('.spec-runner').html($('.loading.template').html());
    $('#sandbox').remove();
    $($('.sandbox.template').html()).appendTo('body').load(function() {
      $('.spec-runner').html('');
      Sandbox().runSpecs();
    });
  };

  //Define the little iframe sandbox
  window.Sandbox = function(){
    var self = $('#sandbox').get(0).contentWindow;

    self.runSpecs = function() {
      hideErrors();
      self.jasmine.getEnv().addReporter(new self.jasmine.TrivialReporter({
        location: window.document.location,
        body: $('.spec-runner')[0]
      }));
      self.execute($('#specs').data('editor'));
      self.execute($('#src').data('editor'));
      self.jasmine.getEnv().execute();
    };
    self.execute = function(editor) {
      var script = editor.getSession().getValue();
      localStorage[editor.name] = script;
      try {
        self.eval(script);
      } catch(e) {
        //Well, maybe it's just coffeescript.
        try {
          self.eval(CoffeeScript.compile(script, { bare: true }));
        } catch(coffeeError) {
          showError(name);
          throw coffeeError;
        }
      }
    };

    var hideErrors = function() {
      $('.flash').html('').hide();
      $('.error, .runner-wrap').removeClass('error');
    };

    var showError = function(name) {
      $('.flash').fadeIn().append("<li>Uh oh, it looks like your JavaScript "+(name === 'specs' ? 'specs have' : 'source has')+" a parse error!</li>");
      $('.runner-wrap').addClass('error');
    };

    return self;
  };

  window.templates = {
    getEditor: function(name) {
      return $('#'+name).data('editor');
    },
    stillDefault: function(editor) {
      return this.getDefault(editor.name) === editor.getSession().getValue();
    },
    getDefault: function(name) {
      return $.trim($('#default-'+name).text());
    },
    renderDefault: function(name) {
      var script = this.getDefault(name);
      if((localStorage[name] && script !== localStorage[name])) {
        $('.clear-saved').show().css('display','inline-block');
      }
      this.getEditor(name).getSession().setValue(localStorage[name] || script);
    },
    init: function() {
      this.renderDefault('specs');
      this.renderDefault('src');
    },
    goCoffee: function() {
      var specEditor = this.getEditor('specs'),
          sourceEditor = this.getEditor('source')
      if((this.stillDefault(specEditor) && this.stillDefault(sourceEditor))
        || confirm('overwrite your code with a sampling of CoffeeScript?')) {
        var coffeefy = function(editor) {
          editor.switchMode('coffee');
          editor.getSession().setValue(this.getDefault('coffee-'+editor.name));
        };
        coffeefy(specEditor);
        coffeefy(sourceEditor);
      }
    }
  };

  //Eventy stuff
  $('.try-it.button').live('click',function(e){
    e.preventDefault();
    tryIt();
  });
  $('html, body').add(document.body).keydown(function(e){
    if(e.which == 13 && (e.ctrlKey || e.metaKey)) {
      e.preventDefault();
      tryIt();
    }
  });
  $('.button.insert').live('click',function(e) {
    e.preventDefault();
    specEditor.insert($(this).data('snippet'));
  });
  $('.clear-saved').live('click',function(e) {
    e.preventDefault();
    delete localStorage['specs'];
    delete localStorage['src'];
    $(this).hide();
    templates.init();
  });
  $('.coffee.button').live('click',function(e){
    e.preventDefault();
    templates.goCoffee();
  });

  $.fn.codeBox = function() {
    var $this = $(this);
    var editor = ace.edit($this.attr('id'));
    editor.setTheme("ace/theme/textmate");
    editor.switchMode = function(name) {
      var mode = require("ace/mode/"+name).Mode;
      editor.getSession().setMode(new mode());
    };
    editor.name = $this.attr('id');
    editor.switchMode('javascript');
    $this.data('editor',editor);
    return $this;
  }

  //Dom-ready
  $(function(){
    $('#specs').codeBox();
    $('#src').codeBox();
    templates.init();
  });
})(jQuery);
