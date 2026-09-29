class EducationResourceCatalog {
  static const resourceTypes = <String>['Videos','Books','Interactive Simulations','Labs & Practice','Courses','Open Textbooks','Research & References','Projects'];
  static const languages = <String>['العربية','English','Français','Español','Português','Deutsch','Italiano','Türkçe','中文','日本語','한국어','हिन्दी','বাংলা','اردو','فارسی','Bahasa Indonesia','Bahasa Melayu','Русский','Українська','Polski','Nederlands','Svenska','Norsk','Dansk','Suomi','Čeština','Ελληνικά','עברית','ไทย','Tiếng Việt','Kiswahili','አማርኛ','Yorùbá','Igbo','isiZulu','Hausa'];
  static const resources = <Map<String, String>>[
    {'name':'Khan Academy','type':'Videos + Practice','languages':'Many languages','subjects':'Math, Science, Computing, History, Test Prep','license':'Provider terms','url':'https://www.khanacademy.org/'},
    {'name':'MIT OpenCourseWare','type':'Courses + Books + Materials','languages':'English','subjects':'Science, Engineering, Computing, Business, Humanities','license':'Open course materials','url':'https://ocw.mit.edu/'},
    {'name':'MIT BLOSSOMS','type':'Science & Math Videos','languages':'Arabic, English, Farsi, Hindi, Japanese, Korean, Malay, Mandarin, Portuguese, Spanish, Urdu','subjects':'Math, Science','license':'Open educational resource','url':'https://blossoms.mit.edu/'},
    {'name':'OpenStax','type':'Open Textbooks','languages':'English, Spanish, Polish','subjects':'Math, Science, Computing, Business, Social Science','license':'Openly licensed textbooks','url':'https://openstax.org/'},
    {'name':'LibreTexts','type':'Open Textbooks + Courseware','languages':'English, Spanish','subjects':'Chemistry, Biology, Physics, Math, Engineering, Social Science','license':'Open educational resources','url':'https://libretexts.org/'},
    {'name':'PhET Interactive Simulations','type':'Interactive Simulations','languages':'65+ languages','subjects':'Physics, Chemistry, Biology, Earth Science, Math','license':'CC BY 4.0 + open source components','url':'https://phet.colorado.edu/'},
    {'name':'UNESCO OpenLearning','type':'Courses + Resources','languages':'Arabic, English, French, Spanish + UN languages','subjects':'Natural Sciences, Education, Culture, Communication','license':'Open/free courses','url':'https://openlearning.unesco.org/'},
    {'name':'Wikibooks','type':'Books + Learning Materials','languages':'Many languages','subjects':'Science, Computing, Languages, Humanities, Vocational','license':'Open knowledge','url':'https://www.wikibooks.org/'},
    {'name':'Wikiversity','type':'Courses + Study Materials','languages':'Many languages','subjects':'Academic and vocational subjects','license':'Open knowledge','url':'https://www.wikiversity.org/'},
    {'name':'KOCW','type':'University Lectures','languages':'Korean','subjects':'University disciplines','license':'Open courseware','url':'https://www.kocw.net/'},
    {'name':'Pressbooks Directory','type':'Open Books','languages':'Many languages','subjects':'Academic and professional subjects','license':'Open publishing catalog','url':'https://pressbooks.directory/'},
    {'name':'Virtu-WIL / Simulation Canada','type':'Virtual Simulations','languages':'English, French','subjects':'Healthcare education','license':'Provider-dependent','url':'https://www.simulationcanada.ca/'},
    {'name':'UNESCO-UNEVOC','type':'Videos + Vocational Resources','languages':'English, French + regional resources','subjects':'Vocational, trades, skills','license':'Provider-dependent/open resources','url':'https://unevoc.unesco.org/'},
    {'name':'European Schoolnet Academy','type':'Courses','languages':'Many European languages','subjects':'Education and professional development','license':'Free courses','url':'https://www.europeanschoolnetacademy.eu/'},
    {'name':'VOCEDplus','type':'Research + TVET Resources','languages':'English','subjects':'Vocational education, skills, workforce research','license':'Resource-dependent','url':'https://www.ncver.edu.au/vocedplus'},
  ];
}
