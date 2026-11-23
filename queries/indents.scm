[
  (header_block)
  (book_block)
  (bookpart_block)
  (score_block)
  (paper_block)
  (layout_block)
  (midi_block)
  (context_definition)
  (with_block)
  (sequential_music)
  (simultaneous_music)
  (markup_list)
  (embedded_lilypond)
  (scheme_list)
  (scheme_vector)
] @indent.begin

[
  "}"
  ">>"
  "#}"
] @indent.branch @indent.end

(scheme_list
  ")" @indent.branch @indent.end)

(scheme_list
  "]" @indent.branch @indent.end)

(scheme_vector
  ")" @indent.branch @indent.end)

[
  (string)
  (scheme_string)
] @indent.ignore

(comment) @indent.auto
