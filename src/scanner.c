/**
 * External scanner for tree-sitter-lilypond.
 *
 * Inside markup, it recognizes the built-in markup commands (\bold,
 * \fontsize, \fromproperty, …) and returns a token that tells the parser how
 * many Scheme and markup arguments the command takes. Other commands are left
 * to the internal lexer, which returns them as generic commands.
 */

#include "tree_sitter/parser.h"

#include <stdint.h>
#include <string.h>

#include "markup_commands.h"

enum TokenType {
    // MARKUP_SIGNATURE_COUNT tokens, one per signature, in the order of
    // MARKUP_SIGNATURES in grammar.js.
    ERROR_SENTINEL = MARKUP_SIGNATURE_COUNT,
};

// Longest built-in markup command name, plus room for the terminating null.
#define MAX_NAME_LENGTH 64

void *tree_sitter_lilypond_external_scanner_create(void) { return NULL; }

void tree_sitter_lilypond_external_scanner_destroy(void *payload) { (void)payload; }

unsigned tree_sitter_lilypond_external_scanner_serialize(void *payload, char *buffer) {
    (void)payload;
    (void)buffer;
    return 0;
}

void tree_sitter_lilypond_external_scanner_deserialize(void *payload, const char *buffer,
                                                       unsigned length) {
    (void)payload;
    (void)buffer;
    (void)length;
}

// LilyPond's lexer treats every non-ASCII character as a letter.
static inline bool is_letter(int32_t c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c >= 0x80;
}

static inline bool is_space(int32_t c) {
    return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' || c == '\v' ||
           c == 0xFEFF;
}

static int find_markup_command(const char *name) {
    size_t low = 0;
    size_t high = sizeof(MARKUP_COMMANDS) / sizeof(MARKUP_COMMANDS[0]);
    while (low < high) {
        size_t middle = low + (high - low) / 2;
        int comparison = strcmp(name, MARKUP_COMMANDS[middle].name);
        if (comparison == 0) {
            return MARKUP_COMMANDS[middle].signature;
        }
        if (comparison < 0) {
            high = middle;
        } else {
            low = middle + 1;
        }
    }
    return -1;
}

bool tree_sitter_lilypond_external_scanner_scan(void *payload, TSLexer *lexer,
                                                const bool *valid_symbols) {
    (void)payload;

    // During error recovery every token is valid: let the internal lexer
    // decide.
    if (valid_symbols[ERROR_SENTINEL]) {
        return false;
    }

    bool in_markup = false;
    for (int i = 0; i < MARKUP_SIGNATURE_COUNT; i++) {
        if (valid_symbols[i]) {
            in_markup = true;
            break;
        }
    }
    if (!in_markup) {
        return false;
    }

    while (is_space(lexer->lookahead)) {
        lexer->advance(lexer, true);
    }
    if (lexer->lookahead != '\\') {
        return false;
    }
    lexer->advance(lexer, false);

    // A command name is LilyPond's {SYMBOL}: letters, with single `-` or `_`
    // between letters.
    char name[MAX_NAME_LENGTH];
    size_t length = 0;
    if (!is_letter(lexer->lookahead)) {
        return false;
    }
    for (;;) {
        while (is_letter(lexer->lookahead)) {
            // Built-in names are ASCII: anything else is not one of them.
            if (lexer->lookahead >= 0x80 || length + 1 >= MAX_NAME_LENGTH) {
                return false;
            }
            name[length++] = (char)lexer->lookahead;
            lexer->advance(lexer, false);
        }
        lexer->mark_end(lexer);
        if (lexer->lookahead != '-' && lexer->lookahead != '_') {
            break;
        }
        char separator = (char)lexer->lookahead;
        lexer->advance(lexer, false);
        if (!is_letter(lexer->lookahead)) {
            // The separator is not part of the name.
            break;
        }
        if (length + 1 >= MAX_NAME_LENGTH) {
            return false;
        }
        name[length++] = separator;
    }
    name[length] = '\0';

    int signature = find_markup_command(name);
    if (signature < 0 || !valid_symbols[signature]) {
        return false;
    }
    lexer->result_symbol = (TSSymbol)signature;
    return true;
}
