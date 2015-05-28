path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'

describe "AutosavePlus", ->
  [workspaceElement, activationPromise, initialActiveItem, projectPath,
   otherPath] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    projectPath = temp.mkdirSync('autosave-plus-spec-')
    otherPath = temp.mkdirSync('some-other-path-')
    fs.copySync(path.join(__dirname, 'fixtures', 'working-dir'), projectPath)
    fs.moveSync(path.join(projectPath, 'git.git'), path.join(projectPath, '.git'))
    atom.project.setPaths([otherPath, projectPath])

    atom.config.set('autosave-plus.excludeGrammars', ['text.git-commit'])
    atom.config.set('autosave-plus.enabled', true)

    waitsForPromise ->
      atom.packages.activatePackage('autosave-plus')

    waitsForPromise ->
      atom.workspace.open(path.join(projectPath, 'sample.coffee'))

    waitsForPromise ->
      atom.packages.activatePackage('language-coffee-script')

    waitsForPromise ->
      atom.packages.activatePackage('language-git')

    runs ->
      atom.packages.emitter.emit 'did-activate-initial-packages'
      initialActiveItem = atom.workspace.getActiveTextEditor()
      spyOn(initialActiveItem, 'save')

  describe "Settings excludeGrammars", ->
    [commitMsgItem] = []

    beforeEach ->
      waitsForPromise ->
        atom.workspace.open(path.join(projectPath, 'COMMIT_EDITMSG'))
      runs ->
        commitMsgItem = atom.workspace.getActiveTextEditor()
        spyOn(commitMsgItem, 'save').andCallThrough()

    it "does not save the item", ->
      commitMsgItem.setText("i am modified")
      window.dispatchEvent(new FocusEvent('blur'))
      expect(commitMsgItem.save).not.toHaveBeenCalled()

    it "save the item", ->
      atom.config.set('autosave-plus.excludeGrammars', [])
      commitMsgItem.setText("i am modified")
      window.dispatchEvent(new FocusEvent('blur'))
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
      atom.config.set('autosave-plus.includeOnlyRepositoryPath', true)
      initialActiveItem.setText("i am modified")
      window.dispatchEvent(new FocusEvent('blur'))
      expect(initialActiveItem.save).toHaveBeenCalled()

    it "done not save the other item", ->
      atom.config.set('autosave-plus.includeOnlyRepositoryPath', true)
      otherItem.setText("i am modified")
      window.dispatchEvent(new FocusEvent('blur'))
      expect(otherItem.save).not.toHaveBeenCalled()

    it "save all item", ->
      atom.config.set('autosave-plus.includeOnlyRepositoryPath', false)
      initialActiveItem.setText("i am modified")
      window.dispatchEvent(new FocusEvent('blur'))
      expect(initialActiveItem.save).toHaveBeenCalled()

      otherItem.setText("i am modified")
      window.dispatchEvent(new FocusEvent('blur'))
      expect(otherItem.save).toHaveBeenCalled()
