ogSpecs=ogSrc=null
beforeEach ->
  ogSpecs=localStorage['specs'] if localStorage['specs']
  ogSrc=localStorage['src'] if localStorage['src']
  spyOn($.fn, "ready")

afterEach ->
  delete localStorage['editorMode']
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
      expect($specRunner).toHaveHtml('')

    it "runs specs", ->
      expect(Sandbox().runSpecs).toHaveBeenCalled()

  afterEach ->
    $('#someSandboxIframe').remove()

describe "Sandbox", ->
  iframe=iframeWindow=sandbox=jsmin=specEditor=sourceEditor=null
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
    specEditor = fakeEditor('specs')
    sourceEditor = fakeEditor('src')
    sandbox = Sandbox()

  describe "#runSpecs", ->
    $flash=$runner=$specRunner=null
    beforeEach ->
      spyOn(sandbox, "execute")
      $flash = $.jasmine.inject('<div class="flash">Stuff</div>')
      $runner = $.jasmine.inject('<div class="runner-wrap error"></div>')
      $specRunner = $.jasmine.inject('<div class="spec-runner"></div>')
      $('#specs').addClass('error')
      sandbox.runSpecs()

    it "empties the error message box", ->
      expect($flash).toHaveText('')

    it "hides the error message box", ->
      expect($flash).not.toBeVisible()

    it "removes the error class from the spec runner container", ->
      expect($runner).not.toHaveClass('error')

    it "removes the error class to the editor", ->
      expect($('#specs')).not.toHaveClass('error')

    it "adds a trivial reporter to the jasmine environment", ->
      expect(jsmin.getEnv().addReporter.calls[0].args[0]).toEqual(new jsmin.TrivialReporter({
        location: window.document.location,
        body: $specRunner[0]
      }))

    it "executes 'specs'", ->
      expect(sandbox.execute).toHaveBeenCalledWith(specEditor)

    it "executes 'src'", ->
      expect(sandbox.execute).toHaveBeenCalledWith(sourceEditor)

    it "executes jasmine", ->
      expect(jsmin.getEnv().execute).toHaveBeenCalled()

  describe "#execute", ->
    $flash=$runner=name=null
    beforeEach ->
      name = 'some-script'
      specEditor.getSession().setValue(name)
      sourceEditor.getSession().setValue("Panda Script")
      $flash = $.jasmine.inject('<div class="flash"></div>').hide()
      $runner = $.jasmine.inject('<div class="runner-wrap"></div>')

    context "when all is well", ->
      beforeEach ->
        sandbox.execute(specEditor)

      it "evals the script in the editor", ->
        expect(iframeWindow.eval).toHaveBeenCalledWith(name)

    context "when eval of JS fails, but Coffee succeeds", ->
      $select=null
      beforeEach ->
        $select = $.jasmine.inject('<input value="" id="mode-select"></input>')
        iframeWindow.eval.andCallFake(-> if iframeWindow.eval.callCount == 1 then throw ':(')
        spyOn(CoffeeScript, "compile").andReturn('coffee!')
        sandbox.execute(specEditor)

      it "sets coffee mode", ->
        expect($select).toHaveValue('coffee')


    context "when eval as JS fails", ->
      thrown=null
      beforeEach ->
        iframeWindow.eval.andThrow(':(')
        spyOn(CoffeeScript, "compile").andReturn('coffee!')
        spyOn($.fn, "fadeIn").andCallThrough()

        try sandbox.execute(specEditor) catch e then thrown = e

      it "compiles the script to CoffeeScript", ->
       expect(CoffeeScript.compile).toHaveBeenCalledWith(specEditor.getSession().getValue(),{bare:on})

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

        it "adds the error class to the editor", ->
          expect($('#specs')).toHaveClass('error')

        it "throws both errors so they hit the user's console", ->
          expect(thrown).toBe('''
                              JavaScript Parse Error: :(
                              CoffeeScript Compile Error: :(
                              ''')

