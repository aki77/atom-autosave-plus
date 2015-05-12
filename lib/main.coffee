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
    @subscriptions.add atom.workspace.observeTextEditors (editor) ->
      new Autosave editor
    @simulateAutosave()

  deactivate: ->
    @subscriptions.dispose()

  # support autocomplete-plus
  simulateAutosave: ->
    unless atom.packages.isPackageDisabled('autosave')
      atom.packages.disablePackage('autosave')

    @subscriptions.add atom.config.observe 'autosave-plus.enabled', (enabled) ->
      atom.config.set('autosave.enabled', enabled, save: false)
