{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'

module.exports =
  class Autosave
    constructor: (@editor) ->
      @subscriptions = new CompositeDisposable

      @subscriptions.add atom.config.observe 'autosave-plus.debouncePeriod', (wait) =>
        @debouncedSave = _.debounce @_save.bind(@), wait

      @subscriptions.add @editor.onDidStopChanging(@changeHandler)

    _save: ->
      return unless atom.config.get 'autosave-plus.enabled'
      return unless @editor.getURI?()?
      return unless @editor.isModified?()
      return if @isExcludeScope @editor.getGrammar?()?.scopeName
      return unless @isIncludeOnlyRepositoryPath @editor.getPath()
      @editor.save()

    changeHandler: =>
      @debouncedSave()

    destroy: =>
      @subscriptions.dispose()

    isExcludeScope: (scopeName) ->
      excludeGrammars = atom.config.get 'autosave-plus.excludeGrammars'
      excludeGrammars.indexOf(scopeName) > -1

    isIncludeOnlyRepositoryPath: (path) ->
      return true unless atom.config.get 'autosave-plus.includeOnlyRepositoryPath'
      !!@repositoryForPath path

    repositoryForPath: (goalPath) ->
      for directory, i in atom.project.getDirectories()
        if goalPath is directory.getPath() or directory.contains(goalPath)
          return atom.project.getRepositories()[i]
      null
