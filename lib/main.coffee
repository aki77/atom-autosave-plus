{CompositeDisposable, Disposable} = require 'atom'
Autosave = require './autosave'

module.exports =
  config:
    enabled:
      type: 'boolean'
      default: true
    excludeGrammars:
      type: 'array'
      default: ['text.git-commit']
      items:
        type: 'string'
    debouncePeriod:
      type: 'integer'
      default: 1000
    includeOnlyRepositoryPath:
      type: 'boolean'
      default: true

  activate: ->
    @subscriptions = new CompositeDisposable
    @autosaveObjects = new WeakMap
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      @autosaveObjects.set(editor, new Autosave(editor))

    @subscriptions.add atom.packages.onDidActivateInitialPackages =>
      @subscriptions.add(@wrapWhitespace())

    @simulateAutosave()

  deactivate: ->
    @subscriptions.dispose()
    @subscriptions = null

    atom.workspace.getTextEditors().forEach((editor) =>
      @autosaveObjects.get(editor)?.destroy()
    )
    @autosaveObjects = null

  # support autocomplete-plus
  simulateAutosave: ->
    unless atom.packages.isPackageDisabled('autosave')
      atom.packages.disablePackage('autosave')

    @subscriptions.add atom.config.observe 'autosave-plus.enabled', (enabled) ->
      atom.config.set('autosave.enabled', enabled, save: false)

  wrapWhitespace: ->
    pack = atom.packages.getLoadedPackage('whitespace')
    return new Disposable unless pack
    whitespace = pack.mainModule.whitespace
    ensureSingleTrailingNewline = whitespace.ensureSingleTrailingNewline

    whitespace.ensureSingleTrailingNewline = (editor) ->
      buffer = editor.getBuffer()
      lastRow = buffer.getLastRow()
      cursorRows = (cursor.getBufferRow() for cursor in editor.getCursors())
      return if lastRow in cursorRows
      ensureSingleTrailingNewline(editor)

    new Disposable ->
      whitespace.ensureSingleTrailingNewline = ensureSingleTrailingNewline
