path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
_ = require 'underscore-plus'

# Jasmine skip the debounce delay
_.debounce = (func) ->
  ->
    func.apply @, arguments

describe "AutosavePlus", ->
  [workspaceElement, activationPromise, initialActiveItem, projectPath,
   otherPath] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    projectPath = temp.mkdirSync('autosave-plus-spec-')
    otherPath = temp.mkdirSync('some-other-path-')
    fs.copySync(path.join(__dirname, 'fixtures', 'working-dir'), projectPath)
    fs.moveSync(path.join(projectPath, 'git.git'), path.join(projectPath, '.git'))
    atom.project.setPaths([otherPath, projectPath])

    atom.config.set('autosave-plus.excludeGrammars', ['text.git-commit'])
    atom.config.set('autosave-plus.enabled', true)

    waitsForPromise ->
      atom.packages.activatePackage('autosave')

    runs ->
      atom.packages.enablePackage('autosave')

    waitsForPromise ->
      atom.packages.activatePackage('autosave-plus')

    waitsForPromise ->
      atom.workspace.open(path.join(projectPath, 'sample.coffee'))

    waitsForPromise ->
      atom.packages.activatePackage('language-coffee-script')

    waitsForPromise ->
      atom.packages.activatePackage('language-git')

    runs ->
      initialActiveItem = atom.workspace.getActiveTextEditor()
      spyOn(initialActiveItem, 'save')

  describe "when a pane stop changing", ->
    it "saves the item if autosave is enabled and the item has a uri", ->
      expect(initialActiveItem.save).not.toHaveBeenCalled()
      atom.config.set('autosave-plus.enabled', true)
      initialActiveItem.setText("i am also modified")
      advanceClock(initialActiveItem.getBuffer().stoppedChangingDelay)
      expect(initialActiveItem.save).toHaveBeenCalled()

  describe "when the item does not have a URI", ->
    it "does not save the item", ->
      waitsForPromise ->
        atom.workspace.open()

      runs ->
        pathLessItem = atom.workspace.getActiveTextEditor()
        spyOn(pathLessItem, 'save').andCallThrough()
        pathLessItem.setText('text!')
        expect(pathLessItem.getURI()).toBeFalsy()

        atom.config.set('autosave-plus.enabled', true)
        initialActiveItem.setText("i am also modified")
        advanceClock(initialActiveItem.getBuffer().stoppedChangingDelay)
        expect(pathLessItem.save).not.toHaveBeenCalled()

  describe "Settings excludeGrammars", ->
    [commitMsgItem] = []

    beforeEach ->
      waitsForPromise ->
        atom.workspace.open(path.join(projectPath, 'COMMIT_EDITMSG'))
      runs ->
        commitMsgItem = atom.workspace.getActiveTextEditor()
        spyOn(commitMsgItem, 'save').andCallThrough()
        atom.config.set('autosave-plus.enabled', true)

    it "does not save the item", ->
      runs ->
        commitMsgItem.setText("i am modified")
        advanceClock(commitMsgItem.getBuffer().stoppedChangingDelay)
        expect(commitMsgItem.save).not.toHaveBeenCalled()

    it "save the item", ->
      runs ->
        atom.config.set('autosave-plus.excludeGrammars', [])
        commitMsgItem.setText("i am modified")
        advanceClock(commitMsgItem.getBuffer().stoppedChangingDelay)
        expect(commitMsgItem.save).toHaveBeenCalled()

  describe "Settings includeOnlyRepositoryPath", ->
    [otherItem] = []

    beforeEach ->
      waitsForPromise ->
        atom.workspace.open(path.join(otherPath, 'sample.coffee'))
      runs ->
        otherItem = atom.workspace.getActiveTextEditor()
        spyOn(otherItem, 'save')

    it "save the repository item", ->
      runs ->
        atom.config.set('autosave-plus.includeOnlyRepositoryPath', true)
        initialActiveItem.setText("i am modified")
        advanceClock(initialActiveItem.getBuffer().stoppedChangingDelay)
        expect(initialActiveItem.save).toHaveBeenCalled()

    it "done not save the other item", ->
      runs ->
        atom.config.set('autosave-plus.includeOnlyRepositoryPath', true)
        otherItem.setText("i am modified")
        advanceClock(otherItem.getBuffer().stoppedChangingDelay)
        expect(otherItem.save).not.toHaveBeenCalled()

    it "save all item", ->
      runs ->
        atom.config.set('autosave-plus.includeOnlyRepositoryPath', false)
        initialActiveItem.setText("i am modified")
        advanceClock(initialActiveItem.getBuffer().stoppedChangingDelay)
        expect(initialActiveItem.save).toHaveBeenCalled()

        otherItem.setText("i am modified")
        advanceClock(otherItem.getBuffer().stoppedChangingDelay)
        expect(otherItem.save).toHaveBeenCalled()

  describe "Support autocomplete-plus", ->
    it 'autosave.enabled synchronizes with autosave-plus.enabled', ->
      runs ->
        atom.config.set('autosave-plus.enabled', true)
        expect(atom.config.get('autosave.enabled')).toBe true
        atom.config.set('autosave-plus.enabled', false)

    it 'disable autosave package', ->
      runs ->
        expect(atom.packages.isPackageDisabled('autosave')).toBe true
