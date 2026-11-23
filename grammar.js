/**
 * @file LilyPond grammar for tree-sitter
 * @author Baptiste Darthenay
 * @license MIT
 *
 * The grammar follows LilyPond's own lexer (lily/lexer.ll) and parser
 * (lily/parser.yy) wherever a context-free grammar can:
 *
 * - The keywords of the lexer (`\score`, `\new`, `\override`, `\repeat`, …)
 *   are syntax and get dedicated rules.
 * - Everything defined in LilyPond itself (music functions such as
 *   `\relative`, `\tuplet` or `\key`, the dynamics, the articulations, …) is
 *   an ordinary `command`: LilyPond only knows their arity at run time, so
 *   inside music they are followed by their arguments as siblings. The
 *   highlight queries recognize them by name.
 * - The input modes of the lexer (notes and drums, lyrics, chords, figured
 *   bass and markup) are separate sets of rules, entered with the same
 *   keywords as in LilyPond (`\lyricmode`, `\addlyrics`, `\chordmode`, …).
 * - Embedded Scheme (`#…`, `$…`) is parsed as s-expressions, and LilyPond
 *   embedded in Scheme (`#{ … #}`) is parsed again as LilyPond.
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

// The lexer treats every byte >= 0x80 as a letter.
const LETTER = '([a-zA-Z]|[^\\x00-\\x7F])';
// LilyPond's {SYMBOL}: letters, with single `-` or `_` between letters.
const SYMBOL = `${LETTER}([-_]?${LETTER})*`;

const DIRECTIONS = ['-', '^', '_'];

// Signatures of the built-in markup commands: '<n><m>' means n Scheme
// arguments followed by m markup (or markup list) arguments. The external
// scanner (src/scanner.c) recognizes the built-in commands in markup and
// returns the token of their signature; the list of commands is in
// src/markup_commands.h. Other commands (user-defined ones) are parsed with a
// generic rule.
//
// BEGIN GENERATED markup-signatures (scripts/update-builtins.js)
const MARKUP_SIGNATURES = [
  '00', '01', '02', '10', '11', '12', '20', '21', '22', '23', '30', '31',
];
// END GENERATED markup-signatures

const PREC = {
  // Dynamic precedences of the last argument of a music function call: see
  // the _music_call rule.
  CALL_SIMPLE: 1,
  CALL_COMPOUND: 2,
  // Same for a markup command and its markup argument.
  MARKUP_ARGUMENT: 1,
  // `foo = bar` assigns a symbol rather than a pitch.
  VALUE_SYMBOL: 1,
};

/**
 * Rules shared by the input modes that contain music: notes (and drums),
 * lyrics, chords and figured bass. Each mode has its own set of items, but
 * braces, `<< >>`, `\repeat`, `\alternative` and `\new`/`\context` look the
 * same in all of them, so they are generated once per mode and aliased to a
 * common node name.
 *
 * @param {string} mode
 */
function musicMode(mode) {
  const item = `_${mode}_item`;
  const argument = `_${mode}_argument`;
  const sequential = `_${mode}_sequential`;
  const simultaneous = `_${mode}_simultaneous`;
  const grouped = `_${mode}_grouped`;
  const alternative = `_${mode}_alternative`;

  return {
    /** @param {GrammarSymbols<string>} $ */
    [sequential]: $ => seq(
      optional('\\sequential'),
      '{',
      repeat($[item]),
      '}',
    ),

    /** @param {GrammarSymbols<string>} $ */
    [simultaneous]: $ => choice(
      seq('<<', repeat($[item]), '>>'),
      seq('\\simultaneous', '{', repeat($[item]), '}'),
    ),

    /** @param {GrammarSymbols<string>} $ */
    [grouped]: $ => choice(
      alias($[sequential], $.sequential_music),
      alias($[simultaneous], $.simultaneous_music),
    ),

    /** @param {GrammarSymbols<string>} $ */
    [`_${mode}_repeat`]: $ => prec.right(seq(
      '\\repeat',
      field('type', $._simple_string),
      choice(
        seq(
          field('count', $._unsigned),
          field('body', $[argument]),
          optional(field('alternative', alias($[alternative], $.alternative))),
        ),
        // testPercent = \repeat percent \etc
        $.etc,
      ),
    )),

    /** @param {GrammarSymbols<string>} $ */
    [alternative]: $ => seq('\\alternative', field('body', $[argument])),

    /** @param {GrammarSymbols<string>} $ */
    [`_${mode}_contexted`]: $ => seq(
      choice('\\new', '\\context'),
      field('type', $._simple_string),
      optional(seq('=', field('name', $._simple_string))),
      repeat($.with_block),
      field('music', $[argument]),
    ),

    /** @param {GrammarSymbols<string>} $ */
    [`_${mode}_construct`]: $ => choice(
      alias($[`_${mode}_repeat`], $.repeat),
      alias($[alternative], $.alternative),
      alias($[`_${mode}_contexted`], $.contexted_music),
      $._shared_construct,
    ),
  };
}

