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

  consumeAutosave: ({dontSaveIf}) ->
    dontSaveIf((paneItem) => @isExcludeScope(paneItem?.getGrammar?()?.scopeName))
    dontSaveIf((paneItem) => !@isIncludeOnlyRepositoryPath(paneItem?.getURI?()))

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
