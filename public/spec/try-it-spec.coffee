ogSpecs=ogSrc=null
beforeEach ->
  ogSpecs=localStorage['specs'] if localStorage['specs']
  ogSrc=localStorage['src'] if localStorage['src']

afterEach ->
  localStorage['specs'] = ogSpecs if ogSpecs
  localStorage['src'] = ogSrc if ogSrc


describe ".tryIt", ->
  $specRunner=previousSandboxNode=loadHandler=null
  beforeEach ->
    spyOn($.fn, "load").andCallFake((f) -> loadHandler = f)
    previousSandboxNode = $.jasmine.inject('<div id="sandbox">blah</div>')[0]
    $.jasmine.inject('<div class="template loading"><div id="someLoading"></div></div>')
    $.jasmine.inject('<div class="template sandbox"><div id="someSandboxIframe"></div></div>')
    $specRunner = $.jasmine.inject('<div class="spec-runner">blarg</div>')

    tryIt()

  it "apends the iframe template to the body", ->
    expect($('body > #someSandboxIframe')).toExist()

  it "removes the old sandbox", ->
    expect($(previousSandboxNode)).not.toBeVisible()

  it "appends a loading template to the spec-runner", ->
    expect($specRunner).toContain('#someLoading')

  describe "the load handler", ->
    beforeEach ->
      spyOn(window, "Sandbox").andReturn({
        runSpecs: jasmine.createSpy('#runSpecs')
      })
      loadHandler()

    it "empties the spec results container", ->
      expect($specRunner).toHaveHtml('');

    it "runs specs", ->
      expect(Sandbox().runSpecs).toHaveBeenCalled()

  afterEach ->
    $('#someSandboxIframe').remove()

describe "Sandbox", ->
  iframe=iframeWindow=sandbox=jsmin=$specEditor=$sourceEditor=null
  beforeEach ->
    iframeWindow = {
      eval: jasmine.createSpy('.eval'),
      jasmine: {
        TrivialReporter: (config) -> config
        env: {
          execute: jasmine.createSpy('#execute'),
          addReporter: jasmine.createSpy('#addReporter')
        },
        getEnv: -> @env
      }
    }
    iframe = { contentWindow: iframeWindow}
    spyOn($.fn, "get").andReturn(iframe)
    jsmin = iframeWindow.jasmine
    $.jasmine.inject('<div id="spec-editor"></div>');
    $.jasmine.inject('<div id="source-editor"></div>');
    codeBoxes.setupCodeBoxes()
    $specEditor = codeBoxes.getSpecEditor()
    $sourceEditor = codeBoxes.getSourceEditor()

    sandbox = Sandbox()




  describe "#runSpecs", ->
    $flash=$textareas=$runner=$specRunner=null
    beforeEach ->
      spyOn(sandbox, "execute")
      $flash = $.jasmine.inject('<div class="flash">Stuff</div>')
      $textareas = $.jasmine.inject('<textarea class="error"></textarea>')
      $runner = $.jasmine.inject('<div class="runner-wrap error"></div>')
      $specRunner = $.jasmine.inject('<div class="spec-runner"></div>');

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

      expect(jsmin.getEnv().addReporter.mostRecentCall.args[0]).toEqual(new jsmin.TrivialReporter({
        location: window.document.location,
        body: $specRunner[0]
      }))

    it "executes 'specs'", ->
      expect(sandbox.execute).toHaveBeenCalledWith($specEditor)

    it "executes 'src", ->
      expect(sandbox.execute).toHaveBeenCalledWith($sourceEditor)

    it "executes jasmine", ->
      expect(jsmin.getEnv().execute).toHaveBeenCalled()

  describe "#execute", ->
    $flash=$textarea=$runner=name=null
    beforeEach ->
      name = 'some-script'
      $specEditor.getSession().setValue(name)
      $sourceEditor.getSession().setValue("Panda Script")
      $flash = $.jasmine.inject('<div class="flash"></div>').hide()
      $runner = $.jasmine.inject('<div class="runner-wrap"></div>')

    context "when all is well", ->
      beforeEach ->
        sandbox.execute($specEditor)

      it "evals the script in the textarea", ->
        expect(iframeWindow.eval).toHaveBeenCalledWith(name)


    context "when eval as JS fails", ->
      thrown=null
      beforeEach ->
        iframeWindow.eval.andThrow(':(')
        spyOn(CoffeeScript, "compile").andReturn('coffee!')
        spyOn($.fn, "fadeIn").andCallThrough()


        sandbox.execute($specEditor)

        it "compiles the script to CoffeeScript", ->
         script = editor.getSession().getValue()
         expect(CoffeeScript.compile).toHaveBeenCalledWith(script,{bare:on})

        it "evals the compiled CoffeeScript", ->
          expect(iframeWindow.eval).toHaveBeenCalledWith('coffee!')

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

        it "throws the error", ->
          expect(thrown).toBe(':(')


