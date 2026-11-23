#!/usr/bin/env node
/**
 * Parse LilyPond's own test suite and report the files that do not parse.
 *
 * Usage: node scripts/parse-corpus.js [LILYPOND_SOURCE_DIR]
 *
 * Without an argument, a shallow, sparse clone of the LilyPond repository is
 * made in .corpus/ (ignored by git). The corpus is the regression tests
 * (input/regression), the snippets of the documentation
 * (Documentation/snippets) and the initialization files (ly/).
 */

import {execFileSync, spawnSync} from 'node:child_process';
import {existsSync, mkdirSync, readdirSync, statSync, writeFileSync} from 'node:fs';
import {dirname, join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const REPOSITORY = 'https://gitlab.com/lilypond/lilypond.git';
const DIRECTORIES = ['input/regression', 'Documentation/snippets', 'ly'];

/** @param {string} source */
function cloneLilyPond(source) {
  if (existsSync(source)) return;
  console.log(`Cloning ${REPOSITORY} into ${source}…`);
  execFileSync('git', [
    'clone', '--quiet', '--depth=1', '--filter=blob:none', '--sparse',
    REPOSITORY, source,
  ], {stdio: 'inherit'});
  execFileSync('git', ['sparse-checkout', 'set', ...DIRECTORIES], {
    cwd: source,
    stdio: 'inherit',
  });
}

/**
 * @param {string} directory
 * @returns {string[]}
 */
function lilypondFiles(directory) {
  if (!existsSync(directory)) return [];
  return readdirSync(directory).flatMap(entry => {
    const path = join(directory, entry);
    if (statSync(path).isDirectory()) return lilypondFiles(path);
    return /\.i?ly$/.test(entry) ? [path] : [];
  });
}

/**
 *
 */
function main() {
  const source = resolve(process.argv[2] ?? join(ROOT, '.corpus', 'lilypond'));
  if (process.argv[2] === undefined) cloneLilyPond(source);

  const files = DIRECTORIES.flatMap(d => lilypondFiles(join(source, d))).sort();
  if (files.length === 0) {
    console.error(`No LilyPond files found in ${source}`);
    process.exit(2);
  }
  mkdirSync(join(ROOT, '.corpus'), {recursive: true});
  const list = join(ROOT, '.corpus', 'files.txt');
  writeFileSync(list, `${files.join('\n')}\n`);

  const result = spawnSync('tree-sitter', [
    'parse', '--quiet', '--stat', '--paths', list,
  ], {cwd: ROOT, encoding: 'utf8', maxBuffer: 64 * 1024 * 1024});
  const output = `${result.stdout}${result.stderr}`;
  for (const line of output.split('\n')) {
    if (/\((ERROR|MISSING)/.test(line)) {
      console.log(line.replace(`${source}/`, '').replace(/\s+Parse:.*?\(/, '  ('));
    }
  }
  const summary = output.split('\n').find(line => line.startsWith('Total parses'));
  console.log(summary ?? output);
}

main();
