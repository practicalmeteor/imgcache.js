log = new ObjectLogger("ImgCacheTest")


class ImgCacheTest

  self = @

  if Meteor.isClient
    imgCache = window.ImgCache

  suiteSetup: (test)=>
    try
      log.enter "suiteSetup"
    finally
      log.return()

  suiteTearDown: (test)->
    try
      log.enter "suiteTearDown"
    finally
      log.return()

  setup: ->
    try
      log.enter "setup"
      if Meteor.isClient
        imgCache.clearCache()
      else
        lv.ImgCache = {}
    finally
      log.return()

  tearDown: ->
    try
      log.enter "tearDown"
      stubs.restoreAll()
      spies.restoreAll()
    finally
      log.return()

  tests:[
    {
      name: "Ground.Collection - reproduce bug"
      func:(test)=>
        try
          log.enter("Ground.Collection - reproduce bug")
          if Meteor.isServer
            lv.ImgCache.coll = new Mongo.Collection('testImages')
          lv.ImgCache.coll.remove({})
          expect(lv.ImgCache.coll.find().count()).to.equal(0)
          url = 'http://storage.googleapis.com/menuapp/public/c1.jpg'
          id = lv.ImgCache.coll.insert({url: url})
          expect(lv.ImgCache.coll.find().count()).to.equal(1)
          expect(id).to.be.a('string').that.is.ok
          img = lv.ImgCache.coll.findOne({url: url})
          expect(img).to.be.an('object').that.has.property('url')
          cachedUrl = 'localhost:http://storage.googleapis.com/menuapp/public/c1.jpg'
          expect(lv.ImgCache.coll.update({url: url}, {$set: {cachedUrl: cachedUrl}})).to.equal(1)
          img = lv.ImgCache.coll.findOne({url: url})
          expect(img, 'updated img').to.be.an('object').that.contain.keys(['url', 'cachedUrl'])
        finally
          log.return()
    }
  ]


try
  Munit.run(new ImgCacheTest())
catch err
  log.error(err.stack)
