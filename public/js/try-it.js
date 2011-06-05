(function($){
  var specEditor;
  var sourceEditor;

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
      self.execute(specEditor);
      self.execute(sourceEditor);
      self.jasmine.getEnv().execute();
    };
    self.execute = function(editor) {
      var script = editor.getSession().getValue();
      localStorage[name] = script;
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
      $('textarea.error, .runner-wrap').removeClass('error');
    };

    var showError = function(name) {
      $('.flash').fadeIn().append("<li>Uh oh, it looks like your JavaScript "+(name === 'specs' ? 'specs have' : 'source has')+" a parse error!</li>");
      $('.runner-wrap').addClass('error');
    };

    return self;
  };

  window.templates = {
    stillDefault: function(name, editor) {
      return this.getDefault(name) === editor.getSession().getValue();
    },
    getDefault: function(name) {
      return $.trim($('#default-'+name).text());
    },
    renderDefault: function(name, editor) {
      var script = this.getDefault(name, editor);
      if((localStorage[name] && script !== localStorage[name])) {
        $('.clear-saved').show().css('display','inline-block');
      }
      if (!editor) {return;}
        editor.getSession().setValue(localStorage[name] || script);
      },
    init: function() {
      this.renderDefault('specs', specEditor);
      this.renderDefault('src', sourceEditor);
    },
    goCoffee: function() {
      if((this.stillDefault('specs', specEditor) && this.stillDefault('src', sourceEditor))
        || confirm('overwrite your code with a sampling of CoffeeScript?')) {
        codeBoxes.switchToCoffeeScriptMode();
        specEditor.getSession().setValue(this.getDefault('coffee-specs'));
        sourceEditor.getSession().setValue(this.getDefault('coffee-src'));
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

  window.codeBoxes = {
    setupCodeBoxes: function(){
      if ($('#spec-editor').length){
        specEditor = ace.edit("spec-editor");
        specEditor.setTheme("ace/theme/textmate"); var
        JavaScriptMode = require("ace/mode/javascript").Mode;
        specEditor.getSession().setMode(new JavaScriptMode());
        $('#specs').hide();
      }
      if ($('#source-editor').length){
        sourceEditor = ace.edit("source-editor");
        sourceEditor.setTheme("ace/theme/textmate");
        sourceEditor.getSession().setMode(new
        JavaScriptMode()); $('#src').hide();
      }
    },
    switchToCoffeeScriptMode: function(){
      var CoffeeScriptMode = require("ace/mode/coffee").Mode;
      specEditor.getSession().setMode(new CoffeeScriptMode());
      sourceEditor.getSession().setMode(new CoffeeScriptMode());
    },
    getSpecEditor: function(){
      return specEditor;
    },
    getSourceEditor: function(){
      return sourceEditor;
    }
  };

  //Dom-ready
  $(function(){
    codeBoxes.setupCodeBoxes();
    templates.init();
  });
})(jQuery);