describe "templates", ->
  $textarea=name=script=$default=$specEditor=$sourceEditor=null
  beforeEach ->
    name = 'blah'
    script = 'some script'
    $default = $.jasmine.inject("<div id='default-#{name}'> #{script} </div>")
    $.jasmine.inject('<div id="spec-editor"></div>');
    $.jasmine.inject('<div id="source-editor"></div>');
    codeBoxes.setupCodeBoxes()
    $specEditor = codeBoxes.getSpecEditor()
    $sourceEditor = codeBoxes.getSourceEditor()



  describe ".init", ->
    beforeEach ->
      spyOn(templates, "renderDefault")


      templates.init()

    it "renders specs", ->
      expect(templates.renderDefault).toHaveBeenCalledWith('specs', $specEditor)

    it "renders src", ->
      expect(templates.renderDefault).toHaveBeenCalledWith('src', $sourceEditor)

  describe ".stillDefault", ->
    result=null
    beforeEach ->
      $specEditor.getSession().setValue(script)

    context "when the script matches its default", ->
      beforeEach ->
        result = templates.stillDefault(name, $specEditor)

      it "returns true", ->
        expect(result).toBe(true)

    context "when the script does not match its default", ->
      beforeEach ->
        $default.html('some new script')
        result = templates.stillDefault(name, $specEditor)

      it "returns false", ->
        expect(result).toBe(false)

  describe ".renderDefault", ->
    $clearSaved=null
    beforeEach ->
      delete localStorage[name]
      $clearSaved = $.jasmine.inject('<div class="clear-saved">Blah</div>').hide()

    context "no script saved in localStorage", ->
      beforeEach ->
        templates.renderDefault(name, $specEditor)

      it "populates the textarea with the default", ->
        editorValue = $specEditor.getSession().getValue()
        expect(editorValue).toBe(script)

    context "script is in localStorage", ->
      customScript=$editorValue=null
      beforeEach ->
        localStorage[name] = customScript = 'custom script'

        templates.renderDefault(name, $specEditor)
        $editorValue = $specEditor.getSession().getValue()

      it "populates the editor with the saved script", ->
        expect($editorValue).toBe(customScript)

      it "shows the 'Clear Saved' button", ->
        expect($clearSaved).toBeVisible()

      it "changes the style of the Clear Saved button to be inline-block", ->
        expect($clearSaved.css('display')).toBe('inline-block')

    context "default script is the same as saved in local storage", ->
      beforeEach ->
        localStorage[name] = script

      it "keeps the 'Clear Saved' button hidden", ->
        expect($clearSaved).not.toBeVisible()

  describe ".getDefault", ->
    $default=result=null
    beforeEach ->
      result = templates.getDefault(name, $specEditor)

    it "returns whatever is in #default-<name>", ->
      expect(result).toBe(script)

  describe ".goCoffee", ->
    $specs=$src=$editorValue=$sourceValue=null
    beforeEach ->
      spyOn(window, "confirm")
      spyOn(templates, "stillDefault")
      spyOn(templates, "getDefault").andCallFake((name, $specEditor) -> name)


    itOverwritesScripts = ->
      it "overwrites the specs", ->
        expect($editorValue).toBe('coffee-specs')

      it "overwrites the src", ->
        expect($sourceValue).toBe('coffee-src')

    context "when specs and src are still default", ->
      beforeEach ->
        templates.stillDefault.andReturn(true)
        templates.goCoffee()
        $editorValue = $specEditor.getSession().getValue()
        $sourceValue = $sourceEditor.getSession().getValue()

      it "does not display a confirm", ->
        expect(window.confirm).not.toHaveBeenCalled()

      itOverwritesScripts()

    context "when specs and src have been customized", ->
      beforeEach ->
        templates.stillDefault.andReturn(false)
        templates.goCoffee()
        $editorValue = $specEditor.getSession().getValue()
        $sourceValue = $sourceEditor.getSession().getValue()

      it "displays a confirm", ->
        expect(window.confirm).toHaveBeenCalledWith('overwrite your code with a sampling of CoffeeScript?')

      context "when the user confirms", ->
        beforeEach ->
          window.confirm.andReturn(true)
          templates.goCoffee()
          $editorValue = $specEditor.getSession().getValue()
          $sourceValue = $sourceEditor.getSession().getValue()

        itOverwritesScripts()

      context "when the user rejects", ->
        beforeEach ->
          window.confirm.andReturn(false)
          templates.goCoffee()
          $editorValue = $specEditor.getSession().getValue()
          $sourceValue = $sourceEditor.getSession().getValue()

        it "leaves specs as-is", ->
          expect($editorValue).toBe('')

        it "leaves src as-is", ->
          expect($sourceValue).toBe('')