describe "templates", ->
  name=script=$default=specEditor=sourceEditor=null
  beforeEach ->
    name = 'specs'
    script = 'some script'
    $default = $.jasmine.inject("<div id='default-#{name}'> #{script} </div>")
    specEditor = fakeEditor('specs')
    sourceEditor = fakeEditor('src')

  describe ".init", ->
    beforeEach ->
      spyOn(templates, "renderDefault")
      templates.init()

    it "renders specs", ->
      expect(templates.renderDefault).toHaveBeenCalledWith('specs')

    it "renders src", ->
      expect(templates.renderDefault).toHaveBeenCalledWith('src')

  describe ".stillDefault", ->
    result=null
    beforeEach ->
      specEditor.getSession().setValue(script)

    context "when the script matches its default", ->
      beforeEach ->
        result = templates.stillDefault(specEditor)

      it "returns true", ->
        expect(result).toBe(true)

    context "when the script does not match its default", ->
      beforeEach ->
        $default.html('some new script')
        result = templates.stillDefault(specEditor)

      it "returns false", ->
        expect(result).toBe(false)

  describe ".renderDefault", ->
    $clearSaved=customScript=null
    beforeEach ->
      delete localStorage[name]
      $clearSaved = $.jasmine.inject('<div class="clear-saved">Blah</div>').hide()

    context "no script saved in localStorage", ->
      beforeEach ->
        templates.renderDefault(name)

      it "populates the textarea with the default", ->
        expect(specEditor.getSession().getValue()).toBe(script)

    context "script is in localStorage", ->
      beforeEach ->
        localStorage[name] = customScript = 'custom script'
        templates.renderDefault(name)

      it "populates the editor with the saved script", ->
        expect(specEditor.getSession().getValue()).toBe(customScript)

      it "shows the 'Clear Saved' button", ->
        expect($clearSaved).toBeVisible()

      it "changes the style of the Clear Saved button to be inline-block", ->
        expect($clearSaved.css('display')).toBe('inline-block')

    context "default script is the same as saved in local storage", ->
      beforeEach ->
        localStorage[name] = script
        templates.renderDefault(name)

      it "keeps the 'Clear Saved' button hidden", ->
        expect($clearSaved).not.toBeVisible()

  describe ".getDefault", ->
    $default=result=null
    beforeEach ->
      result = templates.getDefault(name, specEditor)

    it "returns whatever is in #default-<name>", ->
      expect(result).toBe(script)

  describe ".goCoffee", ->
    $specs=$src=$editorValue=$sourceValue=$modeSelect=null
    beforeEach ->
      $modeSelect = $.jasmine.inject('<input id="mode-select" value=""></input>')
      spyOn(window, "confirm")
      spyOn(templates, "stillDefault")
      spyOn(templates, "getDefault").andCallFake((name, specEditor) -> name)
      templates.stillDefault.andReturn(true)
      spyOn(Js2coffee, "build").andReturn('yay coffee');
      templates.goCoffee()

      $editorValue = specEditor.getSession().getValue()
      $sourceValue = sourceEditor.getSession().getValue()

    it "sets coffee mode", ->
      expect($modeSelect).toHaveValue('coffee')

    it "overwrites the specs", ->
      expect($editorValue).toBe('yay coffee')

    it "overwrites the src", ->
      expect($sourceValue).toBe('yay coffee')

