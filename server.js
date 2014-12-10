// Generated by CoffeeScript 1.8.0
var Note, RealtimeAdapter, americano;

americano = require('americano');

RealtimeAdapter = require('cozy-realtime-adapter');

Note = require('./server/models/note');

americano.start({
  name: 'Notes',
  port: process.env.PORT || 9201
}, function(app, server) {
  RealtimeAdapter({
    server: server
  }, ['note.*', 'task.*', 'alarm.*', 'contact.*']);
  return Note.patchAllPathes(function(err) {
    if (err) {
      console.log("Failled to patch notes");
      console.log(err.stack);
      return process.exit(1);
    }
  });
});
