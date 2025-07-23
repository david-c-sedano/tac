package main
// we do not do any heavy parsing, no trees
// this is just to make the "evaluator" easier to read

import "core:fmt"

Label    :: distinct string
Call     :: distinct string
Return   :: distinct TokenKind
Print    :: distinct int
RawPrint :: distinct int
Assign :: struct {
    target: string,
    left:   union{string, int},
    op:     TokenKind,
    right:  union{string, int},
}
StackOp :: struct {
    kind:     TokenKind,
    operands: []union{string, int}
}
Goto :: struct {
    dest:      string,
    branching: bool,
    left:      union{string, int},
    comp:      TokenKind,
    right:     union{string, int},
}
// the end result is literally just an array of these "Statements", NO TREES!!
Stat :: union { Label, Call, Return, Print, RawPrint, Assign, StackOp, Goto, }

// look ahead and ensure tokens are correct
// these are helper funcs
ValidateTokens :: proc(tokens: ^[dynamic]Token, expected: [][]TokenKind) -> (matches: int, succ: bool) {
    for tuple, i in expected {
        succ = false
        token := tokens[i]
        inner: for match in tuple {
            if token.kind == match { 
                succ = true; break inner 
            }
        }
        if !succ do return
        matches += 1
    }
    return
}

// these type casts on the unions were giving me problems,
// anyways this is the highest form of print debugging, passing #caller_location and printing that
// Odin is actually a goated programming language, though proper debuggers are still better
GetTokenData :: proc(token: Token, loc := #caller_location) -> union{string, int} {
    if str, ok := token.data.(string); ok { 
        return str 
    } else { 
        if num, ok := token.data.(int); ok {
            return num
        } else {
            fmt.println("string_or_int fail", loc)
            panic := token.data.(int)
            return '?'
        }
    }
}

DiscardTokens :: proc(tokens: ^[dynamic]Token, amount: int) {
    for i in 0..<amount do pop_front(tokens)
}

// now time for parsing
ParseLabel :: proc(tokens: ^[dynamic]Token) -> (Label, bool) {
    if matches, ok := ValidateTokens(
        tokens, 
        {
            {.Ident}, 
            {.Colon}
        }
    ); ok {
        label := Label(tokens[0].data.(string))
        DiscardTokens(tokens, matches)
        return label, true
    }
    return {}, false
}

ParseCall :: proc(tokens: ^[dynamic]Token) -> (Call, bool) {
    if matches, ok := ValidateTokens(
        tokens, 
        {
            {.Call}, 
            {.Ident}
        }
    ); ok {
        call := Call(tokens[1].data.(string))
        DiscardTokens(tokens, matches)
        return call, true
    }
    return {}, false
}

ParseReturn :: proc(tokens: ^[dynamic]Token) -> (Return, bool) {
    if matches, ok := ValidateTokens(
        tokens, 
        {
            {.Ret}
        }
    ); ok {
        ret := Return(tokens[0].kind)
        DiscardTokens(tokens, matches)
        return ret, true
    }
    return {}, false
}

ParsePrint :: proc(tokens: ^[dynamic]Token) -> (Print, bool) {
    if matches, ok := ValidateTokens(
        tokens, 
        {
            {.Print}, 
            {.IntLit}
        }
    ); ok {
        amount := Print(tokens[1].data.(int))
        DiscardTokens(tokens, matches)
        return amount, true
    } 
    return {}, false
}

ParseRawPrint :: proc(tokens: ^[dynamic]Token) -> (RawPrint, bool) {
    if matches, ok := ValidateTokens(
        tokens, 
        {
            {.RawPrint}, 
            {.IntLit}
        }
    ); ok {
        amount := RawPrint(tokens[1].data.(int))
        DiscardTokens(tokens, matches)
        return amount, true
    }
    return {}, false
}

ParseAssign :: proc(tokens: ^[dynamic]Token) -> (assign: Assign, succ: bool) {
    if matches, ok := ValidateTokens(
        tokens, 
        {
            {.Ident}, 
            {.Assign}, 
            {.Ident, .IntLit}, 
        }
    ); ok {
        succ = true
        assign.target = tokens[0].data.(string)
        assign.left   = GetTokenData(tokens[2]) 
        DiscardTokens(tokens, matches)

        if matches, ok := ValidateTokens(
            tokens, 
            {
                {.Add, .Sub, .Mul, .Div}, 
                {.Ident, .IntLit},
            },
        ); ok {
            assign.op     = tokens[0].kind
            assign.right  = GetTokenData(tokens[1]) 
            DiscardTokens(tokens, matches)
        }
    }
    return
}

ParseStackOp :: proc(tokens: ^[dynamic]Token) -> (stackop: StackOp, succ: bool) {
    if matches, ok := ValidateTokens(
        tokens, 
        {
            {.Push, .Pop},
            {.IntLit, .Ident}
        }
    ); ok {
        succ = true
        stackop.kind = tokens[0].kind
        operands: [dynamic]union{string, int}
        append(&operands, GetTokenData(tokens[1]))
        DiscardTokens(tokens, matches)
    
        loop: for {
            if matches, ok := ValidateTokens(
                tokens,
                {
                    {.Comma},
                    {.IntLit, .Ident}
                }
            ); ok {
                append(&operands, GetTokenData(tokens[1]))
                DiscardTokens(tokens, matches) 
            } else {
                break loop
            }
        }

        stackop.operands = operands[:]
    }
    return
}

ParseGoto :: proc(tokens: ^[dynamic]Token) -> (goto: Goto, succ: bool) {
    if matches, ok := ValidateTokens(
        tokens, 
        {
            {.Goto},
            {.Ident},
        }
    ); ok {
        succ = true
        goto.dest = GetTokenData(tokens[1]).(string)
        DiscardTokens(tokens, matches)

        if matches, ok := ValidateTokens(
            tokens,
            {
                {.Branch},
                {.Ident, .IntLit},
                {.Eq, .NotEq, .Lt, .Gt, .LtEq, .GtEq},
                {.Ident, .IntLit},
            },
        ); ok {
            goto.branching = true
            goto.left      = GetTokenData(tokens[1])
            goto.comp      = tokens[2].kind
            goto.right     = GetTokenData(tokens[3])
            DiscardTokens(tokens, matches) 
        }
    }
    return
}

ParseTac :: proc(tokens: ^[dynamic]Token) -> (ir: [dynamic]Stat, succ: bool) {
    for len(tokens) != 0 {
             if label,    ok := ParseLabel(tokens);    ok { append(&ir, label);    continue }
        else if call,     ok := ParseCall(tokens);     ok { append(&ir, call);     continue }
        else if ret,      ok := ParseReturn(tokens);   ok { append(&ir, ret);      continue }
        else if print,    ok := ParsePrint(tokens);    ok { append(&ir, print);    continue }
        else if rawprint, ok := ParseRawPrint(tokens); ok { append(&ir, rawprint); continue }
        else if assign,   ok := ParseAssign(tokens);   ok { append(&ir, assign);   continue }
        else if stackop,  ok := ParseStackOp(tokens);  ok { append(&ir, stackop);  continue }
        else if goto,     ok := ParseGoto(tokens);     ok { append(&ir, goto);     continue }
        else { fmt.println("Unknown token found?", tokens[0], "parser.odin line", #line); return }
    }
    succ = true
    return
}