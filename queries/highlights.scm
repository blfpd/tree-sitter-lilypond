; Highlights for LilyPond
;
; When several patterns capture the same node, the last one wins, so generic
; patterns come first and specific ones after.

; =============================================================================
; Comments and literals
; =============================================================================

(comment) @comment

(scheme_datum_comment) @comment

[
  (string)
  (scheme_string)
] @string

(escape_sequence) @string.escape

[
  (number)
  (fraction)
  (number_list)
  (scheme_number)
] @number

(unit) @type

(binary_expression
  operator: _ @operator)

; =============================================================================
; Keywords
; =============================================================================

[
  "\\book"
  "\\bookpart"
  "\\score"
  "\\score-lines"
  "\\header"
  "\\paper"
  "\\layout"
  "\\midi"
  "\\context"
  "\\new"
  "\\with"
  "\\change"
  "\\sequential"
  "\\simultaneous"
  "\\tempo"
  "\\markup"
  "\\markuplist"
  "\\notemode"
  "\\drummode"
  "\\drums"
  "\\chordmode"
  "\\chords"
  "\\figuremode"
  "\\figures"
  "\\lyricmode"
  "\\lyrics"
  "\\lyricsto"
  "\\addlyrics"
  "\\override"
  "\\revert"
  "\\set"
  "\\unset"
  "\\consists"
  "\\remove"
  "\\accepts"
  "\\denies"
  "\\alias"
  "\\defaultchild"
  "\\type"
  "\\description"
  "\\name"
] @keyword

(note
  rest: _ @keyword)

[
  "\\repeat"
  "\\alternative"
] @keyword.repeat

"\\include" @keyword.import

[
  "\\version"
  "\\sourcefilename"
  "\\sourcefileline"
  (main_input)
] @keyword.directive

[
  (default)
  (etc)
] @constant.builtin

; =============================================================================
; Music
; =============================================================================

(pitch) @variable

[
  (octave)
  (accidental)
  (octave_check)
] @operator

(duration) @number

(multiplier
  "*" @operator)

(rest
  "r" @constant.builtin)

(spacer_rest
  "s" @constant.builtin)

(multi_measure_rest
  "R" @constant.builtin)

(chord_repetition
  "q" @constant.builtin)

[
  (bar_check)
  (voice_separator)
] @punctuation.special

; Post-events

(post_event
  direction: _ @operator)

(script_abbreviation) @operator

(fingering) @number

[
  (tie)
  (slur)
  (phrasing_slur)
  (beam)
  (ligature)
] @punctuation.special

[
  (hairpin)
  (duration_line)
  (bend)
  (string_number)
] @attribute.builtin

(tremolo) @operator

(spanner_id
  "\\=" @operator)

; Lyrics

[
  (lyric_hyphen)
  (lyric_extender)
] @punctuation.delimiter

