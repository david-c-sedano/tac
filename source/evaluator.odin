package main

import "core:fmt"

// so i can check if my `union{string, int}` should look into my table or just use the int literal...
GetValue :: proc(str_or_int: union{string, int}, table: ^map[string]int) -> int {
    if str, ok := str_or_int.(string); ok do return table[str]
    else { num := str_or_int.(int);          return num }
}

EvalTac :: proc(code: []Stat) {
    table:     map[string]int
    stack:     [dynamic]int
    callstack: [dynamic]int
    ip:        int // "instruction pointer"

    // scan thru and find where the labels are located
    for stat in code {
        #partial switch variant in stat {
        case Label:
            table[string(variant)] = ip
        }
        ip += 1
    }
    ip = 0

    for ip < len(code) {
        stat := code[ip]

        switch variant in stat {
        case Label:
            ip = table[string(variant)]
        case Call:
            append(&callstack, ip)
            ip = table[string(variant)]
        case Return:
            ok:bool
            if ip, ok = pop_safe(&callstack); !ok {
                fmt.println("ERROR: tried to execute `return` with nothing on call stack.")
                return
            }
        case Print:
            for i in 0..<int(variant) {
                if val, ok := pop_front_safe(&stack); ok {
                    fmt.printf("%r", rune(val))
                } else {
                    fmt.println("stack underflow")
                    return
                }
            }
        case RawPrint:
            for i in 0..<int(variant) {
                if val, ok := pop_front_safe(&stack); ok {
                    fmt.printf("%d", val)
                } else {
                    fmt.println("stack underflow")
                    return
                }
            }
        case Assign:
            result: int
            #partial switch variant.op {
                case .Add: result = GetValue(variant.left, &table) + GetValue(variant.right, &table)
                case .Sub: result = GetValue(variant.left, &table) - GetValue(variant.right, &table)
                case .Mul: result = GetValue(variant.left, &table) * GetValue(variant.right, &table)
                case .Div: result = GetValue(variant.left, &table) / GetValue(variant.right, &table)
            }
            table[variant.target] = result
        case StackOp:
            #partial switch variant.kind {
                case .Push:
                    for operand in variant.operands do append(&stack, GetValue(operand, &table))
                case .Pop:
                    for operand in variant.operands {
                        switch v in operand {
                        case int:
                            for _ in 0..<v do pop(&stack)
                        case string:
                            table[v] = pop(&stack)
                        }
                    }
            } 
        case Goto:
            if !variant.branching {
                ip = table[variant.dest]
            } else {
                result: bool
                #partial switch variant.comp {
                    case .Eq:    result = GetValue(variant.left, &table) == GetValue(variant.right, &table)
                    case .NotEq: result = GetValue(variant.left, &table) != GetValue(variant.right, &table)
                    case .Lt:    result = GetValue(variant.left, &table) <  GetValue(variant.right, &table)
                    case .Gt:    result = GetValue(variant.left, &table) >  GetValue(variant.right, &table)
                    case .LtEq:  result = GetValue(variant.left, &table) <= GetValue(variant.right, &table)
                    case .GtEq:  result = GetValue(variant.left, &table) >= GetValue(variant.right, &table)
                }
                if result do ip = table[variant.dest]
            }
        }
        ip += 1
    }
}