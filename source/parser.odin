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
TokenStr :: ""; TokenInt :: 0
ValidateTokens :: proc(tokens: ^[dynamic]Token, expected_tokens: [][]Token) -> (succ: bool) {
    t: Token; ok: bool

    for expected_union, i in expected_tokens {
        succ = false
        inner: for expected_token in expected_union {
            if t, ok = tokens[i].(string); ok {
                if t, ok = expected_token.(string); ok {
                    succ = true
                    break inner
                }
            }

            if t, ok = tokens[i].(int); ok {
                if t, ok = expected_token.(int); ok {
                    succ = true
                    break inner
                }
            }

            if t, ok = tokens[i].(TokenKind); ok {
                if t, ok = expected_token.(TokenKind); ok {
                    if tokens[i].(TokenKind) == expected_token.(TokenKind) {
                        succ = true
                        break inner
                    }
                }
            }
        }
        if !succ do return
    }
    return
}

// these type casts on the unions were giving me problems,
// anyways this is the highest form of print debugging, passing #caller_location and printing that
// Odin is actually a goated programming language, though proper debuggers are still better
GetString_OrInt :: proc(token: Token, loc := #caller_location) -> union{string, int} {
    if str, ok := token.(string); ok { 
        return str 
    } else { 
        if num, ok := token.(int); ok {
            return num
        } else {
            fmt.println("string_or_int fail", loc)
            panic := token.(int)
            return 1
        }
    }
}

DiscardTokens :: proc(tokens: ^[dynamic]Token, amount: int) {
    for i in 0..<amount do pop_front(tokens)
}

// now time for parsing
ParseLabel :: proc(tokens: ^[dynamic]Token) -> (label: Label, succ: bool) {
    if succ = ValidateTokens(
        tokens, 
        {
            {TokenStr}, 
            {.Colon}
        }
    ); !succ do return 

    label = Label(tokens[0].(string))
    DiscardTokens(tokens, 2)
    return
}

ParseCall :: proc(tokens: ^[dynamic]Token) -> (call: Call, succ: bool) {
    if succ = ValidateTokens(
        tokens, 
        {
            {.Call}, 
            {TokenStr}
        }
    ); !succ do return 

    call = Call(tokens[1].(string))
    DiscardTokens(tokens, 2)
    return
}

ParseReturn :: proc(tokens: ^[dynamic]Token) -> (ret: Return, succ: bool) {
    if succ = ValidateTokens(
        tokens, 
        {
            {.Ret}
        }
    ); !succ do return 

    ret = Return(tokens[0].(TokenKind))
    DiscardTokens(tokens, 1)
    return
}

ParsePrint :: proc(tokens: ^[dynamic]Token) -> (amount: Print, succ: bool) {
    if succ = ValidateTokens(
        tokens, 
        {
            {.Print}, 
            {TokenInt}
        }
    ); !succ do return 

    amount = Print(tokens[1].(int))
    DiscardTokens(tokens, 2)
    return
}

ParseRawPrint :: proc(tokens: ^[dynamic]Token) -> (amount: RawPrint, succ: bool) {
    if succ = ValidateTokens(
        tokens, 
        {
            {.RawPrint}, 
            {TokenInt}
        }
    ); !succ do return 

    amount = RawPrint(tokens[1].(int))
    DiscardTokens(tokens, 2)
    return
}

ParseAssign :: proc(tokens: ^[dynamic]Token) -> (assign: Assign, succ: bool) {
    if succ = ValidateTokens(
        tokens, 
        {
            {TokenStr}, 
            {.Assign}, 
            {TokenStr, TokenInt}, 
        }
    ); !succ do return 

    assign.target = tokens[0].(string)
    assign.left   = GetString_OrInt(tokens[2]) 
    DiscardTokens(tokens, 3)

    if ValidateTokens(
        tokens, 
        {
            {.Add, .Sub, .Mul, .Div}, 
            {TokenStr, TokenInt},
        },
    ) {
        assign.op     = tokens[0].(TokenKind)
        assign.right  = GetString_OrInt(tokens[1]) 
        DiscardTokens(tokens, 2)
    }
    return
}

ParseStackOp :: proc(tokens: ^[dynamic]Token) -> (stackop: StackOp, succ: bool) {
    if succ = ValidateTokens(
        tokens, 
        {
            {.Push, .Pop},
            {TokenInt, TokenStr}
        }
    ); !succ do return 

    stackop.kind = tokens[0].(TokenKind)
    operands: [dynamic]union{string, int}
    // python-like oneliner, sorry (you must pop a value into somewhere, `pop 12` is not valid)
    if stackop.kind == .Pop do if name, ok := tokens[1].(string); !ok { stackop = {}; succ = false; return }
    append(&operands, GetString_OrInt(tokens[1]))
    DiscardTokens(tokens, 2)

    for stackop.kind == .Push && ValidateTokens(tokens, {{.Comma}, {TokenStr, TokenInt}}) {
        append(&operands, GetString_OrInt(tokens[1]))
        DiscardTokens(tokens, 2)
    } 
    stackop.operands = operands[:len(operands)]
    return
}

ParseGoto :: proc(tokens: ^[dynamic]Token) -> (goto: Goto, succ: bool) {
    if succ = ValidateTokens(
        tokens, 
        {
            {.Goto},
            {TokenStr},
        }
    ); !succ do return 

    goto.dest = tokens[1].(string)
    DiscardTokens(tokens, 2)

    if ValidateTokens(
        tokens,
        {
            {.Branch},
            {TokenStr, TokenInt},
            {.Eq, .NotEq, .Lt, .Gt, .LtEq, .GtEq},
            {TokenStr, TokenInt},
        },
    ) {
        goto.branching = true
        goto.left      = GetString_OrInt(tokens[1])
        goto.comp      = tokens[2].(TokenKind)
        goto.right     = GetString_OrInt(tokens[3])
        DiscardTokens(tokens, 4) 
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