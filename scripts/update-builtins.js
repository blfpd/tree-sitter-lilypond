#!/usr/bin/env node
/**
 * Regenerate the parts of the grammar and of the queries that list what
 * LilyPond defines in its own files, as opposed to its syntax:
 *
 * - the markup commands with their signatures (src/markup_commands.h, read by
 *   the external scanner, and MARKUP_SIGNATURES in grammar.js);
 * - the identifiers defined in ly/*.ly, sorted by type (music functions,
 *   predefined music, dynamics, articulations, context modifications, …), in
 *   queries/highlights.scm;
 * - the same for the optional packages that a score has to \include, such as
 *   bagpipe.ly or arabic.ly, in a separate section.
 *
 * Usage: node scripts/update-builtins.js   (needs `lilypond` in PATH, or set
 * the LILYPOND environment variable)
 */

import {execFileSync} from 'node:child_process';
import {mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname, join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const LILYPOND = process.env.LILYPOND ?? 'lilypond';
const INTROSPECT = join(ROOT, 'scripts', 'introspect.ly');

// Optional packages whose vocabulary is worth highlighting. Templates
// (*-tkit.ly, satb.ly), interactive helpers (scheme-sandbox.ly, …) and the
// pitch name languages are left out.
const PACKAGES = [
  'arabic.ly',
  'articulate.ly',
  'bagpipe.ly',
  'hel-arabic.ly',
  'makam.ly',
  'persian.ly',
  'swing.ly',
  'turkish-makam.ly',
];

// How each type of identifier is highlighted.
const CAPTURES = {
  'music-function': '@function.builtin',
  'event-function': '@function.builtin',
  'scheme-function': '@function.builtin',
  'void-function': '@function.builtin',
  'markup-command': '@function.builtin',
  'music': '@constant.builtin',
  'markup': '@constant.builtin',
  'duration': '@constant.builtin',
  'pitch': '@constant.builtin',
  'scale': '@constant.builtin',
  'dynamic': '@attribute.builtin',
  'articulation': '@attribute.builtin',
  'post-event': '@attribute.builtin',
  'context-mod': '@type.builtin',
  'context-def': '@type.builtin',
};

// Names that only make sense as `\name` in LilyPond input.
const NAME = /^([a-zA-Z]|[^\x00-\x7F])([-_]?([a-zA-Z]|[^\x00-\x7F]))*$/;

const lilypond = (...args) =>
  execFileSync(LILYPOND, args, {encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe']});

/**
 * Run scripts/introspect.ly, after including `packages`.
 *
 * @param {string[]} packages
 * @returns {{bindings: Map<string, string>, markups: Map<string, string>}}
 */
function introspect(packages = []) {
  const dir = mkdtempSync(join(tmpdir(), 'lilypond-builtins-'));
  try {
    const input = join(dir, 'input.ly');
    const output = join(dir, 'builtins.tsv');
    writeFileSync(input, [
      '\\version "2.24.0"',
      ...packages.map(p => `\\include "${p}"`),
      `\\include "${INTROSPECT}"`,
      '',
    ].join('\n'));
    execFileSync(LILYPOND, ['-s', '-o', dir, input], {
      cwd: dir,
      env: {...process.env, INTROSPECT_OUTPUT: output},
      stdio: 'ignore',
    });
    const bindings = new Map();
    const markups = new Map();
    for (const line of readFileSync(output, 'utf8').split('\n')) {
      const [kind, name, detail] = line.split('\t');
      if (kind === 'binding') bindings.set(name, detail);
      else if (kind === 'markup') markups.set(name, detail);
    }
    return {bindings, markups};
  } finally {
    rmSync(dir, {recursive: true, force: true});
  }
}

/**
 * The file of ly/ that defines each identifier (`name = …` at the start of a
 * line).
 *
 * @param {string} datadir
 */
function origins(datadir) {
  const result = new Map();
  const lyDir = join(datadir, 'ly');
  for (const file of readdirSync(lyDir).filter(f => f.endsWith('.ly')).sort()) {
    const source = readFileSync(join(lyDir, file), 'utf8');
    for (const match of source.matchAll(/^"?([^\s"=%#\\]+)"?\s*=/gm)) {
      if (!result.has(match[1])) result.set(match[1], file);
    }
  }
  return result;
}

/** @param {string} s */
const quote = s => `"\\\\${s.replace(/["\\]/g, c => `\\${c}`)}"`;

/**
 * A highlight pattern matching the commands in `names`.
 *
 * @param {string} node  the start of the pattern, up to the captured node
 * @param {string} capture
 * @param {string[]} names
 */
function pattern(node, capture, names) {
  const lines = [`${node} ${capture}`, `  (#any-of? ${capture}`];
  let line = '   ';
  for (const name of names) {
    const item = ` ${quote(name)}`;
    if (line.length + item.length > 80) {
      lines.push(line);
      line = '   ';
    }
    line += item;
  }
  lines.push(`${line}))`);
  return lines.join('\n');
}

/**
 * Highlight patterns for the identifiers in `bindings`, one per capture.
 *
 * @param {Map<string, string>} bindings
 * @param {string} node
 */
function patterns(bindings, node = '((command)') {
  /** @type {Map<string, string[]>} */
  const byCapture = new Map();
  for (const [name, type] of [...bindings].sort(([a], [b]) => a.localeCompare(b))) {
    const capture = CAPTURES[type];
    if (!capture || !NAME.test(name)) continue;
    if (!byCapture.has(capture)) byCapture.set(capture, []);
    byCapture.get(capture).push(name);
  }
  return [...byCapture]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([capture, names]) => pattern(node, capture, names))
    .join('\n\n');
}

/**
 * Replace the text between `; BEGIN GENERATED <id>` and `; END GENERATED <id>`
 * (or `//` comments in JavaScript).
 *
 * @param {string} text
 * @param {string} id
 * @param {string} content
 * @param {string} comment
 */
function splice(text, id, content, comment) {
  const begin = `${comment} BEGIN GENERATED ${id}`;
  const end = `${comment} END GENERATED ${id}`;
  const start = text.indexOf(begin);
  const stop = text.indexOf(end);
  if (start < 0 || stop < start) throw new Error(`markers for ${id} not found`);
  const lineEnd = text.indexOf('\n', start) + 1;
  return `${text.slice(0, lineEnd)}${content}\n${text.slice(stop)}`;
}

/**
 * The built-in markup commands grouped by signature: the number of Scheme
 * arguments followed by the number of markup arguments, such as '11' for
 * \fontsize #2 markup. Commands with other signatures are left to the
 * generic rule of the grammar.
 *
 * @param {Map<string, string>} markups
 * @returns {Map<string, string>} command name => signature
 */
function markupSignatures(markups) {
  const result = new Map();
  for (const [symbol, signature] of markups) {
    const name = symbol.replace(/-markup(-list)?$/, '');
    // \score and \score-lines are keywords in markup mode.
    if (name === 'score' || name === 'score-lines') continue;
    const match = /^(S*)([ML]*)$/.exec(signature);
    if (!match || match[1].length > 3 || match[2].length > 3) continue;
    result.set(name, `${match[1].length}${match[2].length}`);
  }
  return result;
}

/**
 * src/markup_commands.h, the table of the external scanner.
 *
 * @param {Map<string, string>} commands
 * @param {string[]} signatures
 * @param {string} version
 */
function markupHeader(commands, signatures, version) {
  // Sorted by strcmp, for the binary search of the scanner.
  const names = [...commands.keys()].sort((a, b) => (a < b ? -1 : a > b ? 1 : 0));
  return [
    '// Built-in markup commands and their signatures, for src/scanner.c.',
    `// Generated by scripts/update-builtins.js from ${version}.`,
    '// Do not edit by hand.',
    '',
    '#ifndef TREE_SITTER_LILYPOND_MARKUP_COMMANDS_H_',
    '#define TREE_SITTER_LILYPOND_MARKUP_COMMANDS_H_',
    '',
    '#include <stdint.h>',
    '',
    `#define MARKUP_SIGNATURE_COUNT ${signatures.length}`,
    '',
    '// Signatures (MARKUP_SIGNATURES in grammar.js): the number of Scheme',
    '// arguments followed by the number of markup arguments.',
    ...signatures.map((signature, i) => `// ${i}: ${signature}`),
    '',
    'static const struct {',
    '    const char *name;',
    '    uint8_t signature;',
    '} MARKUP_COMMANDS[] = {',
    ...names.map(name =>
      `    {"${name}", ${signatures.indexOf(commands.get(name))}},`),
    '};',
    '',
    '#endif // TREE_SITTER_LILYPOND_MARKUP_COMMANDS_H_',
    '',
  ].join('\n');
}

/**
 *
 */
function main() {
  const datadir = lilypond(
    '-e', '(begin (display (ly:get-option (quote datadir))) (exit 0))',
  ).trim().split('\n').pop();
  const version = lilypond('--version').split('\n')[0].replace(/ \(.*\)$/, '');
  console.log(`${version}, data in ${datadir}`);

  const base = introspect();
  const where = origins(datadir);

  // Built-in identifiers, from files loaded by init.ly.
  const core = new Map([...base.bindings].filter(([name]) => {
    const file = where.get(name);
    return file === undefined || !PACKAGES.includes(file);
  }));

  // Markup commands are matched inside markup only.
  const markupCommands = new Map(
    [...base.markups.keys()].map(symbol => [
      symbol.replace(/-markup(-list)?$/, ''),
      'markup-command',
    ]),
  );
  for (const [name, type] of base.bindings) {
    if (type === 'markup-command') markupCommands.set(name, type);
  }

  // Packages: what each one adds to the built-in identifiers.
  const sections = [];
  for (const pkg of PACKAGES) {
    const {bindings} = introspect([pkg]);
    const added = new Map(
      [...bindings].filter(([name]) => !base.bindings.has(name)),
    );
    const body = patterns(added);
    if (body) sections.push(`; ${pkg}\n${body}`);
  }

  let highlights = readFileSync(join(ROOT, 'queries', 'highlights.scm'), 'utf8');
  highlights = splice(highlights, 'builtins', patterns(
    new Map([...core].filter(([, type]) => type !== 'markup-command')),
  ), ';');
  highlights = splice(highlights, 'markup-commands', patterns(
    markupCommands, '(markup_command\n  name: (command)',
  ), ';');
  highlights = splice(highlights, 'packages', sections.join('\n\n'), ';');
  writeFileSync(join(ROOT, 'queries', 'highlights.scm'), highlights);

  const commands = markupSignatures(base.markups);
  const signatures = [...new Set(commands.values())].sort();
  let grammar = readFileSync(join(ROOT, 'grammar.js'), 'utf8');
  grammar = splice(grammar, 'markup-signatures', [
    'const MARKUP_SIGNATURES = [',
    `  ${signatures.map(signature => `'${signature}',`).join(' ')}`,
    '];',
  ].join('\n'), '//');
  writeFileSync(join(ROOT, 'grammar.js'), grammar);
  writeFileSync(
    join(ROOT, 'src', 'markup_commands.h'),
    markupHeader(commands, signatures, version),
  );

  console.log('Updated grammar.js, src/markup_commands.h and queries/highlights.scm.');
  console.log('Run `tree-sitter generate` to update the parser.');
}

main();
