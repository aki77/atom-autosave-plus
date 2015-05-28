_ = require 'underscore-plus'
{CompositeDisposable, Disposable} = require 'atom'

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
    includeOnlyRepositoryPath:
      type: 'boolean'
      default: false

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'autosave-plus.enabled', (enabled) ->
      atom.config.set('autosave.enabled', enabled, save: false)
    @subscriptions.add atom.packages.onDidActivateInitialPackages =>
      @subscriptions.add(@wrapAutosave())

  deactivate: ->
    @subscriptions.dispose()

  wrapAutosave: ->
    pack = atom.packages.enablePackage('autosave')
    pack.activate()
    autosave = pack.mainModule
    original = autosave.autosavePaneItem

    _.adviseBefore(autosave, 'autosavePaneItem', (paneItem) =>
      @autosavePaneItem(paneItem)
    )

    new Disposable( -> autosave.autosavePaneItem = original)

  autosavePaneItem: (paneItem) ->
    return false if @isExcludeScope(paneItem?.getGrammar?()?.scopeName)
    return false unless @isIncludeOnlyRepositoryPath(paneItem?.getURI?())
    return true

  isExcludeScope: (scopeName) ->
    excludeGrammars = atom.config.get('autosave-plus.excludeGrammars')
    excludeGrammars.indexOf(scopeName) isnt -1

  isIncludeOnlyRepositoryPath: (path) ->
    unless atom.config.get('autosave-plus.includeOnlyRepositoryPath')
      return true
    !!@repositoryForPath(path)

  repositoryForPath: (goalPath) ->
    for directory, i in atom.project.getDirectories()
      if goalPath is directory.getPath() or directory.contains(goalPath)
        return atom.project.getRepositories()[i]
    null
