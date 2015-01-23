// Generated by CoffeeScript 1.7.1
(function() {
  var ActiveTime, datas, jsonFile, moment, orgId, stat, studentList, userId, yesterday, yesterdayDate;

  require('../server/common/init');

  moment = require('moment');

  ActiveTime = _u.getModel('active_time');

  yesterday = moment().add(-1, 'days').format('YYYY-MM-DD');

  yesterdayDate = new Date(yesterday);

  jsonFile = require("/data/log/budweiser.data.log-" + yesterday + ".json");

  datas = [];

  for (orgId in jsonFile) {
    studentList = jsonFile[orgId];
    for (userId in studentList) {
      stat = studentList[userId];
      datas.push({
        orgId: orgId,
        userId: userId,
        date: yesterdayDate,
        activeTime: stat.beat * Const.BeatTimeSpan + stat.me * Const.MeTimeSpan
      });
    }
  }

  ActiveTime.createQ(datas).then(function(results) {
    console.log(results);
    return process.exit(0);
  }, function(err) {
    console.log(err);
    return process.exit(1);
  });

}).call(this);
