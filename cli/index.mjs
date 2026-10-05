#!/usr/bin/env node
// create-dodox-ios — generates a new iOS app from the scaffold template.
//
//   npx create-dodox-ios@latest                      # interactive
//   npx create-dodox-ios "Baby Leveling" --bundle-id com.dodoxtech.babyleveling --team ABCDE12345 --yes

import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync, copyFileSync } from 'node:fs';
import { dirname, join, relative, resolve } from 'node:path';
import { createInterface } from 'node:readline/promises';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';

const PACKAGE_NAME = 'create-dodox-ios';
const templateDir = join(dirname(fileURLToPath(import.meta.url)), 'template');

const TEXT_EXTENSIONS = new Set([
  '.swift', '.pbxproj', '.xcscheme', '.xcworkspacedata', '.plist', '.entitlements',
  '.storekit', '.json', '.xcstrings', '.md',
]);

// MARK: - Output helpers

const tty = process.stdout.isTTY;
const color = (code) => (s) => (tty ? `\x1b[${code}m${s}\x1b[0m` : s);
const bold = color('1');
const dim = color('2');
const green = color('32');
const cyan = color('36');
const red = color('31');

function fail(message) {
  console.error(`${red('✖')} ${message}`);
  process.exit(1);
}

// MARK: - Validation & derivation

/** "baby leveling" → "BabyLeveling"; used for targets, folders and Swift type prefixes. */
function toTargetName(input) {
  return input
    .split(/[^A-Za-z0-9]+/)
    .filter(Boolean)
    .map((w) => w[0].toUpperCase() + w.slice(1))
    .join('');
}

/** Swift type names declared by the template; a target with the same name would shadow them. */
function reservedNames() {
  const names = new Set(['App', 'Widget', 'SwiftUI', 'Foundation', 'StoreKit', 'WidgetKit', 'Test']);
  const walk = (dir) => {
    for (const entry of readdirSync(dir)) {
      const path = join(dir, entry);
      if (statSync(path).isDirectory()) walk(path);
      else if (path.endsWith('.swift')) {
        for (const m of readFileSync(path, 'utf8').matchAll(/\b(?:struct|class|enum|protocol)\s+([A-Z]\w*)/g)) {
          names.add(m[1]);
        }
      }
    }
  };
  walk(templateDir);
  return names;
}

