//! This crate provides [LilyPond] language support for the [tree-sitter]
//! parsing library.
//!
//! Typically, you will use the [`LANGUAGE`] constant to add this language to a
//! tree-sitter [`Parser`], and then use the parser to parse some code:
//!
//! ```
//! let code = r#"
//! \version "2.24.0"
//! melody = \relative c'' {
//!   \key g \major \time 3/4
//!   g4.( a8) b4 | c2.~ c4 r8 <d fis>4\p\< e-1 |
//! }
//! \score { \new Staff \melody }
//! "#;
//! let mut parser = tree_sitter::Parser::new();
//! let language = tree_sitter_lilypond::LANGUAGE;
//! parser
//!     .set_language(&language.into())
//!     .expect("Error loading LilyPond parser");
//! let tree = parser.parse(code, None).unwrap();
//! assert!(!tree.root_node().has_error());
//! ```
//!
//! [LilyPond]: https://lilypond.org/
//! [`Parser`]: https://docs.rs/tree-sitter/0.27.2/tree_sitter/struct.Parser.html
//! [tree-sitter]: https://tree-sitter.github.io/

use tree_sitter_language::LanguageFn;

unsafe extern "C" {
    fn tree_sitter_lilypond() -> *const ();
}

/// The tree-sitter [`LanguageFn`] for this grammar.
pub const LANGUAGE: LanguageFn = unsafe { LanguageFn::from_raw(tree_sitter_lilypond) };

/// The content of the [`node-types.json`] file for this grammar.
///
/// [`node-types.json`]: https://tree-sitter.github.io/tree-sitter/using-parsers/6-static-node-types
pub const NODE_TYPES: &str = include_str!("../../src/node-types.json");

#[cfg(with_highlights_query)]
/// The syntax highlighting query for this grammar.
pub const HIGHLIGHTS_QUERY: &str = include_str!("../../queries/highlights.scm");

#[cfg(with_injections_query)]
/// The language injection query for this grammar.
pub const INJECTIONS_QUERY: &str = include_str!("../../queries/injections.scm");

#[cfg(with_locals_query)]
/// The local variable query for this grammar.
pub const LOCALS_QUERY: &str = include_str!("../../queries/locals.scm");

#[cfg(with_tags_query)]
/// The symbol tagging query for this grammar.
pub const TAGS_QUERY: &str = include_str!("../../queries/tags.scm");

/// The code folding query for this grammar.
pub const FOLDS_QUERY: &str = include_str!("../../queries/folds.scm");

/// The indentation query for this grammar.
pub const INDENTS_QUERY: &str = include_str!("../../queries/indents.scm");

#[cfg(test)]
mod tests {
    use tree_sitter::{Parser, Query, Tree};

    fn parse(code: &str) -> Tree {
        let mut parser = Parser::new();
        parser
            .set_language(&super::LANGUAGE.into())
            .expect("Error loading LilyPond parser");
        parser.parse(code, None).unwrap()
    }

    fn assert_parses(name: &str, code: &str) {
        let tree = parse(code);
        let root = tree.root_node();
        assert!(!root.has_error(), "{name}: {}", root.to_sexp());
    }

    #[test]
    fn test_can_load_grammar() {
        parse("");
    }

    #[test]
    fn test_examples_parse_without_errors() {
        for (name, code) in [
            ("minuet.ly", include_str!("../../examples/minuet.ly")),
            ("lyrics.ly", include_str!("../../examples/lyrics.ly")),
            ("chords.ly", include_str!("../../examples/chords.ly")),
            ("piano.ly", include_str!("../../examples/piano.ly")),
            ("functions.ly", include_str!("../../examples/functions.ly")),
        ] {
            assert_parses(name, code);
        }
    }

    #[test]
    fn test_markup_commands_use_their_signature() {
        let tree = parse(r"\markup \fontsize #2 \bold { a b } x");
        let markup = tree.root_node().child(0).unwrap();
        let command = markup.child_by_field_name("content").unwrap();
        assert_eq!(command.kind(), "markup_command");
        // \fontsize takes a number and a markup, and \bold takes a markup:
        // `x` is left out.
        assert_eq!(command.children_by_field_name("argument", &mut command.walk()).count(), 2);
        assert_eq!(tree.root_node().named_child_count(), 2);
    }

    #[test]
    fn test_queries_are_valid() {
        let language = super::LANGUAGE.into();
        for (name, source) in [
            ("highlights", super::HIGHLIGHTS_QUERY),
            ("injections", super::INJECTIONS_QUERY),
            ("locals", super::LOCALS_QUERY),
            ("tags", super::TAGS_QUERY),
            ("folds", super::FOLDS_QUERY),
            ("indents", super::INDENTS_QUERY),
        ] {
            if let Err(error) = Query::new(&language, source) {
                panic!("{name}.scm: {error}");
            }
        }
    }
}