describe "~ user interface events", ->
  describe "clicking the 'try jasmine' button", ->
    beforeEach ->
      spyOn(window, "tryIt")

      $('<span class="try-it button"></span>').click()

    it "invokes tryIt", ->
      expect(tryIt).toHaveBeenCalled()

  describe "hitting tab", ->
    $field=null
    beforeEach ->
      spyOn($.fn, "insertAtCaret")
      $field = $.jasmine.inject('<span class="source"></span>')

    context "just tab", ->
      beforeEach -> $field.trigger({ type: 'keydown', keyCode: 9 })
      it "inserts two spaces", ->
        expect($.fn.insertAtCaret).toHaveBeenCalledWith('  ')

      it "inserts them on the source", ->
        expect($.fn.insertAtCaret.mostRecentCall.object[0]).toBe($field[0])

    context "holding shift", ->
      beforeEach -> $field.trigger({ type: 'keydown', keyCode: 9, shiftKey: true })

      it "does nothing", ->
        expect($.fn.insertAtCaret).not.toHaveBeenCalled()

  describe "hitting a snippet button", ->
    $button=snippet=$editorValue=null
    beforeEach ->
      $.jasmine.inject('<div id="spec-editor"></div>');
      $.jasmine.inject('<div id="source-editor"></div>');
      codeBoxes.setupCodeBoxes()
      $specEditor = codeBoxes.getSpecEditor()
      snippet = '1337 codez'
      $button = $("<span class='button insert' data-snippet='#{snippet}'></span>")

      $button.trigger('click')
      $editorValue = $specEditor.getSession().getValue()

    it "inserts the snippet", ->
      expect($editorValue).toBe(snippet)

  describe "clicking a clear-saved button", ->
    $button=null
    beforeEach ->
      localStorage['specs'] = localStorage['src'] = 'a'
      $button = $.jasmine.inject('<span class="clear-saved">b</span>')
      spyOn(templates, "init")

      $button.trigger('click')

    it "clears stored specs", ->
      expect(localStorage['specs']).not.toBeDefined()

    it "clears stored src", ->
      expect(localStorage['src']).not.toBeDefined()

    it "hides the button", ->
      expect($button).not.toBeVisible()

    it "re-initializes the template", ->
      expect(templates.init).toHaveBeenCalled()

  describe "hitting the coffee button", ->
    $button=null
    beforeEach ->
      spyOn(templates, "goCoffee")
      $button = $('<span class="coffee button"></span>')

      $button.trigger('click')

    it "shows some coffee", ->
      expect(templates.goCoffee).toHaveBeenCalled()

  describe "hitting enter", ->
    beforeEach ->
      spyOn(window, "tryIt")

    context "just enter", ->
      beforeEach -> $(document.body).trigger({type: 'keydown', which: 13})

      it "doesn't execute the specs", ->
        expect(tryIt).not.toHaveBeenCalled()

    context "cmd-enter", ->
      beforeEach -> $(document.body).trigger({type: 'keydown', which: 13, metaKey: true})

      it "executes the specs", ->
        expect(tryIt).toHaveBeenCalled()

    context "ctrl-enter", ->
      beforeEach -> $(document.body).trigger({type: 'keydown', which: 13, ctrlKey: true})

      it "executes the specs", ->
        expect(tryIt).toHaveBeenCalled()
