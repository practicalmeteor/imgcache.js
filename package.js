Package.describe({
  name: 'practicalmeteor:imgcache',
  version: '0.0.1',
  // Brief, one-line summary of the package.
  summary: '',
  // URL to the Git repository containing the source code for this package.
  git: '',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});


Cordova.depends({
  'org.apache.cordova.device': '0.3.0',
  'org.apache.cordova.file-transfer': '0.5.0',
  'org.apache.cordova.file': '1.3.3'
});



Package.onUse(function(api) {
  api.use(['coffeescript', 'meteor', 'reactive-var', 'tracker', 'practicalmeteor:loglevel'], 'client');
  api.use('ground:db', 'client');
  api.use(['lavaina-base'], 'client');

  api.addFiles('ImgCache.js', 'client');
  api.addFiles('CachedImage.coffee', 'client');
  api.addFiles('ImgCache.coffee', 'client');
});

Package.onTest(function(api) {
  api.use(['coffeescript', 'practicalmeteor:munit']);
  api.use(['imgcache']);

  api.addFiles(['ImgCacheTest.coffee'], 'client');
});
