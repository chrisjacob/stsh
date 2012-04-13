((plunker) ->

  sync = (method, model, options = {}) ->
    params = _.extend {}, options,
      url: if _.isFunction(model.url) then model.url() else model.url
      cache: false
      dataType: "json"

    switch method
      when "create"
        params.type = "post"
        params.headers = "Content-Type": "application/json"
        params.data = JSON.stringify(model.toJSON())
      when "read"
        params.type = "get"
      when "update"
        params.type = "post"
        params.headers = "Content-Type": "application/json"
        params.data = JSON.stringify(model.changes)
      when "delete"
        params.type = "delete"

    $.ajax(params)

  class plunker.Plunk extends Backbone.Model
    defaults:
      description: "Untitled"
    sync: sync
    url: -> @get("url") or "//api.#{window.location.hostname}/plunks" + if @id then "/#{@id}" else ""
    initialize: ->
      self = @

      @set "description", "" unless @get("description")
      @set "files", {} unless @get("files")

      @changes = {}
      @on "sync", -> self.changes = {}
      @on "change:description", -> self.changes.description = @get("description")
      @on "change:expires", -> self.changes.expires = @get("expires")
      @on "change:files", ->
        self.changes.files = {}
        self.changes.files[filename] = null for filename, file of self.previous("files")

        _.each self.get("files"), (file, filename) -> if file then self.changes.files[filename] ||= file.content or ""

    getEditUrl: -> "//edit.#{window.location.hostname}/#{@id}"
    getRawUrl: -> "//raw.#{window.location.hostname}/#{@id}"
    getPreviewUrl: -> "//#{window.location.hostname}/#{@id}"

    toViewModel: -> _.defaults @toJSON(),
      url: @url()
      edit_url: @getEditUrl()
      raw_url: @getRawUrl()
      html_url: @getPreviewUrl()



  class plunker.PlunkCollection extends Backbone.Collection
    url: "//api.#{window.location.hostname}/plunks?page=#{@page}&per_page=#{@per_page}"
    model: plunker.Plunk
    comparator: (model) -> -new Cromag(model.get("updated_at") or model.get("created_at")).valueOf()
    sync: sync

    initialize: ->
      @page = 1
      @per_page = 8

    import: (source, options = {}) ->
      self = @

      for name, matcher of plunker.importers
        if matcher.test(source)
          strategy = matcher
          break;

      if strategy
        self.trigger "import:start"
        strategy.import source, (error, json) ->
          json.expires = options.expires if options.expires

          if error then self.trigger "import:fail"
          else self.create json, _.defaults options,
            wait: true
            silent: false
            success: -> self.trigger "import:success"
            error: -> self.trigger "import:fail"
      else
        @trigger "error", "Import error", "The source you provided is not a recognized source."
      @

)(@plunker ||= {})