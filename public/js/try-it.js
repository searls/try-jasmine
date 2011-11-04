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
      self.jasmine.getEnv().addReporter(new StylishReporter());
      editors.each(function(editor) {
        self.execute(editor);
      });
      self.jasmine.getEnv().execute();
    };
    self.execute = function(editor) {
      var script = editor.getSession().getValue();
      localStorage[editor.name] = script;
      try {
        self.eval(script);
      } catch(javaScriptError) {
        //Well, maybe it's just coffeescript.
        try {
          self.eval(CoffeeScript.compile(script, { bare: true }));
          editors.setMode('coffee');
        } catch(coffeeError) {
          var fullError = 'JavaScript Parse Error: '+javaScriptError+
                          '<br/>'+
                          'CoffeeScript Compile Error: '+coffeeError;
          showError(editor.name,fullError);
          throw fullError.replace(/\<br\/\>/g,"\n");
        }
      }
    };

    var hideErrors = function() {
      $('.flash').html('').hide();
      $('.error, .runner-wrap').removeClass('error');
    };

    var showError = function(name,fullError) {
      $('.flash').fadeIn().append("<li>Uh oh, it looks like your JavaScript "+(name === 'specs' ? 'specs have' : 'source has')+" a parse error!"+
          "<br/><br/>"+
          "<code>"+fullError+"</code>"+
          "</li>");
      $('.runner-wrap, #'+name).addClass('error');
    };

    return self;
  };

  window.templates = {
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
      editors.get(name).getSession().setValue(localStorage[name] || script);
    },
    init: function() {
      _(editors.names).each(function(name) {
        templates.renderDefault(name);
      });
    },
    goCoffee: function() {
      editors.setMode('coffee');
      editors.each(function(editor) {
        var coffee = Js2coffee.build(editor.getSession().getValue());
        editor.getSession().setValue(coffee);
      });
    },
    goJavaScript: function() {
      editors.setMode('javascript');
      editors.each(function(editor) {
        var js = CoffeeScript.compile(editor.getSession().getValue(), { bare: "on" });
        editor.getSession().setValue(js);
      });
    }
  };

  $.fn.codeBox = function() {
    var $this = $(this);
    var editor = ace.edit($this.attr('id'));
    editor.name = $this.attr('id');
    editor.setTheme("ace/theme/textmate");
    editor.getSession().setTabSize(2);
    editor.getSession().setUseSoftTabs(true);
    editor.renderer.setShowPrintMargin(false);
    editor.switchMode = function(name) {
      localStorage['editorMode'] = name;
      $('#mode-select').val(name);
      var mode = require("ace/mode/"+name).Mode;
      editor.getSession().setMode(new mode());
    };
    editor.switchMode(localStorage['editorMode'] || 'javascript');
    $this.data('editor',editor);
    return $this;
  };

  var editors = {
    names: ['specs','src'],
    get: function(name) {
      return $('#'+name).data('editor');
    },
    getMode: function() {
      return $('#mode-select').val();
    },
    setMode: function(name) {
      $('#mode-select').val(name).trigger('change');
    },
    each: function(f) {
      return _(editors.names).each(function(name,i) {
        f(editors.get(name),i);
      });
    },
    all: function(f) {
      return _(editors.names).all(function(name,i) {
        return f(editors.get(name),i);
      });
    }
  };

  //Eventy stuff
  $('html, body').add(document.body).keydown(function(e){
    if(e.which === 13 && (e.ctrlKey || e.metaKey)) {
      e.preventDefault();
      tryIt();
    }
  });
  $('#mode-select').live('change',function(e) {
    e.preventDefault();
    var $sel = $(this);
    editors.each(function(editor) {
      editor.switchMode($sel.val());
    });
  });
  var clicker = function(selector,action) {
    $(selector).live('click',function(e) {
      e.preventDefault();
      action.apply(this,[e]);
    });
  };
  clicker('.try-it.button',function() {
    tryIt();
  });
  clicker('.button.insert',function() {
    editors.get('specs').insert($(this).data(editors.getMode()+'-snippet'));
  });
  clicker('.clear-saved',function() {
    _(editors.names).each(function(name) {
      delete localStorage[name];
    });
    $(this).hide();
    editors.setMode('javascript');
    templates.init();
  });
  clicker('.coffee.button',function() {
    templates.goCoffee();
  });
  clicker('.coffee2js.button',function(){
    templates.goJavaScript();
  });
  clicker('.scroll-to-results',function() {
    window.scrollTo(0,$('.jasmine_reporter').offset().top);
  });
  clicker('.flip-editors',function() {
    arrangeEditors(localStorage['verticalSplit'] === "false" ? true : false)
  });

  var arrangeEditors = function(vertical) {
    $('.editor-wrapper').toggleClass('vertical',vertical);
    $('.editor').toggleClass('vertical',vertical);
    editors.each(function(editor) {
      editor.resize();
    });
    localStorage['verticalSplit'] = vertical;
  };

  var loadGists = (function() {
    var idMatches = window.location.search.match(/gist=(\d*)/);
    if(idMatches) {
      $.getJSON('/gists/'+idMatches[1],function(json) {
        $(function() {
          var specs = '',
              src = '',
              containsCoffee = false;
          _(json.files).each(function(file,name) {
            if(name.indexOf('.coffee') !== -1) {
              containsCoffee = true;
            }

            if(name.match(/spec\.(js|coffee)/)) {
              specs += file.content + '\n';
            } else {
              src += file.content + '\n';
            }
          });
          editors.setMode(containsCoffee? 'coffee' : 'javascript');

          editors.get("specs").getSession().setValue(specs);
          editors.get("src").getSession().setValue(src);

        });
      });
    }
  })();

  var hackAceKeyboardShortcuts = (function() {
    var canon = require('pilot/canon');
    canon.removeCommand("gotoline");
    canon.addCommand({
        name: "donothingsave",
        bindKey: {
          win: 'Ctrl-S',
          mac: 'Command-S',
          sender: 'editor'
        },
        exec: function(env, args, request) {
          tryIt();
        }
    });
  })();

  var StylishReporter = function() {};
  StylishReporter.prototype.reportRunnerStarting = function() {
    $('body').removeClass();
    $('.body-wrap').removeClass('passing-border','failing-border');
  };
  StylishReporter.prototype.reportRunnerResults = function() {
    var passed = $('.runner-wrap .runner').hasClass('passed');
    $('body').toggleClass('passing',passed);
    $('body').toggleClass('failing',!passed);
    $('.body-wrap').toggleClass('passing-border',passed);
    $('.body-wrap').toggleClass('failing-border',!passed);

    $('.runner-notice').html($('.jasmine_reporter .runner .description').text()+' (<a class="scroll-to-results">see results</a>)')
      .toggleClass('passing',passed)
      .toggleClass('failing',!passed);
  };

  if(!window.runningTryJasmineSpecs) {
    $(document).ready(function(){
      $('#specs').codeBox();
      $('#src').codeBox();
      templates.init();
      arrangeEditors(localStorage['verticalSplit'] === "false" ? false : true);
    });
  }
})(jQuery);
