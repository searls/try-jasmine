beforeEach ->
delete localStorage['spec']
delete localStorage['src']


describe "Sandbox", ->
  beforeEach ->
    iframe = {
      contentWindow: {
        eval: jasmine.createSpy('.eval'),
        getEnv: {
          execute: jasmine.createSpy('#execute'),
          addReporter: jasmine.createSpy('#addReporter')
        }
      }
    }
    spyOn($.fn, "get").andReturn(iframe)
    sandbox = Sandbox()

  describe "#run", ->
  it "empties the error message box's html", ->
  it "hides the error message box", ->
  it "removes the error class from textareas", ->
  it "removes the error class from the spec runner container", ->

  it "adds a trivial reporter to the jasmine environment", ->


  it "evals the script in the textarea", ->

  context "when eval as JS fails", ->
    it "compiles the script to CoffeeScript", ->
    it "evals the compiled CoffeeScript", ->

  context "when eval as JS & CoffeeScript both fail", ->
    it "shows the error message box", ->
    it "prints the parse error to the error message box", ->
    it "adds the error class to the spec runner container", ->
    it "adds the error class to the script textarea", ->
    it "description", ->

  it "executes jasmine", ->