export default grammar({
  name: 'lilypond',

  extras: $ => [/\s/, /\uFEFF/, $.comment],

  externals: $ => [
    ...MARKUP_SIGNATURES.map(signature => $[`_markup_command_${signature}`]),
    // Never valid in the grammar: tells the scanner about error recovery.
    $._error_sentinel,
  ],

  // Every `\word` is lexed as one token, so that keywords never match a
  // prefix of a longer command name (`\repeat` vs `\repeatTie`).
  word: $ => $.command,

  conflicts: $ => [
    // Ambiguities that LilyPond resolves with the signatures of the
    // functions, which are only known at run time.
    [$._flat_expression, $._music_call],
    [$._music_argument, $._music_call],
    [$._music_call, $._nested_music_call],
    [$._call_argument, $._simple_final_argument],
    [$._markup, $._generic_markup_command],
    [$._generic_markup_command],
  ],

  supertypes: $ => [
    $._scheme_datum,
  ],

  rules: {
    source_file: $ => repeat($._statement),

    // =====================================================================
    // Comments
    // =====================================================================

    // LilyPond comments (`% …` and `%{ … %}`) and Scheme comments (`; …`,
    // `#| … |#` and `#! … !#`). The low precedence lets words that may
    // contain `%` or `;` (Scheme symbols, markup words, lyrics, strings)
    // take precedence.
    comment: _ => token(prec(-1, choice(
      seq('%{', /[^%]*%+([^}%][^%]*%+)*/, '}'),
      /%([^{\r\n][^\r\n]*)?/,
      /;[^\r\n]*/,
      seq('#|', /[^|]*\|+([^#|][^|]*\|+)*/, '#'),
      seq('#!', /[^!]*!+([^#!][^!]*!+)*/, '#'),
    ))),

    // =====================================================================
    // Top level
    // =====================================================================

    _statement: $ => choice(
      $.assignment,
      $._directive,
      $._block,
      $.context_definition,
      $._expression,
      $._statement_argument,
    ),

    // Arguments of commands whose arity is unknown, such as the string in
    // `\language "english"`. The negative dynamic precedence makes them the
    // last resort: they are arguments of a function call when possible.
    _statement_argument: $ => prec.dynamic(-1, choice(
      $.note,
      alias($._standalone_duration, $.duration),
      $._post_event,
      $._flat_argument,
      $.property_path,
    )),

    _directive: $ => choice(
      $.version,
      $.include,
      $.source_file_name,
      $.source_file_line,
      $.main_input,
    ),

    version: $ => seq('\\version', field('version', $.string)),

    include: $ => seq(
      '\\include',
      field('file', choice($.string, $.command, $.embedded_scheme)),
    ),

    source_file_name: $ => seq('\\sourcefilename', field('name', $.string)),

    source_file_line: $ => seq(
      '\\sourcefileline',
      field('line', alias($._integer, $.number)),
    ),

    main_input: _ => '\\maininput',

    _block: $ => choice(
      $.header_block,
      $.book_block,
      $.bookpart_block,
      $.score_block,
      $._output_definition,
    ),

    // Expressions that may stand alone at top level and as assignment
    // values. There, a command takes the arguments that follow it when they
    // end with music.
    _expression: $ => choice(
      $._flat_expression,
      alias($._music_call, $.function_call),
    ),

    // Expressions without function calls, for the places that contain
    // lists of items (context modifications, output definitions).
    _flat_expression: $ => choice(
      $._music_grouped,
      $._music_construct,
      $.command,
      $.embedded_scheme,
      $.embedded_lilypond,
    ),

    // title = "…"   Staff.instrumentName = "…"   "violin I" = { … }
    assignment: $ => seq(
      field('name', choice(
        alias($._word, $.identifier),
        $.string,
        $.property_path,
        $.embedded_scheme,
        // \markup bold-red = \markup \bold \with-color #red \etc
        alias($._markup_assignment_name, $.markup),
      )),
      '=',
      field('value', $._value),
    ),

    _markup_assignment_name: $ => seq(
      '\\markup',
      field('content', alias($._markup_word, $.word)),
    ),

    _value: $ => choice(
      $._expression,
      $._block,
      $.with_block,
      $.context_definition,
      $._simple_music,
      prec.right(repeat1($._post_event)),
      $._number_expression,
      $.string,
      $.fraction,
      $.number_list,
      $._value_symbol,
      $.property_path,
    ),

    // =====================================================================
    // Blocks
    // =====================================================================

    header_block: $ => seq(
      '\\header',
      '{',
      repeat(choice($.assignment, $.embedded_scheme, $.command)),
      '}',
    ),

    book_block: $ => seq(
      '\\book',
      '{',
      repeat($._statement),
      '}',
    ),

    bookpart_block: $ => seq(
      '\\bookpart',
      '{',
      repeat($._statement),
      '}',
    ),

    score_block: $ => seq('\\score', $._score_body),

    _score_body: $ => seq(
      '{',
      repeat(choice(
        $._expression,
        $._simple_music,
        $.header_block,
        $._output_definition,
      )),
      '}',
    ),

    _output_definition: $ => choice(
      $.paper_block,
      $.layout_block,
      $.midi_block,
    ),

    paper_block: $ => seq('\\paper', $._output_definition_body),

    layout_block: $ => seq('\\layout', $._output_definition_body),

    midi_block: $ => seq('\\midi', $._output_definition_body),

    _output_definition_body: $ => seq(
      '{',
      repeat(choice(
        $.assignment,
        $.context_definition,
        $._directive,
        $._flat_expression,
        // Arguments of commands whose arity is unknown:
        // \accidentalStyle modern
        $._symbol,
        $.property_path,
        $._flat_argument,
        alias($._standalone_duration, $.duration),
      )),
      '}',
    ),

    // =====================================================================
    // Contexts
    // =====================================================================

    // \context { \Staff \consists "Ambitus_engraver" … }
    context_definition: $ => seq(
      '\\context',
      '{',
      repeat($._context_modification),
      '}',
    ),

    // \with { \remove "Time_signature_engraver" fontSize = -2 }
    with_block: $ => seq(
      '\\with',
      choice(
        seq('{', repeat($._context_modification), '}'),
        $.command,
        $.embedded_scheme,
      ),
    ),

    _context_modification: $ => choice(
      $.assignment,
      $.context_mod,
      $.with_block,
      $._directive,
      $._flat_expression,
      // Arguments of commands whose arity is unknown: \omit TimeSignature
      $._symbol,
      $.property_path,
      $._flat_argument,
      alias($._standalone_duration, $.duration),
    ),

    // \consists "Ambitus_engraver"   \accepts Voice   \name MyStaff
    context_mod: $ => seq(
      choice(
        '\\consists',
        '\\remove',
        '\\accepts',
        '\\denies',
        '\\alias',
        '\\defaultchild',
        '\\type',
        '\\description',
        '\\name',
      ),
      field('value', choice($._simple_string, $.command)),
    ),

    // =====================================================================
    // Constructs available in every music mode
    // =====================================================================

    _shared_construct: $ => choice(
      $.override,
      $.revert,
      $.set,
      $.unset,
      $.tempo,
      $.context_change,
      $.markup,
      $.markuplist,
      $.note_mode,
      $.drum_mode,
      $.chord_mode,
      $.figure_mode,
      $.lyric_mode,
      $.lyrics_to,
      $.add_lyrics,
      $.default,
      $.etc,
    ),

    // \override Staff.TimeSignature.color = #red
    // \override Stem #'thickness = #2      (deprecated syntax)
    override: $ => seq(
      '\\override',
      $._property_target,
      '=',
      field('value', $._scalar),
    ),

    revert: $ => seq('\\revert', $._property_target),

    _property_target: $ => prec.right(seq(
      field('path', choice($._symbol, $.property_path, $.embedded_scheme)),
      optional(field('property', $.embedded_scheme)),
    )),

    // \set Staff.instrumentName = "Violin"
    set: $ => seq(
      '\\set',
      field('path', choice($._symbol, $.property_path, $.embedded_scheme)),
      '=',
      field('value', $._scalar),
    ),

    unset: $ => seq(
      '\\unset',
      field('path', choice($._symbol, $.property_path, $.embedded_scheme)),
    ),

    _scalar: $ => choice(
      $.embedded_scheme,
      $.embedded_lilypond,
      $.string,
      $.number,
      $.quantity,
      $.fraction,
      $.number_list,
      $.markup,
      $.markuplist,
      $.command,
      $.default,
      $._simple_music,
      $._value_symbol,
      $.property_path,
    ),

    // Staff.TimeSignature.break-visibility
    property_path: $ => seq(
      // \violin.1 looks up a key in the alist stored in \violin.
      choice($._symbol, $.command),
      repeat1(seq('.', choice($._symbol, alias($._integer, $.number)))),
    ),

    // \tempo "Allegro" 4. = 72-80
    tempo: $ => prec.right(seq(
      '\\tempo',
      choice(
        seq(field('text', $._tempo_text), optional($._metronome_mark)),
        $._metronome_mark,
      ),
    )),

    _tempo_text: $ => choice(
      $.string,
      $.markup,
      $.embedded_scheme,
      $._symbol,
    ),

    _metronome_mark: $ => seq(
      field('duration', alias($._standalone_duration, $.duration)),
      '=',
      field('value', choice($.tempo_range, $._unsigned, $.command)),
    ),

    tempo_range: $ => prec(1, seq($._unsigned, '-', $._unsigned)),

    // \change Staff = "down"
    context_change: $ => seq(
      '\\change',
      field('type', $._simple_string),
      '=',
      field('name', $._simple_string),
    ),

    note_mode: $ => seq('\\notemode', field('music', $._music_grouped)),

    drum_mode: $ => seq(
      choice('\\drummode', seq('\\drums', repeat($.with_block))),
      field('music', $._music_grouped),
    ),

    chord_mode: $ => seq(
      choice('\\chordmode', seq('\\chords', repeat($.with_block))),
      field('music', $._chord_grouped),
    ),

    figure_mode: $ => seq(
      choice('\\figuremode', seq('\\figures', repeat($.with_block))),
      field('music', $._figure_grouped),
    ),

    lyric_mode: $ => seq(
      choice('\\lyricmode', seq('\\lyrics', repeat($.with_block))),
      field('music', $._lyric_grouped),
    ),

    // \lyricsto "melody" { … }
    lyrics_to: $ => seq(
      '\\lyricsto',
      choice(
        field('context', $._simple_string),
        seq(field('type', $._simple_string), '=', field('context', $._simple_string)),
      ),
      field('lyrics', $._lyric_music),
    ),

    // { c d e } \addlyrics { do re mi }
    add_lyrics: $ => seq(
      '\\addlyrics',
      repeat($.with_block),
      field('lyrics', $._lyric_music),
    ),

    _lyric_music: $ => choice(
      $._lyric_grouped,
      $.command,
      $.embedded_scheme,
    ),

    default: _ => '\\default',

    etc: _ => '\\etc',

    // =====================================================================
    // Note mode (also used for drums)
    // =====================================================================

    ...musicMode('music'),

    _music_item: $ => choice(
      $._simple_music,
      $._post_event,
      $.bar_check,
      $.voice_separator,
      $._music_grouped,
      $._music_construct,
      $.command,
      // User-defined one-character shorthands, such as "@" = #(…).
      alias(/[@&]/, $.command),
      $._directive,
      $._flat_argument,
      $.property_path,
      $.embedded_scheme,
      $.embedded_lilypond,
    ),

    // The music that `\new`, `\repeat`, … expect. A command may take
    // arguments here, as long as the last one is music.
    _music_argument: $ => choice(
      $._simple_music,
      $._music_grouped,
      $._music_construct,
      $.command,
      alias($._music_call, $.function_call),
      $.embedded_scheme,
      $.embedded_lilypond,
    ),

    _simple_music: $ => choice(
      $.note,
      $.rest,
      $.spacer_rest,
      $.multi_measure_rest,
      $.chord_repetition,
      $.chord,
      alias($._standalone_duration, $.duration),
    ),

    // c  cis''!4.~  bes,=,8\rest
    note: $ => prec.right(seq(
      field('pitch', alias($._word, $.pitch)),
      optional(field('octave', $.octave)),
      optional(field('accidental', $.accidental)),
      optional(field('octave_check', $.octave_check)),
      optional(field('duration', $.duration)),
      optional(field('rest', '\\rest')),
      repeat($._post_event),
    )),

    rest: $ => prec.right(seq(
      'r',
      optional(field('duration', $.duration)),
      repeat($._post_event),
    )),

    spacer_rest: $ => prec.right(seq(
      's',
      optional(field('duration', $.duration)),
      repeat($._post_event),
    )),

    multi_measure_rest: $ => prec.right(seq(
      'R',
      optional(field('duration', $.duration)),
      repeat($._post_event),
    )),

    chord_repetition: $ => prec.right(seq(
      'q',
      optional(field('duration', $.duration)),
      repeat($._post_event),
    )),

    // <c e g>4->
    chord: $ => prec.right(seq(
      '<',
      repeat(choice(
        alias($._chord_note, $.note),
        $._post_event,
        $.command,
        $.embedded_scheme,
        // Arguments of event functions: <c\RH 1 e\RH 2>
        alias($._standalone_duration, $.duration),
        alias($._music_real, $.number),
        $.string,
        $.property_path,
        $.markup,
      )),
      '>',
      optional(field('duration', $.duration)),
      repeat($._post_event),
    )),

    _chord_note: $ => prec.right(seq(
      field('pitch', alias($._word, $.pitch)),
      optional(field('octave', $.octave)),
      optional(field('accidental', $.accidental)),
      optional(field('octave_check', $.octave_check)),
      repeat($._post_event),
    )),

    octave: _ => /'+|,+/,

    // ! (reminder accidental) and ? (cautionary accidental)
    accidental: _ => /[!?]+/,

    octave_check: _ => token.immediate(/=('+|,+)?/),

    // A duration right after a pitch, a rest or a chord.
    duration: $ => seq(
      choice(token.immediate(/\d+/), '\\breve', '\\longa', '\\maxima'),
      optional(token.immediate(/\.+/)),
      repeat($.multiplier),
    ),

    // A duration on its own: `\partial 8`, `c4 8 8`, `\tempo 4 = 60`.
    _standalone_duration: $ => seq(
      choice(token(prec(-1, /\d+/)), '\\breve', '\\longa', '\\maxima'),
      optional(token.immediate(/\.+/)),
      repeat($.multiplier),
    ),

    // R1*4  s2*3/4  c4*#(…)
    multiplier: $ => seq(
      '*',
      choice(
        alias(/\d+(\/\d+)?/, $.number),
        $.embedded_scheme,
        $.command,
      ),
    ),

    bar_check: _ => '|',

    voice_separator: _ => '\\\\',

    // ------------------------------------------------------- post-events

    _post_event: $ => choice(
      $.post_event,
      $._undirected_post_event,
      $.tremolo,
      $.string_number,
      $.spanner_id,
    ),

    // -.  ^"text"  _\markup { … }  -1  ^(
    post_event: $ => seq(
      field('direction', choice(...DIRECTIONS)),
      field('event', choice(
        $.script_abbreviation,
        alias($._integer, $.fingering),
        $.string,
        $.markup,
        $.command,
        $.embedded_scheme,
        $._undirected_post_event,
        $.string_number,
        alias($._music_real, $.number),
        $.etc,
        // c^text is the same as c^"text".
        $._symbol,
      )),
    ),

    _undirected_post_event: $ => choice(
      $.tie,
      $.slur,
      $.phrasing_slur,
      $.beam,
      $.ligature,
      $.hairpin,
      $.duration_line,
      $.bend,
    ),

    // -^ -+ -- -! -> -. -_
    script_abbreviation: _ => choice('^', '+', '-', '!', '>', '.', '_'),

    tie: _ => '~',

    slur: _ => choice('(', ')'),

    phrasing_slur: _ => choice('\\(', '\\)'),

    beam: _ => choice('[', ']'),

    ligature: _ => choice('\\[', '\\]'),

    hairpin: _ => choice('\\<', '\\>', '\\!'),

    duration_line: _ => '\\-',

    bend: _ => '\\^',

    // c4:32
    tremolo: _ => /:\d*/,

    // c\3
    string_number: _ => /\\\d+/,

    // c\=1(
    spanner_id: $ => seq(
      '\\=',
      field('id', choice(alias($._integer, $.number), $._symbol, $.embedded_scheme)),
    ),

    // ------------------------------------------------------- function calls

    // \relative c' { … }   \transpose c d \relative { … }
    //
    // Where LilyPond expects a single music expression (top level,
    // assignment values, the music of \new, \repeat, …), a command takes
    // the arguments that follow it, provided that the last one is music or
    // a command. Inside music, commands are plain items and their arguments
    // are their siblings.
    //
    // LilyPond knows the signatures of the functions. Here, when the input
    // is ambiguous, the dynamic precedences favor calls that end with a
    // group, a construct or another call, then calls that end with a single
    // note.
    _music_call: $ => choice(
      prec.dynamic(PREC.CALL_COMPOUND, seq(
        field('name', $.command),
        repeat(field('argument', $._call_argument)),
        field('argument', choice($._compound_final_argument, $.command)),
      )),
      prec.dynamic(PREC.CALL_SIMPLE, seq(
        field('name', $.command),
        repeat(field('argument', $._call_argument)),
        field('argument', $._simple_final_argument),
      )),
    ),

    // A call that ends with music, as the last argument of another call:
    // \transpose c d \relative { … }
    _nested_music_call: $ => choice(
      prec.dynamic(PREC.CALL_COMPOUND, seq(
        field('name', $.command),
        repeat(field('argument', $._call_argument)),
        field('argument', $._compound_final_argument),
      )),
      prec.dynamic(PREC.CALL_SIMPLE, seq(
        field('name', $.command),
        repeat(field('argument', $._call_argument)),
        field('argument', $._simple_final_argument),
      )),
    ),

    _simple_final_argument: $ => choice(
      $._simple_music,
      $._post_event,
      // stemOff = \hide Staff.Stem
      $.property_path,
    ),

    _compound_final_argument: $ => choice(
      $._music_grouped,
      $._music_construct,
      $.embedded_lilypond,
      alias($._nested_music_call, $.function_call),
    ),

    _call_argument: $ => choice(
      $._simple_music,
      $._flat_argument,
      $._post_event,
      $.property_path,
      $.embedded_scheme,
    ),

    // Arguments of functions that are neither music nor Scheme.
    _flat_argument: $ => choice(
      $.string,
      alias($._music_real, $.number),
      $.fraction,
      $.number_list,
    ),

    // =====================================================================
    // Lyric mode
    // =====================================================================

    ...musicMode('lyric'),

    _lyric_item: $ => choice(
      $.syllable,
      $.lyric_hyphen,
      $.lyric_extender,
      alias($._standalone_duration, $.duration),
      $.bar_check,
      $._lyric_grouped,
      $._lyric_construct,
      $.command,
      $._directive,
      $._undirected_post_event,
      alias($._music_real, $.number),
      $.fraction,
      $.number_list,
      $.embedded_scheme,
      $.embedded_lilypond,
    ),

    _lyric_argument: $ => choice(
      $.syllable,
      $._lyric_grouped,
      $._lyric_construct,
      $.command,
      $.embedded_scheme,
      $.embedded_lilypond,
    ),

    syllable: $ => prec.right(seq(
      field('text', choice(alias($._lyric_word, $.word), $.string)),
      optional(field('duration', $.duration)),
    )),

    // Anything up to a space, a digit or a character that is special in
    // lyrics. `_` alone is a skipped syllable and `~` a lyric tie.
    _lyric_word: _ => /[^\s{}"\\#$%|*.=0-9][^\s{}"\\#$0-9]*/,

    lyric_hyphen: _ => '--',

    lyric_extender: _ => '__',

    // =====================================================================
    // Chord mode
    // =====================================================================

    ...musicMode('chord'),

    _chord_item: $ => choice(
      $.chord_symbol,
      $.rest,
      $.spacer_rest,
      $.multi_measure_rest,
      $.chord_repetition,
      $.chord,
      alias($._standalone_duration, $.duration),
      $.bar_check,
      $._chord_grouped,
      $._chord_construct,
      $.command,
      $._directive,
      $._undirected_post_event,
      $._flat_argument,
      $.property_path,
      $.embedded_scheme,
      $.embedded_lilypond,
    ),

    _chord_argument: $ => choice(
      $.chord_symbol,
      $.chord,
      $._chord_grouped,
      $._chord_construct,
      $.command,
      $.embedded_scheme,
      $.embedded_lilypond,
    ),

    // c:m7.9-/e  f1:sus4  bes:maj7/+d
    chord_symbol: $ => prec.right(seq(
      field('root', alias($._word, $.pitch)),
      optional(field('octave', $.octave)),
      optional(field('duration', $.duration)),
      repeat(choice(
        $.chord_modifiers,
        $.chord_removals,
        $.chord_inversion,
        $.chord_bass,
      )),
      repeat(choice(
        $._undirected_post_event,
        // `-` and `^` are chord syntax, only `_` can give a direction.
        alias($._chord_post_event, $.post_event),
      )),
    )),

    _chord_post_event: $ => seq(
      field('direction', '_'),
      field('event', choice(
        $.string,
        $.markup,
        $.command,
        $.embedded_scheme,
      )),
    ),

    chord_modifiers: $ => prec.right(seq(
      ':',
      repeat(choice($.chord_modifier, $.chord_step, '.')),
    )),

    chord_removals: $ => prec.right(seq(
      '^',
      repeat(choice($.chord_step, '.')),
    )),

    chord_modifier: _ => choice('m', 'min', 'maj', 'aug', 'dim', 'sus'),

    // The precedence keeps `7.5` from being lexed as a number in c:7.5-.
    chord_step: _ => token(prec(1, /\d+[+-]?/)),

    chord_inversion: $ => seq(
      '/',
      field('pitch', alias($._word, $.pitch)),
      optional(field('octave', $.octave)),
    ),

    chord_bass: $ => seq(
      '/+',
      field('pitch', alias($._word, $.pitch)),
      optional(field('octave', $.octave)),
    ),

    // =====================================================================
    // Figure mode (figured bass)
    // =====================================================================

    ...musicMode('figure'),

    _figure_item: $ => choice(
      $.figure_group,
      $.rest,
      $.spacer_rest,
      $.multi_measure_rest,
      $.chord_repetition,
      alias($._standalone_duration, $.duration),
      $.bar_check,
      $._figure_grouped,
      $._figure_construct,
      $.command,
      $._directive,
      $._undirected_post_event,
      $._flat_argument,
      $.property_path,
      $.embedded_scheme,
      $.embedded_lilypond,
    ),

    _figure_argument: $ => choice(
      $.figure_group,
      $._figure_grouped,
      $._figure_construct,
      $.command,
      $.embedded_scheme,
      $.embedded_lilypond,
    ),

    // <6 4+>4  <_ [5 3]>
    figure_group: $ => prec.right(seq(
      '<',
      repeat($.figure),
      '>',
      optional(field('duration', $.duration)),
      repeat($._undirected_post_event),
    )),

    figure: $ => prec.right(seq(
      optional('['),
      field('value', choice(
        '_',
        alias($._integer, $.number),
        $.string,
        $.markup,
        $.embedded_scheme,
      )),
      repeat($.figure_alteration),
      optional(']'),
    )),

    figure_alteration: _ => choice(
      '+', '-', '!', '\\+', '\\!', '/', '\\\\',
      // <3[-]>: a bracketed alteration
      /\[[+\-!\s]*\]/,
    ),

    // =====================================================================
    // Markup
    // =====================================================================

    // \markup \bold { Hello "world" }
    markup: $ => seq('\\markup', field('content', $._markup)),

    markuplist: $ => seq('\\markuplist', field('content', $._markup)),

    _markup: $ => choice(
      $.markup_list,
      alias($._markup_word, $.word),
      $.string,
      $.command,
      $.markup_command,
      $.embedded_scheme,
      $.embedded_lilypond,
      $.score_block,
      alias($._score_lines, $.score_block),
      // \markup \bold \etc defines a partial markup function.
      $.etc,
    ),

    markup_list: $ => seq('{', repeat($._markup), '}'),

    // Everything up to a space or a character that is special in markup.
    _markup_word: _ => /[^\s{}"\\#$%][^\s{}"\\#$]*/,

    _score_lines: $ => seq('\\score-lines', $._score_body),

    markup_command: $ => choice(
      ...MARKUP_SIGNATURES.map(signature => {
        const schemeArgs = Number(signature[0]);
        const markupArgs = Number(signature[1]);
        return seq(
          field('name', alias($[`_markup_command_${signature}`], $.command)),
          ...Array(schemeArgs).fill(field('argument', $._markup_scheme_argument)),
          ...Array(markupArgs).fill(field('argument', $._markup)),
        );
      }),
      $._generic_markup_command,
    ),

    // A command that is not built in: it takes any number of Scheme
    // arguments, then (if the input allows it) one markup argument.
    _generic_markup_command: $ => seq(
      field('name', $.command),
      choice(
        seq(
          repeat1(field('argument', $.embedded_scheme)),
          optional(field('argument', $._generic_markup_argument)),
        ),
        field('argument', $._generic_markup_argument),
      ),
    ),

    _generic_markup_argument: $ => prec.dynamic(PREC.MARKUP_ARGUMENT, $._markup),

    _markup_scheme_argument: $ => choice(
      $.embedded_scheme,
      $.string,
      $.markup_list,
      $.command,
    ),

    // =====================================================================
    // Words, strings and numbers
    // =====================================================================

    // A bare word: a pitch in music, a symbol elsewhere.
    _word: _ => new RegExp(SYMBOL),

    _symbol: $ => alias($._word, $.symbol),

    _value_symbol: $ => prec(PREC.VALUE_SYMBOL, alias($._word, $.symbol)),

    _simple_string: $ => choice($._symbol, $.string, $.embedded_scheme),

    // \foo  \fill-line  \"violin 1"
    command: _ => token(choice(
      new RegExp(`\\\\${SYMBOL}`),
      /\\"([^"\\]|\\.)*"/,
      // Shorthands: \( \< \! \~ \* \% … (those with a meaning of their own
      // in the grammar are keywords).
      /\\[^a-zA-Z0-9\s"\x80-\uFFFF]/,
    )),

    string: $ => seq(
      '"',
      repeat(choice(
        alias(token.immediate(prec(1, /[^"\\]+/)), $.string_content),
        $.escape_sequence,
        alias(token.immediate('\\'), $.string_content),
      )),
      token.immediate('"'),
    ),

    // Only these are escapes in LilyPond strings; any other backslash is
    // kept as is.
    escape_sequence: _ => token.immediate(prec(1, /\\[nt\\'"]/)),

    _integer: _ => /\d+/,

    _unsigned: $ => choice(alias($._integer, $.number), $.embedded_scheme),

    number: _ => /-?(\d+(\.\d*)?|\.\d+)/,

    // Inside music, integers are durations, so only reals with digits on
    // both sides of the point are numbers.
    _music_real: _ => /\d+\.\d+/,

    fraction: _ => /\d+\/\d+/,

    // \time 2,2,3 7/8
    number_list: _ => /\d+(,\d+)+/,

    // 15\mm  -0.5\cm
    quantity: $ => seq($.number, $.unit),

    unit: _ => token.immediate(prec(1, new RegExp(`\\\\${SYMBOL}`))),

    _number_expression: $ => choice(
      $.number,
      $.quantity,
      $.binary_expression,
    ),

    // line-width = 180\mm - 2 * 15\mm
    binary_expression: $ => choice(
      ...[['+', 1], ['-', 1], ['*', 2], ['/', 2]].map(([operator, precedence]) =>
        prec.left(Number(precedence), seq(
          field('left', $._number_expression),
          field('operator', String(operator)),
          field('right', $._number_expression),
        )),
      ),
    ),

    // =====================================================================
    // Scheme
    // =====================================================================

    // #red  ##t  #'(1 . 2)  $(make-music …)  #{ c4 #}
    embedded_scheme: $ => seq(
      // $@ and #@ splice a Scheme list into the music.
      field('prefix', choice('#', '$', '#@', '$@')),
      field('value', $._scheme_datum),
    ),

    // #{ \relative { c4 d e } #}
    embedded_lilypond: $ => seq(
      '#{',
      repeat(choice(
        $._music_item,
        $.assignment,
        $._block,
        $.with_block,
        $.context_definition,
      )),
      '#}',
    ),

    _scheme_datum: $ => choice(
      $.scheme_list,
      $.scheme_vector,
      $.scheme_quote,
      $.scheme_string,
      $.scheme_number,
      $.scheme_boolean,
      $.scheme_character,
      $.scheme_keyword,
      $.scheme_symbol,
      $.embedded_lilypond,
    ),

    _scheme_list_item: $ => choice(
      $._scheme_datum,
      $.scheme_datum_comment,
      alias('.', $.scheme_dot),
    ),

    scheme_list: $ => choice(
      seq('(', repeat($._scheme_list_item), ')'),
      seq('[', repeat($._scheme_list_item), ']'),
    ),

    scheme_vector: $ => seq(
      choice('#(', '#u8(', '#vu8('),
      repeat($._scheme_list_item),
      ')',
    ),

    // 'x  `(a ,b ,@c)  #'x
    scheme_quote: $ => seq(
      field('quote', choice('\'', '`', ',', ',@', '#\'', '#`', '#,', '#,@')),
      field('value', $._scheme_datum),
    ),

    // #;(ignored datum)
    scheme_datum_comment: $ => seq('#;', $._scheme_datum),

    scheme_string: $ => seq(
      '"',
      repeat(choice(
        alias(token.immediate(prec(1, /[^"\\]+/)), $.string_content),
        alias(token.immediate(prec(1, /\\(x[0-9a-fA-F]+;|u[0-9a-fA-F]{4}|U[0-9a-fA-F]{6}|(.|\r?\n))/)), $.escape_sequence),
      )),
      token.immediate('"'),
    ),

    scheme_number: _ => token(prec(1, choice(
      /[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?(\/\d+)?/,
      /#[xXbBoOdDeEiI][^\s()\[\]{}"';`,|]+/,
      /[+-](inf|nan)\.0/,
    ))),

    scheme_boolean: _ => /#(t|f|T|F|true|false)/,

    scheme_character: _ => /#\\(x[0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9-]*|[^\s])/,

    scheme_keyword: _ => /#:[^\s()\[\]{}"';`,#|]+/,

    scheme_symbol: _ => choice(
      /[^\s()\[\]{}"';`,#|]+/,
      /\|[^|]*\|/,
    ),
  },
});
