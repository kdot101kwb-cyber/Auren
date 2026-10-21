#!/usr/bin/env node
'use strict';

const { spawnSync } = require('node:child_process');

const REQUIRED = [
  { name: 'git', command: 'git', args: ['--version'], purpose: 'Source control' },
  { name: 'node', command: 'node', args: ['--version'], purpose: 'JavaScript tooling', minimumMajor: 22 },
  { name: 'flutter', command: 'flutter', args: ['--version'], purpose: 'Flutter app development' },
  { name: 'dart', command: 'dart', args: ['--version'], purpose: 'Dart analysis and tests' },
];
const OPTIONAL = [
  { name: 'firebase', command: 'firebase', args: ['--version'], purpose: 'Firebase CLI workflows' },
  { name: 'java', command: 'java', args: ['-version'], purpose: 'Android build toolchain' },
];

function defaultRun(command, args) {
  const result = spawnSync(command, args, { encoding: 'utf8', timeout: 5000, windowsHide: true });
  return {
    status: result.status,
    stdout: result.stdout || '',
    stderr: result.stderr || '',
    error: result.error ? result.error.message : '',
  };
}

function parseMajor(versionOutput) {
  const match = String(versionOutput).match(/v?(\d+)\./);
  return match ? Number(match[1]) : null;
}

function inspectEnvironment({ runCommand = defaultRun, platform = process.platform, env = process.env } = {}) {
  const checks = [];
  for (const item of REQUIRED.concat(OPTIONAL)) {
    let result;
    try {
      result = runCommand(item.command, item.args);
    } catch (error) {
      result = { status: null, stdout: '', stderr: '', error: error.message || 'command failed' };
    }
    const available = result.status === 0;
    const output = [result.stdout, result.stderr].join('\n').trim();
    const major = item.minimumMajor && available ? parseMajor(output) : null;
    let status = available ? 'pass' : (OPTIONAL.includes(item) ? 'optional-missing' : 'missing');
    let note = available ? 'Command responds successfully.' : 'Command unavailable or exited with an error.';
    if (available && item.minimumMajor && major !== null && major < item.minimumMajor) {
      status = 'version-warning';
      note = `Detected major version ${major}; recommended minimum is ${item.minimumMajor}.`;
    } else if (available && item.minimumMajor && major === null) {
      status = 'version-unverified';
      note = 'Command responds, but version output could not be parsed.';
    }
    checks.push({
      name: item.name,
      purpose: item.purpose,
      required: REQUIRED.includes(item),
      status,
      note,
      version: available ? firstVersionLine(output) : null,
    });
  }
  return {
    title: 'AUREN Developer Environment Preflight',
    platform,
    nodeEnvSet: Boolean(env.NODE_ENV),
    checks,
    summary: {
      requiredMissing: checks.filter((x) => x.required && ['missing', 'version-warning'].includes(x.status)).length,
      requiredUnverified: checks.filter((x) => x.required && x.status === 'version-unverified').length,
      optionalMissing: checks.filter((x) => !x.required && x.status === 'optional-missing').length,
    },
    safety: 'Read-only: checks command versions only; does not install, update, configure, or print environment variable values.',
  };
}

function firstVersionLine(output) {
  return String(output).split(/\r?\n/).map((line) => line.trim()).find(Boolean)?.slice(0, 160) || 'version output unavailable';
}

function renderMarkdown(report) {
  const lines = [
    '# ' + report.title,
    '',
    '- Platform: **' + report.platform + '**',
    '- Required tools missing or below recommended version: **' + report.summary.requiredMissing + '**',
    '- Required tool versions unverified: **' + report.summary.requiredUnverified + '**',
    '- Optional tools unavailable: **' + report.summary.optionalMissing + '**',
    '',
    '| Tool | Requirement | Status | Version |',
    '| --- | --- | --- | --- |',
  ];
  for (const check of report.checks) {
    lines.push('| ' + check.name + ' | ' + (check.required ? 'Required' : 'Optional') + ' | ' + check.status + ' | ' + (check.version || '—').replace(/[|\r\n]/g, ' ') + ' |');
  }
  lines.push('', '## Notes', '', report.safety, '', 'This is a preflight hint, not a substitute for the repository CI checks.', '');
  return lines.join('\n');
}

if (require.main === module) {
  const report = inspectEnvironment();
  process.stdout.write(renderMarkdown(report));
  if (report.summary.requiredMissing > 0) process.exitCode = 1;
}

module.exports = { REQUIRED, OPTIONAL, inspectEnvironment, renderMarkdown, parseMajor };
