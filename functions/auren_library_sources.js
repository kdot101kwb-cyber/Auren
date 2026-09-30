const {onCall,HttpsError}=require('firebase-functions/v2/https');
const SOURCES=[
 {id:'openlibrary',name:'Open Library',type:'Books',license:'Public catalog metadata',url:'https://openlibrary.org/'},
 {id:'crossref',name:'Crossref',type:'Research',license:'Metadata services',url:'https://www.crossref.org/'},
 {id:'unesco',name:'UNESCO DataHub',type:'Heritage',license:'CC BY-SA 4.0',url:'https://data.unesco.org/'},
 {id:'gcd',name:'Grand Comics Database',type:'Comics',license:'Catalog/source index',url:'https://www.comics.org/'},
 {id:'gutendex',name:'Gutendex / Project Gutenberg',type:'Public-domain books',license:'Varies by work',url:'https://gutendex.com/'},
];
exports.getAurenLibrarySources=onCall({region:'us-central1'},async(req)=>{
 if(!req.auth)throw new HttpsError('unauthenticated','Sign in required.');
 return {sources:SOURCES,rightsPrinciples:['Prefer original/licensed/open metadata','Link to source rather than mirror protected files','Display attribution and license when available','Keep uncertain rights marked as unknown'],lastChecked:new Date().toISOString()};
});
