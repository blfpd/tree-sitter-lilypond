# tree-sitter-lilypond

[![CI](https://img.shields.io/github/actions/workflow/status/tree-sitter-grammars/tree-sitter-lilypond/ci.yml?logo=github&label=CI)](https://github.com/tree-sitter-grammars/tree-sitter-lilypond/actions/workflows/ci.yml)
[![crates](https://img.shields.io/crates/v/tree-sitter-lilypond?logo=rust)](https://crates.io/crates/tree-sitter-lilypond)

A [tree-sitter](https://tree-sitter.github.io/) grammar for
[LilyPond](https://lilypond.org/), the music engraving program, with Rust
bindings and queries for highlighting, injections, local variables, folds,
indentation and tags.

```lilypond
\version "2.24.0"
\header { title = "Minuet" }

melody = \relative c'' {
  \key g \major \time 3/4
  d4\p g,8( a b c) | d4-. g,-. g-. |
}

\score {
  \new Staff \with { instrumentName = "Violin" } \melody
  \layout { indent = 15\mm }
}
```

The grammar parses 99.9% of LilyPond's own test suite without errors: the
2,952 regression tests, documentation snippets and initialization files of the
LilyPond repository, of which the three failures use rare syntax listed under
[Limitations](#limitations).

## Usage

```toml
[dependencies]
tree-sitter = "0.27"
tree-sitter-lilypond = "0.1"
```

```rust
let mut parser = tree_sitter::Parser::new();
parser.set_language(&tree_sitter_lilypond::LANGUAGE.into())?;
let tree = parser.parse(r"\relative { c'4 d e f }", None).unwrap();
```

The crate also exports `NODE_TYPES` and the queries: `HIGHLIGHTS_QUERY`,
`INJECTIONS_QUERY`, `LOCALS_QUERY`, `TAGS_QUERY`, `FOLDS_QUERY` and
`INDENTS_QUERY`.

## How LilyPond is parsed

LilyPond has no formal grammar: its lexer switches modes as it reads, and its
parser relies on the signatures of functions that are only known at run time.
This grammar follows LilyPond's own lexer and parser (`lily/lexer.ll` and
`lily/parser.yy`) as far as a context-free grammar can, and makes the
following choices for the rest.

### Syntax and definitions

The keywords of LilyPond's lexer are syntax, with their own nodes:

| Input | Node |
| --- | --- |
| `\version`, `\include` | `version`, `include` |
| `\header`, `\score`, `\book`, `\bookpart` | `header_block`, `score_block`, … |
| `\paper`, `\layout`, `\midi` | `paper_block`, `layout_block`, `midi_block` |
| `\new`, `\context` + music | `contexted_music` |
| `\context { … }`, `\with { … }` | `context_definition`, `with_block` |
| `\consists`, `\remove`, `\accepts`, … | `context_mod` |
| `\override`, `\revert`, `\set`, `\unset` | `override`, `revert`, `set`, `unset` |
| `\repeat`, `\alternative` | `repeat`, `alternative` |
| `\tempo`, `\change` | `tempo`, `context_change` |
| `\markup`, `\markuplist` | `markup`, `markuplist` |
| `\lyricmode`, `\chordmode`, `\figuremode`, `\drummode`, … | `lyric_mode`, `chord_mode`, … |
| `\lyricsto`, `\addlyrics` | `lyrics_to`, `add_lyrics` |

Everything that LilyPond defines in its own `ly/*.ly` files (`\relative`,
`\tuplet`, `\key`, `\voiceOne`, `\p`, `\fermata`, …) is an ordinary `command`.
The highlight queries recognize these definitions by name, sorted by what they
are (music functions, predefined music, dynamics and articulations, context
modifications, …). The lists are generated from LilyPond itself, and the
definitions of optional packages such as `bagpipe.ly` or `arabic.ly`, which a
score has to `\include`, have a section of their own.

### Music

Notes, rests and chords carry their parts as fields, and the post-events that
follow them (articulations, ties, slurs, beams, dynamics spans, fingerings,
tremolos, …) as children:

```lilypond
melody = \relative c'' { g4.-> a8( b) \clef bass }
```

```query
(source_file
  (assignment
    name: (identifier)
    value: (function_call
      name: (command)
      argument: (note pitch: (pitch) octave: (octave))
      argument: (sequential_music
        (note pitch: (pitch) duration: (duration)
          (post_event event: (script_abbreviation)))
        (note pitch: (pitch) duration: (duration) (slur))
        (note pitch: (pitch) (slur))
        (command)
        (note pitch: (pitch))))))
```

Inside music, a command and its arguments are siblings, since only LilyPond
knows how many arguments `\clef` takes. Where LilyPond expects a single
expression (at top level, as the value of an assignment, as the music of
`\new` or `\repeat`), a command takes the arguments that follow it and becomes
a `function_call`, provided that the last one is music or a command. When
several readings are possible, the longest call that ends with music wins.

A bare word in music is a `note`, because LilyPond decides only at run time
whether it is a pitch (`c`, `fis`, `do`, `bd` in drum mode) or a symbol
(`\clef treble`).

### Input modes

Lyrics (`syllable`, `lyric_hyphen`, `lyric_extender`), chord mode
(`chord_symbol` with `chord_modifiers`, `chord_inversion`, `chord_bass`, …),
figured bass (`figure_group`, `figure`) and markup each have their own rules,
entered with the same keywords as in LilyPond.

### Markup

Built-in markup commands take exactly their arguments: in
`\markup \fontsize #2 \bold { a b } x`, `\fontsize` takes a number and a
markup, `\bold` takes a markup, and `x` is left out. The external scanner
(`src/scanner.c`) recognizes the built-in commands and tells the parser their
signature, generated from LilyPond into `src/markup_commands.h`. Other
commands take any number of Scheme arguments, then one markup argument when
the input allows it.

### Scheme

Scheme after `#` and `$` is parsed as s-expressions (`scheme_list`,
`scheme_symbol`, `scheme_string`, …), with Scheme comments, and LilyPond
embedded in Scheme (`#{ … #}`) is parsed as LilyPond again, to any depth.

## Queries

| File | Contents |
| --- | --- |
| `highlights.scm` | Highlights, with the [Neovim capture names](https://neovim.io/doc/user/treesitter.html#treesitter-highlight-groups). |
| `injections.scm` | Comments, and LilyPond in strings given to `ly:parser-include-string`. |
| `locals.scm` | Scopes and definitions, for variables and for Scheme. |
| `folds.scm` | Blocks, music expressions, markup lists and Scheme lists. |
| `indents.scm` | Indentation inside braces, `<< >>`, `#{ #}` and Scheme lists. |
| `tags.scm` | Variables, music functions, Scheme functions and markup commands. |

When several patterns capture the same node, the last one wins, as in Neovim,
Helix and the tree-sitter CLI.

## Development

```sh
npm install                        # tree-sitter CLI and ESLint
tree-sitter generate               # regenerate src/parser.c
tree-sitter test                   # corpus, highlight and tags tests
cargo test                         # Rust bindings, examples and queries
npm run lint                       # ESLint on grammar.js and scripts/
node scripts/parse-corpus.js       # parse LilyPond's test suite (clones it)
node scripts/update-builtins.js    # regenerate the lists of definitions
```

`scripts/update-builtins.js` asks LilyPond (`lilypond` in `PATH`, or the
`LILYPOND` environment variable) for the identifiers and markup commands it
defines, using `scripts/introspect.ly`, then rewrites the generated sections of
`queries/highlights.scm` and `grammar.js` and the file
`src/markup_commands.h`. Run `tree-sitter generate` afterwards.

## Limitations

- Bare words in music are parsed as notes, even when LilyPond reads them as
  symbols: `color` in `\tweak color #red`, `treble` in `\clef treble`. The
  highlight queries color the capitalized ones (context and grob names) as
  types.
- The arity of functions is a heuristic outside music: at top level, a command
  followed by another command may be parsed as one call.
- These rare forms are not supported: lists mixing numbers and strings
  (`\voices 1,"sop"`), duration variables followed by dots (`c\wholeHalved.`),
  partial markup functions with missing Scheme arguments
  (`\markup \note-by-number #2 \etc`) and Guile's `#[ ]` syntax.

## License

[MIT](LICENSE). The CI configuration is adapted from
[tree-sitter-latex](https://github.com/latex-lsp/tree-sitter-latex) (MIT).
