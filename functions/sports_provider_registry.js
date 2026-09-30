'use strict';

exports.AUREN_SPORTS_PROVIDER_REGISTRY = [
  {
    id:'api_football',
    name:'API-Football',
    scope:'Football',
    trust:'official provider API',
    requiresKey:true,
    sourceUrl:'https://www.api-football.com/'
  },
  {
    id:'the_sports_db',
    name:'TheSportsDB',
    scope:'Multi-sport metadata, schedules and events',
    trust:'official provider API',
    requiresKey:true,
    sourceUrl:'https://www.thesportsdb.com/api.php'
  },
];
