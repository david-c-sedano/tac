package main

import "core:fmt"
import "core:strings"
import "core:strconv"
import "core:unicode"

TokenKind :: enum {
    Invalid, Entry, Comment, Name, Colon, Assign, 
    Add, Sub, Mul, Div, Push, Pop, Comma, Goto,
    Branch, Ret, Call, Eq, NotEq, Lt, Gt, LtEq, 
    GtEq, Print, RawPrint, EndLine,
} 
Token :: union { TokenKind, string, int }

MatchKeyword :: proc(input: []u8) -> Token {
    s := string(input)

    match :: proc(input: string, keyword: string) -> bool 
    { return strings.compare(input, keyword) == 0 }

    switch {
        case match(s, "entry"):     return .Entry
        case match(s, "push"):      return .Push
        case match(s, "pop"):       return .Pop
        case match(s, "goto"):      return .Goto
        case match(s, "if"):        return .Branch
        case match(s, "call"):      return .Call
        case match(s, "return"):    return .Ret
        case match(s, "print"):     return .Print
        case match(s, "raw_print"): return .RawPrint
    }
    return .Invalid
}

MatchDoubleChar :: proc(c1: u8, c2: u8) -> Token {
    switch { 
        case c1 == '/' && c2 == '/': return .Comment
        case c1 == '=' && c2 == '=': return .Eq
        case c1 == '!' && c2 == '=': return .NotEq
        case c1 == '<' && c2 == '=': return .LtEq
        case c1 == '>' && c2 == '=': return .GtEq
    }
    return .Invalid
}

MatchChar :: proc(c: u8) -> Token {
    switch {
        case c == ':':  return .Colon
        case c == '=':  return .Assign
        case c == '+':  return .Add
        case c == '-':  return .Sub
        case c == '*':  return .Mul
        case c == '/':  return .Div
        case c == ',':  return .Comma
        case c == '<':  return .Lt
        case c == '>':  return .Gt
        case c == '\n': return .EndLine
    }
    return .Invalid
}

Span :: proc(input: []u8, predicate: proc(rune) -> bool) -> []u8 {
    sb := strings.builder_make()
    for c in input {
        c := rune(c)
        if predicate(c) do strings.write_rune(&sb, c)
        if !predicate(c) do break
    }
    str := strings.to_string(sb)
    result := make([]u8, len(str))
    copy_from_string(result, str)
    return result
}

// to be used with Span()
Alphanumeric :: proc(c: rune) -> bool {
    return unicode.is_letter(c) || unicode.is_number(c) || c == '_'
}

EndLine :: proc(c: rune) -> bool { 
    if c == '\n' do return false
    return true
}

Tokenize :: proc(input: []u8, tokens: ^[dynamic]Token) {
    if len(input) == 0 do return

    advance :: proc(input: []u8, amount: int) -> []u8 {
        return input[amount:]
    }

    x := rune(input[0]); xs := input[1:]
    lookahead := input[1] if len(input) > 2 else 0 
    switch {
        case unicode.is_white_space(x):
            Tokenize(xs, tokens)

        case unicode.is_lower(x) || x == '_':
            word := Span(input, Alphanumeric)
            keyword := MatchKeyword(word)
            if keyword != .Invalid {
                append(tokens, keyword)
                Tokenize(advance(input, len(word)), tokens)
            } else {
                append(tokens, string(word))
                Tokenize(advance(input, len(word)), tokens)
            }

        case unicode.is_digit(x):
            int_literal := Span(input, unicode.is_digit)
            token := strconv.atoi(string(int_literal))
            append(tokens, token)
            Tokenize(advance(input, len(int_literal)), tokens)

        case lookahead != 0:
            token := MatchDoubleChar(u8(x), lookahead)
            if token != .Invalid {
                if token == .Comment {
                    // skip to the end of the line
                    span := len(Span(input, EndLine)) + 1 // add one to account for newline
                    Tokenize(advance(input, span), tokens) 
                    return
                }
                append(tokens, token)
                Tokenize(advance(input, 2), tokens)
                return
            }
            fallthrough

        case:
            token := MatchChar(u8(x))
            if token == .Invalid do fmt.println("unexpected char %r ~", x)
            append(tokens, token)
            Tokenize(xs, tokens)
    }
}