describe "~ user interface events", ->
  describe "changing the mode selector", ->
    fakeEditors=null
    beforeEach ->
      fakeEditors = fakeBothEditors()
      $.jasmine.inject('''
        <select id="mode-select">
          <option value="javascript"></option>
          <option value="coffee"></option>
        </select>
        ''').val('coffee').trigger('change')

    it "was switched to coffee mode", ->
      _(fakeEditors).each (e) -> expect(e.switchMode).toHaveBeenCalledWith('coffee')

  describe "clicking the 'try jasmine' button", ->
    beforeEach ->
      spyOn(window, "tryIt")

      $('<span class="try-it button"></span>').click()

    it "invokes tryIt", ->
      expect(tryIt).toHaveBeenCalled()

  describe "hitting a snippet button", ->
    snippet=specEditor=result=null
    beforeEach ->
      inject({id: 'mode-select', el: 'input', attrs: { value: 'javascript'}});
      specEditor = fakeEditor('specs')
      snippet = '1337 codez'
      $("<span class='button insert' data-javascript-snippet='#{snippet}'></span>").trigger('click')
      result = specEditor.getSession().getValue()

    it "inserts the snippet", ->
      expect(specEditor.insert).toHaveBeenCalledWith(snippet)

  describe "clicking a clear-saved button", ->
    $button=null
    beforeEach ->
      localStorage['specs'] = localStorage['src'] = 'a'
      $button = $.jasmine.inject('<span class="clear-saved">b</span>')
      spyOn(templates, "init")
      $button.trigger('click')

    it "clears stored specs", ->
      expect(localStorage['specs']).toBeFalsy()

    it "clears stored src", ->
      expect(localStorage['src']).toBeFalsy()

    it "hides the button", ->
      expect($button).not.toBeVisible()

    it "re-initializes the template", ->
      expect(templates.init).toHaveBeenCalled()

  describe "hitting the coffee button", ->
    beforeEach ->
      spyOn(templates, "goCoffee")
      $('<span class="coffee button"></span>').trigger('click')

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

describe "$.fn.codeBox", ->
  $div=result=editor=null
  ID="woah"
  beforeEach ->
    editor = fakeEditorObject(ID)
    editor.name = undefined
    spyOn(ace, "edit").andReturn(editor)
    $div = $("<div id=#{ID}></div>")
    spyOn(window, "require").andReturn({
      Mode: -> @panda = true
    })
    delete localStorage['editorMode']
    result = $div.codeBox()

  it "returns the result object to support chaining", ->
    expect(result).toEqual($div)

  it "creates an ace box for the id of the div", ->
    expect(ace.edit).toHaveBeenCalledWith(ID)

  it "sets the theme to textmate", ->
    expect(editor.setTheme).toHaveBeenCalledWith("ace/theme/textmate")

  it "sets the name to that of the id", ->
    expect(editor.name).toBe(ID)

  it "persists the editor in a data key 'editor'", ->
    expect($div.data('editor')).toBe(editor)

  it "sets tab size of 2", ->
    expect(editor.getSession().setTabSize).toHaveBeenCalledWith(2)

  it "enables soft tabs (spaces instead of tabulators)", ->
    expect(editor.getSession().setUseSoftTabs).toHaveBeenCalledWith(true)

  it "disables print margins", ->
    expect(editor.renderer.setShowPrintMargin).toHaveBeenCalledWith(false)


  behavesLikeItSwitchesModes = (name) ->
    it "requires the #{name} mode", ->
      expect(require.callCount).toBe(1)
      expect(require).toHaveBeenCalledWith("ace/mode/#{name}")

    it "sets the mode on the editor", ->
      expect(editor.getSession().setMode).toHaveBeenCalled()
      expect(editor.getSession().setMode.mostRecentCall.args[0].panda).toBe(true)

  behavesLikeItSwitchesModes('javascript')

  describe "#switchMode", ->
    NAME='PANDA'
    beforeEach ->
      require.reset()
      editor.getSession().setMode.reset()
      editor.switchMode(NAME)

    behavesLikeItSwitchesModes(NAME)

fakeBothEditors = ->
  [fakeEditor('specs'), fakeEditor('src')]

fakeEditor = (id) ->
  editor = fakeEditorObject(id)
  $.jasmine.inject("<div id=\"#{id}\"></div>").data('editor',editor)
  editor

fakeEditorObject = (id) ->
  session = {
    getValue: -> editor.value,
    setValue: (val) -> editor.value = val,
    setMode: jasmine.createSpy('#getSession #setMode'),
    setTabSize: jasmine.createSpy('#getSession #setTabSize')
    setUseSoftTabs: jasmine.createSpy('#getSession #setUseSoftTabs')
  }
  editor = {
    value: '',
    name: id,
    setTheme: jasmine.createSpy('#setTheme'),
    switchMode: jasmine.createSpy('#switchMode'),
    insert: jasmine.createSpy('#insert'),
    renderer: {
      setShowPrintMargin: jasmine.createSpy('#setShowPrintMargin')
    }
    getSession: -> session
  }