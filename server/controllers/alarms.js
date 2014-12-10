// Generated by CoffeeScript 1.8.0
var Alarm;

Alarm = require('../models/alarm');

module.exports.fetch = function(req, res, next, id) {
  return Alarm.find(id, function(err, alarm) {
    if (err) {
      return res.send({
        error: err
      }, 500);
    }
    if (!alarm) {
      return res.send({
        error: 'Alarm not found'
      }, 404);
    }
    req.alarm = alarm;
    return next();
  });
};

module.exports.list = function(req, res) {
  return Alarm.request('all', function(err, alarms) {
    if (err) {
      return res.send({
        error: err
      }, 500);
    }
    return res.send(alarms);
  });
};

module.exports.create = function(req, res) {
  delete req.body.id;
  return Alarm.create(req.body, function(err, alarm) {
    if (err) {
      return res.send({
        error: err
      }, 500);
    }
    return res.send(alarm, 201);
  });
};

module.exports.read = function(req, res) {
  return res.send(req.alarm);
};

module.exports.update = function(req, res) {
  return req.alarm.updateAttributes(req.body, function(err, alarm) {
    if (err) {
      return res.send({
        error: err
      }, 500);
    }
    return res.send(alarm, 200);
  });
};

module.exports["delete"] = function(req, res) {
  return req.alarm.destroy(function(err) {
    if (err) {
      return res.send({
        error: err
      }, 500);
    }
    return res.send({
      success: "Alarm destroyed"
    }, 204);
  });
};
