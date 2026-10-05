#!/usr/bin/env node
// Converts the scaffold app at the repository root into `cli/template/`,
// replacing project-specific identifiers with placeholders that `index.mjs` fills in.
//
// The root app stays the single source of truth: develop it as a normal Xcode project,
// then run `npm run build-template` (also runs automatically on `npm pack` / `npm publish`).

import { execFileSync } from 'node:child_process';
import { cpSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const cliDir = join(dirname(fileURLToPath(import.meta.url)), '..');
const sourceRoot = join(cliDir, '..');
const templateDir = join(cliDir, 'template');

// Identifiers used by the source project.
const SOURCE = {
  name: 'test',
  bundleId: 'dodoxtech.test',
  urlScheme: 'testapp',
  teamId: 'RLNMLDZ56R',
};

const TEXT_EXTENSIONS = new Set([
  '.swift', '.pbxproj', '.xcscheme', '.xcworkspacedata', '.plist', '.entitlements',
  '.storekit', '.json', '.xcstrings', '.md', '.gitignore',
]);

const escapeRegExp = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const word = (s) => new RegExp(`\\b${escapeRegExp(s)}\\b`, 'g');

/** Placeholder substitutions on file contents, in order. */
function tokenize(path, text) {
  const ext = path.slice(path.lastIndexOf('.'));

  text = text
    .replaceAll(SOURCE.bundleId, '__BUNDLE_ID__')
    .replace(/\bTest(?=Widget|App\b)/g, '__NAME__')
    .replace(word(SOURCE.urlScheme), '__URL_SCHEME__')
    .replace(/^\/\/  Created by .*\n\/\/\n/m, '')
    .replace(new RegExp(`^//  ${SOURCE.name}$`, 'm'), '//  __NAME__');

  if (ext === '.pbxproj') {
    text = text
      .replace(/INFOPLIST_KEY_CFBundleDisplayName = Test;/g, 'INFOPLIST_KEY_CFBundleDisplayName = "__DISPLAY_NAME__";')
      .replaceAll(`DEVELOPMENT_TEAM = ${SOURCE.teamId};`, 'DEVELOPMENT_TEAM = "__TEAM_ID__";')
      .replace(word(SOURCE.name), '__NAME__');
  }

  if (ext === '.xcscheme' || path === 'README.md') {
    text = text.replace(word(SOURCE.name), '__NAME__');
  }

  if (path.endsWith('Localization/Localizable.xcstrings')) {
    const catalog = JSON.parse(text);
    for (const loc of Object.values(catalog.strings['app.name'].localizations)) {
      loc.stringUnit.value = '__DISPLAY_NAME__';
    }
    text = JSON.stringify(catalog, null, 2).replace(/": /g, '" : ') + '\n';
  }

  if (path === 'README.md') {
    // Drop the section that documents the generator itself.
    text = text
      .replace(/<!-- cli:start -->[\s\S]*?<!-- cli:end -->\n?/g, '')
      .replace(/^# .*$/m, '# __DISPLAY_NAME__');
  }

  return text;
}

/** Placeholder substitutions on each path segment. */
function tokenizePath(path) {
  return path
    .split('/')
    .map((segment) => segment
      .replace(new RegExp(`^${SOURCE.name}(?=$|\\.(xcodeproj|entitlements|xcscheme)$)`), '__NAME__')
      .replace(/^Test(?=Widget|App)/, '__NAME__'))
    .join('/');
}

function sourceFiles() {
  const out = execFileSync('git', ['ls-files', '--cached', '--others', '--exclude-standard', '-z'], {
    cwd: sourceRoot,
    encoding: 'utf8',
  });
  return out
    .split('\0')
    .filter(Boolean)
    .filter((f) => !f.startsWith('cli/'))
    .filter((f) => !f.includes('xcuserdata/'))
    .filter((f) => !f.endsWith('.DS_Store'))
    .filter((f) => f !== '.gitignore');
}

/** Fails loudly if a source identifier would leak into generated projects. */
function verify(path, text) {
  const leaks = [
    [SOURCE.bundleId, text.includes(SOURCE.bundleId)],
    [SOURCE.teamId, text.includes(SOURCE.teamId)],
    ['TestWidget/TestApp', /\bTest(Widget|App)\b/.test(text)],
  ];
  if (/\.(pbxproj|xcscheme)$/.test(path)) leaks.push([`"${SOURCE.name}"`, word(SOURCE.name).test(text)]);
  for (const [what, found] of leaks) {
    if (found) throw new Error(`Template still contains ${what} in ${path}`);
  }
}

rmSync(templateDir, { recursive: true, force: true });
mkdirSync(templateDir, { recursive: true });

let count = 0;
for (const file of sourceFiles()) {
  const target = join(templateDir, tokenizePath(file));
  mkdirSync(dirname(target), { recursive: true });

  const ext = file.slice(file.lastIndexOf('.'));
  if (TEXT_EXTENSIONS.has(ext)) {
    const text = tokenize(file, readFileSync(join(sourceRoot, file), 'utf8'));
    verify(file, text);
    writeFileSync(target, text);
  } else {
    cpSync(join(sourceRoot, file), target);
  }
  count++;
}

// npm strips `.gitignore` from published packages, so ship it under another name.
cpSync(join(cliDir, 'scripts', 'project.gitignore'), join(templateDir, '_gitignore'));

console.log(`✔ Built template with ${count} files → ${relative(process.cwd(), templateDir) || '.'}`);
