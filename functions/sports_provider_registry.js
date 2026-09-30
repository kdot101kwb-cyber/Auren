'use strict';

exports.AUREN_SPORTS_PROVIDER_REGISTRY = [
  {
    id:'api_sports',
    name:'API-Sports',
    scope:'Multi-sport structured data, fixtures, leagues, teams, standings and player data where supported',
    trust:'official provider API',
    requiresKey:true,
    sourceUrl:'https://api-sports.io/'
  },
  {
    id:'the_sports_db',
    name:'TheSportsDB',
    scope:'Multi-sport metadata, schedules and events',
    trust:'community sports database',
    requiresKey:true,
    sourceUrl:'https://www.thesportsdb.com/api.php'
  },
];
