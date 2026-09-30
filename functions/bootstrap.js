const existing = require('./index');
const educationGamification = require('./education_gamification');

module.exports = {
  ...existing,
  recordAurenEducationActivity: educationGamification.recordAurenEducationActivity,
  getAurenEducationGamification: educationGamification.getAurenEducationGamification,
  getAurenEducationLeaderboard: educationGamification.getAurenEducationLeaderboard,
};