(syllable
  text: (word) @punctuation.special
  (#eq? @punctuation.special "_"))

; Chord mode

(chord_symbol
  root: (pitch) @variable)

[
  (chord_inversion
    "/" @operator)
  (chord_bass
    "/+" @operator)
  (chord_modifiers
    ":" @operator)
  (chord_removals
    "^" @operator)
]

(chord_modifier) @attribute

(chord_step) @number

; Figured bass

(figure
  "_" @punctuation.special)

(figure_alteration) @operator

; Bare words in music are parsed as pitches, because LilyPond only decides at
; run time. Capitalized ones are context or grob names: \omit TimeSignature
((pitch) @type
  (#match? @type "^[A-Z][a-zA-Z]+$"))

; =============================================================================
; Markup
; =============================================================================

[
  (markup_list
    (word) @string)
  (markup
    content: (word) @string)
  (markup_command
    argument: (word) @string)
]

(markup_command
  name: (command) @function)

; =============================================================================
; Contexts, properties and assignments
; =============================================================================

(symbol) @string.special.symbol

(assignment
  "=" @operator)

(assignment
  name: (identifier) @variable)

(assignment
  name: (property_path
    (symbol) @variable))

; Header fields, paper and layout variables, context properties.
[
  (header_block
    (assignment
      name: (identifier) @property))
  (paper_block
    (assignment
      name: [
        (identifier) @property
        (property_path
          (symbol) @property)
      ]))
  (layout_block
    (assignment
      name: [
        (identifier) @property
        (property_path
          (symbol) @property)
      ]))
  (midi_block
    (assignment
      name: (identifier) @property))
  (with_block
    (assignment
      name: (identifier) @property))
  (context_definition
    (assignment
      name: (identifier) @property))
]

(property_path
  (symbol) @property)

(property_path
  "." @punctuation.delimiter)

(set
  path: (symbol) @property)

(unset
  path: (symbol) @property)

[
  (override
    "=" @operator)
  (set
    "=" @operator)
  (contexted_music
    "=" @operator)
  (context_change
    "=" @operator)
  (lyrics_to
    "=" @operator)
  (tempo
    "=" @operator)
]

(tempo_range
  "-" @operator)

; Staff.TimeSignature.color: contexts and grobs are capitalized.
((symbol) @type
  (#match? @type "^[A-Z]"))

(contexted_music
  type: (symbol) @type)

(context_change
  type: (symbol) @type)

(context_mod
  value: (symbol) @type)

(contexted_music
  name: (symbol) @label)

(context_change
  name: (symbol) @label)

(lyrics_to
  context: (symbol) @label)

(repeat
  type: (symbol) @attribute)

; =============================================================================
; Scheme
; =============================================================================

(embedded_scheme
  prefix: _ @punctuation.special)

(embedded_lilypond
  [
    "#{"
    "#}"
  ] @punctuation.special)

(scheme_symbol) @variable

(scheme_boolean) @boolean

(scheme_character) @character

(scheme_keyword) @string.special.symbol

(scheme_quote
  quote: _ @operator)

(scheme_quote
  value: (scheme_symbol) @string.special.symbol)

(scheme_dot) @punctuation.delimiter

(scheme_list
  .
  (scheme_symbol) @function.call)

((scheme_symbol) @function.builtin
  (#match? @function.builtin "^ly:"))

((scheme_list
  .
  (scheme_symbol) @keyword)
  (#any-of? @keyword
    "and" "begin" "case" "cond" "define" "define*" "define-public"
    "define*-public" "define-macro" "define-module" "define-record-type"
    "define-syntax" "define-syntax-rule" "delay" "do" "else" "if" "lambda"
    "lambda*" "let" "let*" "let-values" "let*-values" "letrec" "letrec*"
    "or" "quasiquote" "quote" "set!" "syntax-rules" "unless" "unquote"
    "unquote-splicing" "use-modules" "when"))

((scheme_list
  .
  (scheme_symbol) @keyword.function)
  (#any-of? @keyword.function
    "define-music-function" "define-event-function" "define-scheme-function"
    "define-void-function" "define-markup-command"
    "define-markup-list-command" "define-public-toplevel"))

((scheme_symbol) @constant.builtin
  (#any-of? @constant.builtin
    "UP" "DOWN" "LEFT" "RIGHT" "CENTER" "START" "STOP" "SMALLER" "BIGGER"
    "X" "Y" "INF" "PI" "ZERO-MOMENT"))

; (define (name parameter …) …)
(scheme_list
  .
  (scheme_symbol) @keyword
  .
  (scheme_list
    .
    (scheme_symbol) @function
    (scheme_symbol)* @variable.parameter)
  (#any-of? @keyword "define" "define*" "define-public" "define*-public"))

; (lambda (parameter …) …)
(scheme_list
  .
  (scheme_symbol) @keyword
  .
  (scheme_list
    (scheme_symbol) @variable.parameter)
  (#any-of? @keyword "lambda" "lambda*"))

; (define-music-function (parameter …) (type? …) …)
(scheme_list
  .
  (scheme_symbol) @keyword.function
  .
  (scheme_list
    (scheme_symbol) @variable.parameter)
  (#any-of? @keyword.function
    "define-music-function" "define-event-function" "define-scheme-function"
    "define-void-function"))

; (define-markup-command (name layout props parameter …) (type? …) …)
(scheme_list
  .
  (scheme_symbol) @keyword.function
  .
  (scheme_list
    .
    (scheme_symbol) @function
    (scheme_symbol)* @variable.parameter)
  (#any-of? @keyword.function "define-markup-command" "define-markup-list-command"))

; =============================================================================
; Commands
; =============================================================================

; Anything not listed below: variables and functions defined in the score.
(command) @function

; BEGIN GENERATED builtins (scripts/update-builtins.js)
((command) @attribute.builtin
  (#any-of? @attribute.builtin
    "\\accent" "\\accentus" "\\arpeggio" "\\bachschleifer" "\\breakDynamicSpan"
    "\\chordSlur" "\\circulus" "\\coda" "\\cr" "\\cresc" "\\dashBang"
    "\\dashDash" "\\dashDot" "\\dashHat" "\\dashLarger" "\\dashPlus"
    "\\dashUnderscore" "\\decr" "\\decresc" "\\dim" "\\downbow" "\\downmordent"
    "\\downprall" "\\endcr" "\\endcresc" "\\enddecr" "\\enddecresc" "\\enddim"
    "\\episemFinis" "\\episemInitium" "\\espressivo" "\\f" "\\fermata" "\\ff"
    "\\fff" "\\ffff" "\\fffff" "\\flageolet" "\\fp" "\\fz" "\\glide"
    "\\glissando" "\\halfopen" "\\harmonic" "\\haydnturn" "\\heel"
    "\\heelcircle" "\\henzelongfermata" "\\henzeshortfermata" "\\ictus"
    "\\laissezVibrer" "\\lheel" "\\lheeltoe" "\\lineprall" "\\longfermata"
    "\\ltoe" "\\ltoeheel" "\\marcato" "\\mf" "\\mordent" "\\mp" "\\n" "\\noBeam"
    "\\nonArpeggiato" "\\open" "\\p" "\\portato" "\\pp" "\\ppp" "\\pppp"
    "\\ppppp" "\\prall" "\\pralldown" "\\prallmordent" "\\prallprall"
    "\\prallup" "\\repeatTie" "\\reverseturn" "\\rfz" "\\rheel" "\\rheeltoe"
    "\\rtoe" "\\rtoeheel" "\\segno" "\\semicirculus" "\\sf" "\\sff" "\\sfp"
    "\\sfz" "\\shortfermata" "\\signumcongruentiae" "\\slashturn"
    "\\snappizzicato" "\\sostenutoOff" "\\sostenutoOn" "\\sp" "\\spp"
    "\\staccatissimo" "\\staccato" "\\startGraceSlur" "\\startGroup"
    "\\startTextSpan" "\\startTrillSpan" "\\stopGraceSlur" "\\stopGroup"
    "\\stopped" "\\stopTextSpan" "\\stopTrillSpan" "\\sustainOff" "\\sustainOn"
    "\\tenuto" "\\thumb" "\\toe" "\\treCorde" "\\trill" "\\turn" "\\unaCorda"
    "\\upbow" "\\upmordent" "\\upprall" "\\varcoda" "\\varheel" "\\vartoe"
    "\\verylongfermata" "\\veryshortfermata" "\\vowelTransition"))

((command) @constant.builtin
  (#any-of? @constant.builtin
    "\\aeolian" "\\aikenHeads" "\\aikenHeadsMinor" "\\aikenThinHeads"
    "\\aikenThinHeadsMinor" "\\allowBreak" "\\arabicStringNumbers" "\\ascendens"
    "\\auctum" "\\autoBeamOff" "\\autoBeamOn" "\\autoBreaksOff" "\\autoBreaksOn"
    "\\autoLineBreaksOff" "\\autoLineBreaksOn" "\\autoPageBreaksOff"
    "\\autoPageBreaksOn" "\\balloonLengthOff" "\\balloonLengthOn"
    "\\bassFigureExtendersOff" "\\bassFigureExtendersOn"
    "\\bassFigureStaffAlignmentDown" "\\bassFigureStaffAlignmentNeutral"
    "\\bassFigureStaffAlignmentUp" "\\beamBreak" "\\blackTriangleMarkup"
    "\\break" "\\breve" "\\cavum" "\\compressEmptyMeasures" "\\crescHairpin"
    "\\crescTextCresc" "\\deadNotesOff" "\\deadNotesOn" "\\default-language"
    "\\defaultNoteHeads" "\\defaultTimeSignature" "\\deminutum" "\\descendens"
    "\\dimHairpin" "\\dimTextDecr" "\\dimTextDecresc" "\\dimTextDim"
    "\\divisioMaior" "\\divisioMaxima" "\\divisioMinima" "\\dorian" "\\dotsDown"
    "\\dotsNeutral" "\\dotsUp" "\\dynamicDown" "\\dynamicNeutral" "\\dynamicUp"
    "\\easyHeadsOff" "\\easyHeadsOn" "\\endSkipNCs" "\\englishChords"
    "\\expandEmptyMeasures" "\\finalis" "\\fine" "\\flagStyleDefault"
    "\\flagStyleStacked" "\\flexa" "\\frenchChords" "\\funkHeads"
    "\\funkHeadsMinor" "\\germanChords" "\\harmonicsOff" "\\hideNotes"
    "\\hideSplitTiedTabNotes" "\\hideStaffSwitch" "\\huge"
    "\\ignatzekExceptionMusic" "\\iij" "\\IIJ" "\\ij" "\\IJ"
    "\\improvisationOff" "\\improvisationOn" "\\inclinatum" "\\input-file-name"
    "\\ionian" "\\italianChords" "\\kievanOff" "\\kievanOn" "\\large" "\\linea"
    "\\locrian" "\\longa" "\\lydian" "\\major" "\\markLengthOff"
    "\\markLengthOn" "\\maxima" "\\medianChordGridStyle" "\\melisma"
    "\\melismaEnd" "\\mergeDifferentlyDottedOff" "\\mergeDifferentlyDottedOn"
    "\\mergeDifferentlyHeadedOff" "\\mergeDifferentlyHeadedOn" "\\minor"
    "\\mixolydian" "\\newSpacingSection" "\\noBeamBreak" "\\noBreak"
    "\\normalsize" "\\numericTimeSignature" "\\oneVoice" "\\oriscus"
    "\\palmMuteOff" "\\partCombineApart" "\\partCombineAutomatic"
    "\\partCombineChords" "\\partCombineSoloI" "\\partCombineSoloII"
    "\\partCombineUnisono" "\\pes" "\\phrasingSlurDashed" "\\phrasingSlurDotted"
    "\\phrasingSlurDown" "\\phrasingSlurHalfDashed" "\\phrasingSlurHalfSolid"
    "\\phrasingSlurNeutral" "\\phrasingSlurSolid" "\\phrasingSlurUp"
    "\\phrygian" "\\predefinedFretboardsOff" "\\predefinedFretboardsOn"
    "\\quilisma" "\\romanStringNumbers" "\\sacredHarpHeads"
    "\\sacredHarpHeadsMinor" "\\section" "\\semiGermanChords"
    "\\senzaMisuraTimeSignatureOff" "\\senzaMisuraTimeSignatureX"
    "\\setDefaultDurationToQuarter" "\\shiftOff" "\\shiftOn" "\\shiftOnn"
    "\\shiftOnnn" "\\showSplitTiedTabNotes" "\\showStaffSwitch" "\\skipNC"
    "\\skipNCs" "\\slurDashed" "\\slurDotted" "\\slurDown" "\\slurHalfDashed"
    "\\slurHalfSolid" "\\slurNeutral" "\\slurSolid" "\\slurUp" "\\small"
    "\\southernHarmonyHeads" "\\southernHarmonyHeadsMinor"
    "\\startAcciaccaturaMusic" "\\startAppoggiaturaMusic" "\\startGraceMusic"
    "\\startMeasureCount" "\\startMeasureSpanner" "\\startOptionalMaterial"
    "\\startSlashedGraceMusic" "\\startStaff" "\\stemDown" "\\stemNeutral"
    "\\stemUp" "\\stopAcciaccaturaMusic" "\\stopAppoggiaturaMusic"
    "\\stopGraceMusic" "\\stopMeasureCount" "\\stopMeasureSpanner"
    "\\stopOptionalMaterial" "\\stopSlashedGraceMusic" "\\stopStaff"
    "\\stopStaffHighlight" "\\stropha" "\\submeasureBarsOff"
    "\\submeasureBarsOn" "\\tabFullNotation" "\\teeny" "\\textLengthOff"
    "\\textLengthOn" "\\textSpannerDown" "\\textSpannerNeutral"
    "\\textSpannerUp" "\\tieDashed" "\\tieDotted" "\\tieDown" "\\tieHalfDashed"
    "\\tieHalfSolid" "\\tieNeutral" "\\tieSolid" "\\tieUp" "\\tiny"
    "\\tocItemWithDotsMarkup" "\\tupletDown" "\\tupletNeutral" "\\tupletUp"
    "\\unHideNotes" "\\virga" "\\virgula" "\\voiceFour" "\\voiceFourStyle"
    "\\voiceNeutralStyle" "\\voiceOne" "\\voiceOneStyle" "\\voiceThree"
    "\\voiceThreeStyle" "\\voiceTwo" "\\voiceTwoStyle" "\\walkerHeads"
    "\\walkerHeadsMinor" "\\whiteCircleMarkup" "\\whiteTriangleMarkup"
    "\\xNotesOff" "\\xNotesOn"))

((command) @function.builtin
  (#any-of? @function.builtin
    "\\absolute" "\\acciaccatura" "\\accidentalStyle" "\\addChordShape"
    "\\addInstrumentDefinition" "\\addQuote" "\\addToTagGroup" "\\after"
    "\\afterGrace" "\\allowPageTurn" "\\allowVoltaHook" "\\alterBroken"
    "\\ambitusAfter" "\\appendToTag" "\\appendToTagMarkup" "\\applyContext"
    "\\applyMusic" "\\applyOutput" "\\appoggiatura" "\\approximatePitch"
    "\\arpeggioArrowDown" "\\arpeggioArrowUp" "\\arpeggioBracket"
    "\\arpeggioNormal" "\\arpeggioParenthesis" "\\arpeggioParenthesisDashed"
    "\\assertBeamQuant" "\\assertBeamSlope" "\\atLeft" "\\atRight" "\\augmentum"
    "\\autoChange" "\\balloonGrobText" "\\balloonText" "\\bar"
    "\\barNumberCheck" "\\beamExceptions" "\\bendAfter" "\\bendHold"
    "\\bendStartLevel" "\\bookOutputName" "\\bookOutputSuffix"
    "\\breakAlignInsert" "\\breathe" "\\cadenzaOff" "\\cadenzaOn" "\\caesura"
    "\\chordRepeats" "\\clef" "\\codaMark" "\\compressMMRests"
    "\\contextPropertyCheck" "\\crossStaff" "\\cueClef" "\\cueClefUnset"
    "\\cueDuring" "\\cueDuringWithClef" "\\deadNote" "\\defineBarLine"
    "\\displayLilyMusic" "\\displayMusic" "\\displayScheme" "\\dropNote"
    "\\enablePerStaffTiming" "\\endSpanners" "\\eventChords"
    "\\featherDurations" "\\finger" "\\fixed" "\\footnote" "\\grace"
    "\\grobdescriptions" "\\harmonicByFret" "\\harmonicByRatio" "\\harmonicNote"
    "\\harmonicsOn" "\\hide" "\\incipit" "\\inherit-acceptability"
    "\\initialContextFrom" "\\inStaffSegno" "\\instrumentSwitch" "\\inversion"
    "\\invertChords" "\\jump" "\\keepWithTag" "\\key" "\\killCues" "\\label"
    "\\language" "\\languageRestore" "\\languageSaveAndChange" "\\ligature"
    "\\magnifyMusic" "\\magnifyStaff" "\\makeClusters"
    "\\makeDefaultStringTuning" "\\mark" "\\markupMap" "\\measure"
    "\\measureRemainder" "\\modalInversion" "\\modalTranspose" "\\musicLength"
    "\\musicMap" "\\noPageBreak" "\\noPageTurn" "\\noStanza" "\\octaveCheck"
    "\\offset" "\\omit" "\\once" "\\ottava" "\\overrideProperty"
    "\\overrideTimeSignatureSettings" "\\pageBreak" "\\pageTurn" "\\palmMute"
    "\\palmMuteOn" "\\parallelMusic" "\\parenthesize" "\\partCombine"
    "\\partCombineDown" "\\partCombineForce" "\\partCombineUp" "\\partial"
    "\\phrasingSlurDashPattern" "\\pitchedTrill" "\\pointAndClickOff"
    "\\pointAndClickOn" "\\pointAndClickTypes" "\\polymetric"
    "\\popContextProperty" "\\preBend" "\\preBendHold" "\\premeasure"
    "\\propertyOverride" "\\propertyRevert" "\\propertySet" "\\propertyTweak"
    "\\propertyUnset" "\\pushContextProperty" "\\pushToTag" "\\pushToTagMarkup"
    "\\quoteDuring" "\\raiseNote" "\\reduceChords" "\\relative"
    "\\removeFromTagGroup" "\\removeWithTag" "\\replaceWithTag"
    "\\replaceWithTagMarkup" "\\resetRelativeOctave" "\\resetTagGroup"
    "\\resetTagGroups" "\\responsum" "\\retrograde"
    "\\revertTimeSignatureSettings" "\\rightHandFinger" "\\scaleDurations"
    "\\sectionLabel" "\\segnoMark" "\\senzaMisura" "\\setDefaultMeasureLength"
    "\\setMeasureLengthFromHere" "\\shape" "\\shiftDurations" "\\single"
    "\\skip" "\\slashedGrace" "\\slurDashPattern" "\\staffHighlight" "\\stanza"
    "\\startGradualTempoChange" "\\stopGradualTempoChange"
    "\\storePredefinedDiagram" "\\stringTuning" "\\styledNoteHeads"
    "\\tabChordRepeats" "\\tabChordRepetition" "\\tag" "\\tagGroup"
    "\\tagGroupRef" "\\temporary" "\\textEndMark" "\\textMark"
    "\\tieDashPattern" "\\time" "\\timeAbbrev" "\\times" "\\tocItem"
    "\\transpose" "\\transposedCueDuring" "\\transposition" "\\tuplet"
    "\\tupletSpan" "\\tweak" "\\undo" "\\unfolded" "\\unfoldRepeats"
    "\\verboseBarNumbers" "\\versus" "\\voices" "\\void" "\\volta" "\\vshape"
    "\\withMusicProperty" "\\withRelativeDir" "\\xNote"))

((command) @type.builtin
  (#any-of? @type.builtin
    "\\ChoirStaff" "\\ChordGrid" "\\ChordGridScore" "\\ChordNames" "\\CueVoice"
    "\\Devnull" "\\DrumStaff" "\\DrumVoice" "\\Dynamics"
    "\\EnableGregorianDivisiones" "\\FiguredBass" "\\FretBoards" "\\Global"
    "\\GrandStaff" "\\GregorianTranscriptionLyrics"
    "\\GregorianTranscriptionStaff" "\\GregorianTranscriptionVoice"
    "\\InternalGregorianStaff" "\\InternalMensuralStaff" "\\KievanStaff"
    "\\KievanVoice" "\\Lyrics" "\\MensuralStaff" "\\MensuralVoice" "\\NoteNames"
    "\\NullVoice" "\\OneStaff" "\\PetrucciStaff" "\\PetrucciVoice"
    "\\PianoStaff" "\\RemoveAllEmptyStaves" "\\RemoveEmptyStaves"
    "\\RhythmicStaff" "\\Score" "\\Staff" "\\StaffGroup"
    "\\StandaloneRhythmScore" "\\StandaloneRhythmStaff"
    "\\StandaloneRhythmVoice" "\\TabStaff" "\\TabVoice" "\\VaticanaLyrics"
    "\\VaticanaScore" "\\VaticanaStaff" "\\VaticanaVoice" "\\Voice"))
; END GENERATED builtins

; Optional packages, available after \include "<package>.ly".
; BEGIN GENERATED packages (scripts/update-builtins.js)
; arabic.ly
((command) @constant.builtin
  (#any-of? @constant.builtin
    "\\bayati" "\\dwn" "\\hijaz" "\\hijaz_kar" "\\huzam" "\\iraq" "\\kurd"
    "\\nakriz" "\\rast" "\\sikah"))

; articulate.ly
((command) @function.builtin
  (#any-of? @function.builtin
    "\\articulate"))

; bagpipe.ly
((command) @constant.builtin
  (#any-of? @constant.builtin
    "\\bari" "\\barluadh" "\\barluadhG" "\\bgrip" "\\birl" "\\btaor" "\\cad"
    "\\catcha" "\\catchb" "\\catchc" "\\catchd" "\\catche" "\\crun" "\\crunamb"
    "\\crunambfosg" "\\crunamc" "\\crunamcfosg" "\\crunamd" "\\crunamdfosg"
    "\\dare" "\\dari" "\\darodo" "\\dbirl" "\\dbla" "\\dblA" "\\dblb" "\\dblc"
    "\\dbld" "\\dble" "\\dblf" "\\dblg" "\\dblG" "\\dcrun" "\\dre" "\\egrip"
    "\\fifteenthcutting" "\\fifteenthcuttingG" "\\Gbarluadh" "\\GbarluadhG"
    "\\gbirl" "\\Gcrun" "\\Gdarodo" "\\Gfifteenthcutting" "\\GfifteenthcuttingG"
    "\\gra" "\\grA" "\\gracad" "\\grb" "\\grc" "\\grd" "\\gre" "\\grf" "\\grg"
    "\\grG" "\\grGcad" "\\grip" "\\gripthrwd" "\\Gseventeenthcutting"
    "\\GseventeenthcuttingG" "\\Gtaor" "\\Gthrwd" "\\halfBeaming" "\\hcad"
    "\\hcatcha" "\\hcatchb" "\\hcatchc" "\\hcatchd" "\\hcatche" "\\hdbla"
    "\\hdblA" "\\hdblb" "\\hdblc" "\\hdbld" "\\hdble" "\\hdblf" "\\hdblg"
    "\\hdblG" "\\hideKeySignature" "\\hshakea" "\\hshakeA" "\\hshakeb"
    "\\hshakec" "\\hshaked" "\\hshakee" "\\hshakef" "\\hshakeg" "\\hslura"
    "\\hslurA" "\\hslurb" "\\hslurc" "\\hslurd" "\\hslure" "\\hslurf" "\\hslurg"
    "\\marchTime" "\\pdarodo" "\\pGdarodo" "\\pthrwd" "\\quarterBeaming"
    "\\reelTime" "\\seventeenthcutting" "\\seventeenthcuttingG" "\\shakea"
    "\\shakeA" "\\shakeb" "\\shakec" "\\shaked" "\\shakee" "\\shakef" "\\shakeg"
    "\\showKeySignature" "\\slura" "\\slurA" "\\slurb" "\\slurc" "\\slurd"
    "\\slure" "\\slurf" "\\slurg" "\\taor" "\\taoramb" "\\taoramc" "\\taoramd"
    "\\taorjmd" "\\taorold" "\\tcad" "\\tcatcha" "\\tcatchb" "\\tcatchc"
    "\\tcatchd" "\\tcatche" "\\tdbla" "\\tdblb" "\\tdblc" "\\tdbld" "\\tdble"
    "\\tdblf" "\\tdblg" "\\tdblG" "\\thcad" "\\thrwd" "\\thrwe" "\\thrwf"
    "\\trebling" "\\tripleA" "\\tshakea" "\\tshakeA" "\\tshakeb" "\\tshakec"
    "\\tshaked" "\\tshakee" "\\tshakef" "\\tshakeg" "\\tslura" "\\tslurA"
    "\\tslurb" "\\tslurc" "\\tslurd" "\\tslure" "\\tslurf" "\\tslurg" "\\txcrun"
    "\\txcrunam" "\\txtaor" "\\txtaoram" "\\txtaorcrun" "\\txtaorcrunam"
    "\\wbirl" "\\wcatchd" "\\whcatchd" "\\whshaked" "\\whslurd" "\\wshaked"
    "\\wslurd" "\\wtcatchd" "\\wthrwe" "\\wtshaked" "\\wtslurd"))

((command) @function.builtin
  (#any-of? @function.builtin
    "\\pgrace" "\\stemspace"))

; hel-arabic.ly
((command) @constant.builtin
  (#any-of? @constant.builtin
    "\\bayati" "\\dwn" "\\hijaz" "\\hijaz_kar" "\\hizaz" "\\houssaini" "\\huzam"
    "\\iraq" "\\jaharkah" "\\karjkhar" "\\kurd" "\\nahawande" "\\nakriz"
    "\\nawaatar" "\\rast" "\\saba" "\\sikah" "\\souznak"))

; persian.ly
((command) @constant.builtin
  (#any-of? @constant.builtin
    "\\chahargah" "\\delkashMahur" "\\esfahan" "\\mahur" "\\mokhalefsegah"
    "\\persianAltKeyAlterationOrder" "\\persianKeyAlterationOrder" "\\shur"
    "\\shurGvlat" "\\shurk"))

; swing.ly
((command) @function.builtin
  (#any-of? @function.builtin
    "\\applySwing" "\\applySwingWithOffset" "\\tripletFeel"))

; turkish-makam.ly
((command) @constant.builtin
  (#any-of? @constant.builtin
    "\\acem" "\\acemasiran" "\\acembuselik" "\\acemkurdi" "\\acemliyegah"
    "\\anberefsan" "\\arabanbuselik" "\\aramican" "\\arazbar" "\\arazbarbuselik"
    "\\arazbarek" "\\arazbarzemzeme" "\\askevza" "\\bahrinazik" "\\bendihisar"
    "\\bestehicaz" "\\bestehisar" "\\besteisfahan" "\\bestenigar" "\\beyati"
    "\\beyatiaraban" "\\beyatiarabanbuselik" "\\beyatibuselik"
    "\\beyatiruyiacem" "\\bezmitarab" "\\buselik" "\\buselikasiran" "\\buzurk"
    "\\canfeza" "\\cargah" "\\cargaheski" "\\dilefruz" "\\dilfuruz" "\\dilkes"
    "\\dilkeshaveran" "\\dilkeside" "\\dilkusa" "\\dilnevaz" "\\dilnisin"
    "\\dugah" "\\dugahbuselik" "\\dugahmaye" "\\eskisipihr" "\\evcara"
    "\\evcibahrinazik" "\\evciruyineva" "\\evcisevk" "\\evic" "\\evicbuselik"
    "\\evichuzi" "\\evicmaye" "\\ferahfeza" "\\ferahnak" "\\ferahnakasiran"
    "\\ferahnuma" "\\fethibelgrad" "\\fethidil" "\\feyziyekta" "\\gerdaniye"
    "\\gerdaniyebuselik" "\\gerdaniyekurdi" "\\gestuguzaribahar" "\\gevest"
    "\\gulbuse" "\\guldeste" "\\gulizar" "\\gulsenivefa" "\\hicaz"
    "\\hicazasiran" "\\hicazbuselik" "\\hicazeyn" "\\hicazhumayun" "\\hicazirak"
    "\\hicazkar" "\\hicazuzzal" "\\hicazzemzeme" "\\hicazzirgule" "\\hisar"
    "\\hisarbuselik" "\\hisarvechisehnaz" "\\horasan" "\\hosaver" "\\huseyni"
    "\\huseyniaraban" "\\huseyniasiran" "\\huseynizemzeme" "\\huzi" "\\huzzam"
    "\\irak" "\\irakasiran" "\\isfahan" "\\isfahanek" "\\isfahanruyineva"
    "\\karcigar" "\\kucek" "\\kurdi" "\\kurdilihicazkar" "\\lalegul" "\\mahur"
    "\\mahurbuselik" "\\mahurhan" "\\maveraunnehir" "\\mayeasiran" "\\muberka"
    "\\muhalif" "\\muhalifiirak" "\\muhayyer" "\\muhayyerbuselik"
    "\\muhayyerkurdi" "\\muhayyersunbule" "\\muhayyerzirgule" "\\mustear"
    "\\narefte" "\\neva" "\\nevabagdat" "\\nevabuselik" "\\nevadilkes"
    "\\nevakurdi" "\\neveda" "\\neveser" "\\nevkes" "\\nevruz" "\\nevruzirumi"
    "\\nigar" "\\nihavend" "\\nihavendikebir" "\\nikriz" "\\nisabur"
    "\\nisaburek" "\\nisaburrumi" "\\nuhuft" "\\pencgah" "\\pesendide"
    "\\peykinesat" "\\peykisafa" "\\rahatulervah" "\\rast" "\\rastasiran"
    "\\rasthaveran" "\\rasticedid" "\\rastisagir" "\\rastmaye" "\\rehavi"
    "\\rekbizavil" "\\rengidil" "\\revnaknuma" "\\ruhnuvaz" "\\ruyidilara"
    "\\ruyiirak" "\\saba" "\\sabaasiran" "\\sababuselik" "\\sabazemzeme"
    "\\sazkar" "\\sedaraban" "\\segah" "\\segaharaban" "\\segahmaye" "\\sehnaz"
    "\\sehnazasiran" "\\sehnazbuselik" "\\sehnazhaveran" "\\selmek"
    "\\serefnuma" "\\sevkaver" "\\sevkefza" "\\sevkicihan" "\\sevkidil"
    "\\sevkiserab" "\\sevkitarab" "\\sevkutarab" "\\sipihr" "\\sivenuma"
    "\\sultanicedid" "\\sultaniirak" "\\sultanirast" "\\sultanisegah"
    "\\sultaniyegah" "\\suzidil" "\\suzidilara" "\\suznak" "\\tahir"
    "\\tahirbuselik" "\\tarabengiz" "\\tarzicedid" "\\tarzicihan" "\\tarzinevin"
    "\\tavrinihavend" "\\tebriz" "\\ussak" "\\ussakasiran" "\\uzzal"
    "\\vecdidil" "\\vechiarazbar" "\\yegah" "\\yenisipihr" "\\zavil"
    "\\zavilasiran" "\\zevkidil" "\\zirefkend" "\\zirgulelisuznak"))
; END GENERATED packages

; Markup commands.
; BEGIN GENERATED markup-commands (scripts/update-builtins.js)
(markup_command
  name: (command) @function.builtin
  (#any-of? @function.builtin
    "\\abs-fontsize" "\\abs-hspace" "\\abs-vspace" "\\accidental"
    "\\align-on-other" "\\annotate-moving" "\\append-to-tag" "\\arrow-head"
    "\\auto-footnote" "\\backslashed-digit" "\\bar-line" "\\beam" "\\bold"
    "\\box" "\\bracket" "\\caps" "\\center-align" "\\center-column" "\\char"
    "\\circle" "\\coda" "\\column" "\\column-lines" "\\combine"
    "\\compound-meter" "\\concat" "\\conditional-trill-markup" "\\customTabClef"
    "\\dir-column" "\\doubleflat" "\\doublesharp" "\\draw-circle"
    "\\draw-dashed-line" "\\draw-dotted-line" "\\draw-hline" "\\draw-line"
    "\\draw-squiggle-line" "\\dynamic" "\\ellipse" "\\epsfile" "\\eyeglasses"
    "\\fermata" "\\figured-bass" "\\fill-line" "\\fill-with-pattern"
    "\\filled-box" "\\finger" "\\first-visible" "\\flat" "\\font-select"
    "\\fontCaps" "\\fontsize" "\\footnote" "\\fraction" "\\fret-diagram"
    "\\fret-diagram-terse" "\\fret-diagram-verbose" "\\fromproperty"
    "\\general-align" "\\halign" "\\harp-pedal" "\\hbracket" "\\hcenter-in"
    "\\hspace" "\\huge" "\\if" "\\image" "\\italic" "\\justified-lines"
    "\\justify" "\\justify-field" "\\justify-line" "\\justify-string"
    "\\keep-with-tag" "\\large" "\\larger" "\\left-align" "\\left-brace"
    "\\left-column" "\\line" "\\lookup" "\\lower" "\\magnify"
    "\\map-markup-commands" "\\markalphabet" "\\markletter"
    "\\multi-measure-rest-by-number" "\\musicglyph" "\\natural"
    "\\normal-size-sub" "\\normal-size-super" "\\normal-text" "\\normal-weight"
    "\\normalsize" "\\note" "\\note-by-number" "\\null" "\\number"
    "\\on-the-fly" "\\oval" "\\overlay" "\\override" "\\override-lines"
    "\\overtie" "\\pad-around" "\\pad-markup" "\\pad-to-box" "\\pad-x"
    "\\pad-x-left" "\\pad-x-right" "\\page-link" "\\page-ref" "\\parenthesize"
    "\\path" "\\pattern" "\\polygon" "\\postscript" "\\property-recursive"
    "\\push-to-tag" "\\put-adjacent" "\\qr-code" "\\raise" "\\remove-with-tag"
    "\\replace" "\\replace-with-tag" "\\rest" "\\rest-by-number" "\\rhythm"
    "\\right-align" "\\right-brace" "\\right-column" "\\rotate" "\\rounded-box"
    "\\sans" "\\scale" "\\score" "\\score-lines" "\\segno" "\\semiflat"
    "\\semisharp" "\\serif" "\\sesquiflat" "\\sesquisharp" "\\sharp" "\\simple"
    "\\slashed-digit" "\\small" "\\smallCaps" "\\smaller" "\\stencil"
    "\\string-lines" "\\strut" "\\sub" "\\super" "\\table"
    "\\table-of-contents-markup-list" "\\tag" "\\tag-list" "\\teeny"
    "\\text-accidental" "\\text-common-time" "\\text-cut-time"
    "\\text-doubleflat" "\\text-doublesharp" "\\text-flat" "\\text-natural"
    "\\text-sharp" "\\tie" "\\tied-lyric" "\\tiny" "\\translate"
    "\\translate-scaled" "\\transparent" "\\triangle" "\\typewriter"
    "\\underline" "\\undertie" "\\unless" "\\upright" "\\varcoda" "\\vcenter"
    "\\verbatim-file" "\\volta-number" "\\vspace" "\\whiteout" "\\with-color"
    "\\with-dimension" "\\with-dimension-from" "\\with-dimensions"
    "\\with-dimensions-from" "\\with-link" "\\with-outline"
    "\\with-string-transformer" "\\with-true-dimension" "\\with-true-dimensions"
    "\\with-url" "\\woodwind-diagram" "\\wordwrap" "\\wordwrap-field"
    "\\wordwrap-internal" "\\wordwrap-lines" "\\wordwrap-string"
    "\\wordwrap-string-internal"))
; END GENERATED markup-commands

; =============================================================================
; Punctuation
; =============================================================================

[
  "{"
  "}"
  "<<"
  ">>"
] @punctuation.bracket

(chord
  [
    "<"
    ">"
  ] @punctuation.bracket)

(figure_group
  [
    "<"
    ">"
  ] @punctuation.bracket)

(figure
  [
    "["
    "]"
  ] @punctuation.bracket)

(scheme_list
  [
    "("
    ")"
    "["
    "]"
  ] @punctuation.bracket)

(scheme_vector
  [
    "#("
    "#u8("
    "#vu8("
    ")"
  ] @punctuation.bracket)