const validators = {
  displayName(value) {
    if (!value.trim()) return 'App name is required.';
    if (/["\\]/.test(value)) return 'App name cannot contain " or \\.';
    const target = toTargetName(value);
    if (!target) return 'App name must contain at least one letter or digit.';
    if (!/^[A-Za-z]/.test(target)) return 'App name must start with a letter.';
    if (reservedNames().has(target)) return `"${target}" clashes with a type in the template, pick another name.`;
    return null;
  },
  bundleId(value) {
    return /^[A-Za-z][A-Za-z0-9-]*(\.[A-Za-z0-9-]+)+$/.test(value)
      ? null
      : 'Bundle ID must look like com.company.app (letters, digits, hyphens and dots).';
  },
  teamId(value) {
    return value === '' || /^[A-Z0-9]{10}$/.test(value) ? null : 'Team ID is 10 uppercase letters/digits (or leave empty).';
  },
  urlScheme(value) {
    return /^[a-z][a-z0-9+.-]*$/.test(value) ? null : 'URL scheme must start with a letter and use a-z, 0-9, +, . or -.';
  },
};

// MARK: - Arguments & prompts

function parseCLI() {
  const { values, positionals } = parseArgs({
    allowPositionals: true,
    options: {
      'bundle-id': { type: 'string' },
      team: { type: 'string' },
      'url-scheme': { type: 'string' },
      directory: { type: 'string', short: 'd' },
      'no-git': { type: 'boolean', default: false },
      yes: { type: 'boolean', short: 'y', default: false },
      help: { type: 'boolean', short: 'h', default: false },
    },
  });

  if (values.help) {
    console.log(`
${bold(`npx ${PACKAGE_NAME}`)} [app name] [options]

Options
  --bundle-id <id>     Bundle identifier            (default: com.example.<appname>)
  --team <id>          Apple Developer Team ID      (default: empty, set later in Xcode)
  --url-scheme <s>     Deep link URL scheme         (default: <appname>)
  -d, --directory <p>  Output directory             (default: ./<AppName>)
  --no-git             Skip git init
  -y, --yes            Accept defaults for anything not passed
  -h, --help           Show this help
`);
    process.exit(0);
  }
  return { ...values, displayName: positionals[0] };
}

async function ask(rl, label, { initial = '', validate }) {
  for (;;) {
    const hint = initial ? dim(` (${initial})`) : '';
    const answer = (await rl.question(`${cyan('?')} ${bold(label)}${hint} › `)).trim() || initial;
    const error = validate?.(answer);
    if (!error) return answer;
    console.log(`  ${red(error)}`);
  }
}

async function collectOptions(args) {
  const interactive = process.stdin.isTTY && !args.yes;
  const rl = interactive ? createInterface({ input: process.stdin, output: process.stdout }) : null;

  const resolveOption = async (key, label, value, initial) => {
    if (value !== undefined) {
      const error = validators[key](value);
      if (error) fail(error);
      return value;
    }
    if (rl) return ask(rl, label, { initial, validate: validators[key] });
    const error = validators[key](initial);
    if (error) fail(`${error} Pass it explicitly (see --help).`);
    return initial;
  };

  try {
    const displayName = (await resolveOption('displayName', 'App name', args.displayName, '')).trim();
    const name = toTargetName(displayName);
    const lower = name.toLowerCase();
    const bundleId = await resolveOption('bundleId', 'Bundle ID', args['bundle-id'], `com.example.${lower}`);
    const teamId = await resolveOption('teamId', 'Apple Team ID (optional)', args.team, '');
    const urlScheme = await resolveOption('urlScheme', 'Deep link URL scheme', args['url-scheme'], lower);
    return { displayName, name, bundleId, teamId, urlScheme };
  } finally {
    rl?.close();
  }
}

// MARK: - Generation

function render(text, tokens) {
  return text.replace(/__([A-Z_]+)__/g, (match, key) => (key in tokens ? tokens[key] : match));
}

function copyTemplate(dir, outDir, tokens) {
  for (const entry of readdirSync(dir)) {
    const src = join(dir, entry);
    const destName = entry === '_gitignore' ? '.gitignore' : render(entry, tokens);
    const dest = join(outDir, destName);

    if (statSync(src).isDirectory()) {
      mkdirSync(dest, { recursive: true });
      copyTemplate(src, dest, tokens);
      continue;
    }

    const ext = entry.slice(entry.lastIndexOf('.'));
    if (TEXT_EXTENSIONS.has(ext)) {
      const output = render(readFileSync(src, 'utf8'), tokens);
      const leftover = output.match(/__[A-Z_]+__/);
      if (leftover) fail(`Unresolved placeholder ${leftover[0]} in ${relative(templateDir, src)}`);
      writeFileSync(dest, output);
    } else {
      copyFileSync(src, dest);
    }
  }
}

function initGit(outDir) {
  const git = (...args) => execFileSync('git', args, { cwd: outDir, stdio: 'ignore' });
  try {
    git('init', '-q');
    git('add', '-A');
  } catch {
    return 'skipped (git not available)';
  }
  try {
    git('commit', '-q', '-m', `Initial commit from ${PACKAGE_NAME}`);
    return 'initialized with an initial commit';
  } catch {
    return 'initialized (commit skipped — configure git user.name/email)';
  }
}

async function main() {
  const [major] = process.versions.node.split('.').map(Number);
  if (major < 18) fail(`Node.js 18 or newer is required (found ${process.versions.node}).`);
  if (!existsSync(templateDir)) fail('Template not found. Run `npm run build-template` first.');

  const args = parseCLI();
  console.log(`\n${bold('Create a new iOS app')} ${dim(`(${PACKAGE_NAME})`)}\n`);

  const options = await collectOptions(args);
  const outDir = resolve(args.directory ?? options.name);

  if (existsSync(outDir) && readdirSync(outDir).length > 0) {
    fail(`Directory ${relative(process.cwd(), outDir) || '.'} already exists and is not empty.`);
  }
  mkdirSync(outDir, { recursive: true });

  copyTemplate(templateDir, outDir, {
    NAME: options.name,
    DISPLAY_NAME: options.displayName,
    BUNDLE_ID: options.bundleId,
    TEAM_ID: options.teamId,
    URL_SCHEME: options.urlScheme,
  });

  const gitStatus = args['no-git'] ? 'skipped' : initGit(outDir);
  const rel = relative(process.cwd(), outDir) || '.';

  console.log(`
${green('✔')} Created ${bold(options.displayName)} in ${cyan(rel)}

  Target / scheme   ${options.name}  (+ ${options.name}Widget)
  Bundle ID         ${options.bundleId}
  App Group         group.${options.bundleId}
  URL scheme        ${options.urlScheme}://
  Subscriptions     ${options.bundleId}.premium.monthly / .yearly
  Team ID           ${options.teamId || dim('not set — choose a team in Signing & Capabilities')}
  Git               ${gitStatus}

Next steps
  ${cyan(`cd ${rel.includes(' ') ? `"${rel}"` : rel}`)}
  ${cyan(`open ${options.name}.xcodeproj`)}

  See README.md for the architecture and the pre-release checklist.
`);
}

main().catch((error) => {
  if (error?.code === 'ABORT_ERR') process.exit(130); // Ctrl+C during a prompt
  fail(error?.message ?? String(error));
});
