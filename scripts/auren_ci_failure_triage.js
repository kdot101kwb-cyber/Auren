#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const path = require('node:path');

const RULES = [
  { id: 'dart-compile', label: 'Dart/Flutter compile errors', pattern: /(?:Error:|\berror:|Compilation failed|Could not compile)/i },
  { id: 'flutter-test', label: 'Flutter test failures', pattern: /(?:Some tests failed|\[E\] .*Exception|Expected:.*Actual:|Test failed)/i },
  { id: 'node-test', label: 'Node test failures', pattern: /(?:not ok \d+|\bfail(?:ed|ure)?\b.*(?:test|assert)|AssertionError)/i },
  { id: 'gradle-build', label: 'Android/Gradle build failures', pattern: /(?:Gradle task .* failed|BUILD FAILED|Execution failed for task|Could not resolve all files)/i },
  { id: 'dependency', label: 'Dependency resolution failures', pattern: /(?:version solving failed|pub get failed|npm ERR!|Unable to resolve dependency|Package .* not found)/i },
  { id: 'firebase-permission', label: 'Firebase/Firestore permission failures', pattern: /(?:permission-denied|Missing or insufficient permissions|PERMISSION_DENIED)/i },
  { id: 'network-timeout', label: 'Network/timeout failures', pattern: /(?:ETIMEDOUT|ECONNRESET|SocketException|timed out|TimeoutException)/i },
  { id: 'missing-plugin', label: 'Missing platform plugin / channel', pattern: /(?:MissingPluginException|No implementation found for method)/i },
];

function listLogFiles(root) {
  if (!fs.existsSync(root)) return [];
  const results = [];
  const visit = (dir) => {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) visit(full);
      else if (entry.isFile() && /\.(?:log|txt)$/i.test(entry.name)) results.push(full);
    }
  };
  visit(root);
  return results.sort();
}

function analyzeLogs(root) {
  const files = listLogFiles(root);
  const totals = new Map(RULES.map((rule) => [rule.id, 0]));
  const perFile = [];
  for (const file of files) {
    let content;
    try {
      content = fs.readFileSync(file, 'utf8');
    } catch {
      continue;
    }
    const matches = [];
    for (const rule of RULES) {
      const count = content.split(/\r?\n/).filter((line) => rule.pattern.test(line)).length;
      if (count > 0) {
        totals.set(rule.id, totals.get(rule.id) + count);
        matches.push({ id: rule.id, label: rule.label, count });
      }
    }
    if (matches.length) {
      perFile.push({ file: path.relative(root, file).split(path.sep).join('/'), matches });
    }
  }
  return {
    filesScanned: files.length,
    filesWithSignals: perFile.length,
    categories: RULES.map((rule) => ({ ...rule, count: totals.get(rule.id) })).filter((rule) => rule.count > 0),
    perFile,
  };
}

function renderReport({ workflowName = 'Unknown workflow', conclusion = 'unknown', runUrl = '', root = 'diagnostics' }) {
  const result = analyzeLogs(root);
  const lines = [
    '# AUREN CI Failure Triage',
    '',
    `- Workflow: **${safeText(workflowName)}**`,
    `- Original workflow conclusion: **${safeText(conclusion)}**`,
    runUrl ? `- Run: ${safeUrl(runUrl)}` : '- Run: not supplied',
    `- Log files scanned: **${result.filesScanned}**`,
    `- Files with diagnostic signals: **${result.filesWithSignals}**`,
    '',
    '## Diagnostic categories',
    '',
  ];
  if (!result.categories.length) {
    lines.push('No known failure patterns were found in the available log artifacts. This does not prove the run was healthy or that logs were complete.');
  } else {
    lines.push('| Category | Signal count |', '| --- | ---: |');
    for (const category of result.categories) lines.push(`| ${category.label} | ${category.count} |`);
    lines.push('', '## Files containing signals', '');
    for (const item of result.perFile) {
      lines.push(`- \`${safeText(item.file)}\`: ${item.matches.map((match) => `${match.label} (${match.count})`).join('; ')}`);
    }
  }
  lines.push(
    '',
    '## Limits and safety',
    '',
    '- This report counts known log patterns; it does not identify a root cause or modify the original workflow result.',
    '- Raw log lines are deliberately omitted to reduce the risk of exposing secrets or personal data.',
    '- Missing artifacts and unknown failure patterns can produce an incomplete or empty report.',
    '- Review the original run and relevant source/tests before changing code.',
    '',
  );
  return lines.join('\n');
}

function safeText(value) {
  return String(value).replace(/[\r\n|]/g, ' ').replace(/\*\*/g, '').slice(0, 300);
}

function safeUrl(value) {
  try {
    const parsed = new URL(value);
    if (parsed.protocol !== 'https:' || parsed.hostname !== 'github.com') return 'URL omitted (not a GitHub HTTPS URL)';
    return `[${parsed.pathname.replace(/[^a-zA-Z0-9/_-]/g, '')}](${parsed.href})`;
  } catch {
    return 'URL omitted (invalid)';
  }
}

if (require.main === module) {
  const root = process.env.AUREN_DIAGNOSTICS_DIR || 'diagnostics';
  const report = renderReport({
    root,
    workflowName: process.env.AUREN_WORKFLOW_NAME || 'Unknown workflow',
    conclusion: process.env.AUREN_WORKFLOW_CONCLUSION || 'unknown',
    runUrl: process.env.AUREN_WORKFLOW_RUN_URL || '',
  });
  process.stdout.write(report);
}

module.exports = { RULES, analyzeLogs, listLogFiles, renderReport };
