log = new ObjectLogger('ImgCache', 'info')

class lv.client.ImgCache extends lv.CollectionWrapper

  instance = null

  @get: ->
    instance ?= new lv.client.ImgCache()


  constructor: ->
    try
      log.enter('constructor')
      @available = false
      @ready = new ReactiveVar(false)

      if lv.Settings.isOfflineEnabled() isnt true
        log.info 'Offline mode disabled, skipping image cache initialization.'
        @ready.set(true)
        return

      # Write log to console

      @imgCache = window.ImgCache
      @imgCache.options.debug = true

      # Increase allocated space on Chrome to 50MB, default was 10MB
      @imgCache.options.chromeQuota = 50*1024*1024

      @coll = new Ground.Collection 'images', { connection: null }

      @clearImgCache = lv.URLParams.getParam('clearImgCache')
    finally
      log.return()


  isReady: =>
    return @ready.get()


  init: ->
    try
      log.enter 'init'
      return if @ready.get() is true
      log.info 'Initializing image cache...'
      if Meteor.isCordova
        document.addEventListener "deviceready", @_init, false
      else
        @_init()
    finally
      log.return()


  _init: =>
    try
      log.enter '_init'
      @imgCache.init(@onInitSuccess, @onInitError)
    finally
      log.return()


  onInitSuccess: =>
    try
      log.enter 'onInitSuccess', arguments
      log.info 'Image cache initialized.'
      @available = true
      if @clearImgCache?
        # TODO: Provide onSuccess and onError function and wait to execute next step below in onSuccess
        @clearCache()
      else
        @ready.set(true)
    finally
      log.return()


  onInitError: =>
    try
      log.enter 'onInitError', arguments
      log.error 'Error:', arguments
      @ready.set(true)
    finally
      log.return()


  clearCache: ->
    try
      log.enter 'clear'
      numOfDocs = @coll.remove({})
      log.info "Removed #{numOfDocs} documents from cached collection. Removing cached files..."
      @imgCache.clearCache(@onClearCacheSuccess, @onClearCacheError)
    finally
      log.return()


  onClearCacheSuccess: =>
    try
      log.enter 'onClearCacheSuccess'
      log.info "Removed all cached image files."
      @ready.set(true)
    finally
      log.return()


  onClearCacheError: =>
    try
      log.enter 'onClearCacheError', arguments
      log.error 'Error:', arguments
    finally
      log.return()


  onGetCachedFileURLSuccess: (url, cachedUrl)=>
    try
      log.enter 'onGetCachedFileURLSuccess', arguments
      expect(url).to.be.a('string').that.is.ok
      expect(cachedUrl).to.be.a('string').that.is.ok
      count = @coll.update( {url: url}, { $set: {cachedUrl: cachedUrl} } )
      expect(count).to.equal(1)
    finally
      log.return()


  onGetCachedFileURLError: (url)=>
    try
      log.enter 'onGetCachedFileURLError', arguments
      # url is not cached apparently, let's cache it
      @cacheImage(url)
    finally
      log.return()


  # @return Number of images that need to be cached.
  cacheImages: (images)->
    try
      log.enter 'cacheImages'
      @imagesToCache = []
      expect(images).to.be.an('array')
      for img in images
        expect(img._id).to.be.a('string').that.is.ok
        expect(img.src).to.be.a('string').that.is.ok
        cachedImg = @coll.findOne({_id: img._id})
        log.debug 'cachedImg:', cachedImg
        if not cachedImg?
          @imagesToCache.push img
        else
          expect(cachedImg.cachedSrc).to.be.ok
          if img.src isnt cachedImg.src
#            The src / url changed for the same id, we need to cache it again
            log.warn "Image #{img._id} src changed, re-caching it."
            numOfDocs = @coll.remove({_id: cachedImg._id})
            expect(numOfDocs).to.equal 1
            @imagesToCache.push img
          else
            img.cachedSrc = cachedImg.cachedSrc

      return 0 if @imagesToCache.length is 0

      @imageCachingProgress = new ReactiveVar(0)

      totalImagesToCache = @imagesToCache.length

      @cacheNextImage()

      return totalImagesToCache
    finally
      log.return()


  cacheNextImage: ->
    try
      log.enter 'cacheNextImage'
      return if @imagesToCache.length is 0
      imgToCacheData = @imagesToCache.shift()
      @currentImgToCache = new lv.client.CachedImage(@coll, imgToCacheData)
      @currentImgToCache.cacheImage(@cacheImageCB)
    finally
      log.return()


  getImageSrc: (imgDoc)->
    try
      log.enter 'getImageSrc'
      expect(imgDoc).to.be.an('object').that.include.keys ['_id', 'src']
      return imgDoc.src if @available isnt true

      img = @coll.findOne { _id: imgDoc._id }

      # if image src not cached yet, we send the remote src
      if img? then img.cachedSrc else imgDoc.src
    finally
      log.return()


  cacheImageCB: (error, data)=>
    try
      log.enter 'cacheImageCB'
      return if error?
      progress = @imageCachingProgress.get() + 1
      log.info 'progress: ', progress
      @imageCachingProgress.set(progress)
      @cacheNextImage()
    finally
      log.return()


  getCachingProgress: =>
    return @imageCachingProgress.get()


  cacheImage: (url)->
    try
      log.enter 'cacheImage', url
      @imgCache.cacheFile(url, @onCacheSuccess, @onCacheError)
    finally
      log.return()


  onCacheSuccess: (url, entry)=>
    try
      log.enter 'onCacheSuccess', arguments
      expect(entry).to.be.ok
      cachedUrl = @imgCache.Helpers.EntryGetURL(entry)
      log.debug 'cachedUrl:', cachedUrl
      count = @coll.update( { url: url }, { $set: {cachedUrl: cachedUrl} } )
      expect(count).to.equal(1)
    finally
      log.return()


  onCacheError: =>
    try
      log.enter 'onCacheError', arguments
      log.info 'ImgCache caching error:', arguments
    finally
      log.return()


  removeImages: (numOfImagesToRemove)->
    try
      log.enter 'removeImages', numOfImagesToRemove
      expect(numOfImagesToRemove).to.be.above 0
      imgs = @find {}, {limit: numOfImagesToRemove}, lv.client.CachedImage
      log.info imgs.length
      for img in imgs
        img.removeImage @_removeImageCb
    finally
      log.return()


  _removeImageCb: (data, error)=>
    try
      log.enter 'removeImageCb', arguments
      log.info arguments
    finally
      log.return()


lv.ImgCache = lv.client.ImgCache.get()
lv.ImgCache.init()
