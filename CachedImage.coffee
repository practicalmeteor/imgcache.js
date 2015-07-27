log = new ObjectLogger('CachedImage', 'info')

class lv.client.CachedImage extends lv.DbObject

  constructor: (coll, data)->
    try
      log.enter("constructor")
      super(coll, data, true)
    finally
      log.return()


  cacheImage: (cb)->
    try
      log.enter 'cacheImage'
      expect(cb).to.be.a('function')
      @cb = cb
      window.ImgCache.cacheFile(@data.src, @onCacheSuccess, @onCacheError)
    finally
      log.return()


  onCacheSuccess: (url, entry)=>
    try
      log.enter 'onCacheSuccess', arguments
      expect(entry).to.be.ok
      if window.wkwebview?
        expect(entry.nativeURL).to.be.ok
        expect(entry.nativeURL).to.startsWith 'file://'
        @data.cachedSrc = entry.nativeURL.substr(7)
      else
        @data.cachedSrc = window.ImgCache.Helpers.EntryGetURL(entry)

      log.debug 'cachedSrc:', @data.cachedSrc
      @save()
      @cb(undefined, @data)
#      @cached.set(true)
    finally
      log.return()


  onCacheError: (error)=>
    try
      log.enter 'onCacheError'
      log.error 'Error:', error
      @cb(arguments, @data)
    finally
      log.return()


  removeImage: (cb)->
    try
      log.enter 'removeImage'
      expect(cb).to.be.a('function')
      @removeCb = cb
      window.ImgCache.removeFile(@data.src, @onRemoveSuccess, @onRemoveError)
    finally
      log.return()


  onRemoveSuccess: =>
    try
      log.enter 'onRemoveSuccess', arguments
      numOfDocs = @coll.remove({_id: @data._id})
      expect(numOfDocs).to.equal 1
      @cb(undefined, @data)
    finally
      log.return()


  onRemoveError: (error)=>
    try
      log.enter 'onCacheError'
      log.error 'Error:', error
      error ?= new Error('Error: Unknown error while removing ImgCache file')
      @cb(error, @data)
    finally
      log.return()
