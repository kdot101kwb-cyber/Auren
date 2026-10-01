#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const functionsDir = path.join(root, 'functions');

const libraryFiles = [
  'global_library_index.js',
  'unesco_heritage_datahub.js',
  'unesco_heritage_search.js',
  'unesco_world_explorer.js',
  'auren_magazine_index.js',
  'auren_comics_index.js',
  'auren_research_index.js',
  'auren_library_graph.js',
  'auren_unified_library_search.js',
  'auren_library_sources.js',
];

const errors = [];
const warnings = [];

function fail(message) {
  errors.push(message);
}

function read(file) {
  const full = path.join(functionsDir, file);
  if (!fs.existsSync(full)) {
    fail(`Missing library service: functions/${file}`);
    return '';
  }
  return fs.readFileSync(full, 'utf8');
}

function checkSyntax(file, source) {
  try {
    new vm.Script(source, {filename: file});
  } catch (error) {
    fail(`Syntax error in functions/${file}: ${error.message}`);
  }
}

for (const file of libraryFiles) {
  const source = read(file);
  if (source) checkSyntax(file, source);
}

const globalIndex = read('global_library_index.js');
const unified = read('auren_unified_library_search.js');
const sources = read('auren_library_sources.js');

const expectedGlobalExports = [
  'getAurenGlobalLibrarySubjects',
  'searchAurenGlobalLibrary',
  'getAurenGlobalHeritageStories',
  'getAurenGlobalHeritageExplorer',
];

for (const name of expectedGlobalExports) {
  if (!globalIndex.includes(`exports.${name}`)) {
    fail(`Global Library export missing: ${name}`);
  }
}

for (const name of [
  'searchAurenUnifiedLibrary',
]) {
  if (!unified.includes(`exports.${name}`)) {
    fail(`Unified Library export missing: ${name}`);
  }
}

for (const required of [
  'Open Library',
  'Crossref',
  'UNESCO DataHub',
  'Grand Comics Database',
  'Gutendex / Project Gutenberg',
]) {
  if (!sources.includes(required)) {
    fail(`Library source registry missing: ${required}`);
  }
}

const heritageIds = [...globalIndex.matchAll(/id:\s*['"]([^'"]+)['"]/g)]
  .map((match) => match[1])
  .filter((id) => id.startsWith('sudan_') || id.includes('_'));

const duplicateIds = heritageIds.filter(
  (id, index) => heritageIds.indexOf(id) !== index,
);
if (duplicateIds.length) {
  fail(`Duplicate-looking library IDs found: ${[...new Set(duplicateIds)].join(', ')}`);
}

const urlMatches = [
  ...globalIndex.matchAll(/sourceUrl:\s*['"]([^'"]+)['"]/g),
  ...unified.matchAll(/https?:\/\/[^'"]+/g),
  ...sources.matchAll(/url:\s*['"]([^'"]+)['"]/g),
].map((match) => match[1] || match[0]);

for (const url of urlMatches) {
  if (!/^https?:\/\//.test(url)) {
    fail(`Invalid library source URL: ${url}`);
  }
}

if (!fs.existsSync(path.join(root, 'lib/features/entertainment/presentation/auren_books_manga_screen.dart'))) {
  fail('Library UI entry is missing: auren_books_manga_screen.dart');
}

if (fs.existsSync(path.join(root, 'functions/package.json'))) {
  const pkg = JSON.parse(fs.readFileSync(path.join(root, 'functions/package.json'), 'utf8'));
  if (!pkg.scripts || !pkg.scripts.test) {
    warnings.push('functions/package.json has no test script; static library checks still run.');
  }
}

if (errors.length) {
  console.error('AUREN Library CI: FAILED');
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log('AUREN Library CI: PASSED');
console.log(`Checked ${libraryFiles.length} library/backend service files.`);
if (warnings.length) {
  console.log('Warnings:');
  for (const warning of warnings) console.log(`- ${warning}`);
}
