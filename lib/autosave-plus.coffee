{CompositeDisposable, Disposable} = require 'atom'
Autosave = require './autosave'

module.exports =
  config:
    enabled:
      type: 'boolean'
      default: false
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

  subscriptions: null

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      autosave = new Autosave editor
      disposable = new Disposable -> autosave.destroy()
      @subscriptions.add editor.onDidDestroy -> disposable.dispose()
      @subscriptions.add disposable

    # support autocomplete-plus
    atom.packages.disablePackage('autosave')
    @subscriptions.add atom.config.observe 'autosave-plus.enabled', (enabled) ->
      atom.config.set('autosave.enabled', enabled, save: false)

  deactivate: ->
    @subscriptions.dispose()
