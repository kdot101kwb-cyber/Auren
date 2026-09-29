'use strict';

const {onCall}=require('firebase-functions/v2/https');

exports.aurenGlobalCountryRegistry = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  return {status:'ok', source:'world_bank_wdi', message:'Country registry ingestion endpoint is enabled.'};
});
