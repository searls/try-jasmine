beforeEach ->
  delete localStorage['spec']
  delete localStorage['src']


describe "Sandbox", ->
  iframe=sandbox=jsmin=null
  beforeEach ->
    iframe = {
      eval: jasmine.createSpy('.eval'),
      jasmine: {
        TrivialReporter: -> @trivialReporter='Yup!'
        env: {
          execute: jasmine.createSpy('#execute'),
          addReporter: jasmine.createSpy('#addReporter')
        },
        getEnv: -> @env
      }
    }    
    spyOn($.fn, "get").andReturn({ contentWindow: iframe})
    jsmin = iframe.jasmine

    sandbox = Sandbox()

  describe "#runSpecs", ->
    $flash=$textareas=$runner=null
    beforeEach ->
      spyOn(sandbox, "execute")
      $flash = $.jasmine.inject('<div class="flash">Stuff</div>')
      $textareas = $.jasmine.inject('<textarea class="error"></textarea>')
      $runner = $.jasmine.inject('<div class="runner-wrap error"></div>')
      
      sandbox.runSpecs()
    
    it "empties the error message box", ->
      expect($flash).toHaveText('')
      
    it "hides the error message box", ->
      expect($flash).not.toBeVisible()
    
    it "removes the error class from textareas", ->
      expect($textareas).not.toHaveClass('error')
      
    it "removes the error class from the spec runner container", ->
      expect($runner).not.toHaveClass('error')

    it "adds a trivial reporter to the jasmine environment", ->
      expect(jsmin.getEnv().addReporter.mostRecentCall.args[0]).toEqual(new jsmin.TrivialReporter())
    
    it "executes 'specs'", ->
      expect(sandbox.execute).toHaveBeenCalledWith('specs')
    
    it "executes 'src", ->
      expect(sandbox.execute).toHaveBeenCalledWith('src')
    
    it "executes jasmine", ->
      expect(jsmin.getEnv().execute).toHaveBeenCalled()
    
  describe "#execute", ->
    $flash=$textarea=$runner=name=null
    beforeEach ->
      name = 'some-script'
      $textarea = $.jasmine.inject("<input id='#{name}' value='Panda Script'/>")
      $flash = $.jasmine.inject('<div class="flash"></div>').hide()
      $runner = $.jasmine.inject('<div class="runner-wrap"></div>')

    context "when all is well", ->      
      beforeEach -> sandbox.execute(name)
      
      it "evals the script in the textarea", ->
        expect(iframe.eval).toHaveBeenCalledWith($('#'+name).val())

        
    context "when eval as JS fails", ->
      beforeEach ->
        iframe.eval.andThrow(':(')
        spyOn(CoffeeScript, "compile").andReturn('coffee!')
        spyOn($.fn, "fadeIn").andCallThrough()
        spyOn(sandbox, "kill")

        sandbox.execute(name)
      
      it "compiles the script to CoffeeScript", ->
        expect(CoffeeScript.compile).toHaveBeenCalledWith($textarea.val(),{bare:on})

      it "evals the compiled CoffeeScript", ->
        expect(iframe.eval).toHaveBeenCalledWith('coffee!')

      context "when eval as JS & CoffeeScript both fail", ->
        it "shows the error message box", ->
          expect($flash).toBeVisible()

        it "fades in the error message box", ->
          expect($.fn.fadeIn.mostRecentCall.object[0]).toBe($flash[0])

        it "prints the parse error to the error message box", ->
          expect($flash.text()).toContain("Uh oh")

        it "adds the error class to the spec runner container", ->
          expect($runner).toHaveClass('error')

        it "adds the error class to the script textarea", ->
          expect($textarea).toHaveClass('error')
          
        it "kills the sandbox", ->
          expect(sandbox.kill).toHaveBeenCalled()
        

