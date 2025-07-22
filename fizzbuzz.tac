call main
// 50+ lines for fizzbuzz program lets go!!
mod:
    pop b
    pop a
    t1 = a / b
    t2 = b * t1
    t3 = a - t2
    push t3
    return
main:
    i = 0
loop_start:
    i = i + 1
// if i mod 15 == 0
    push i
    push 15
    call mod
    pop result
    goto fizzbuzz if result == 0
// else if i mod 5 == 0
    push i
    push 5
    call mod
    pop result
    goto buzz if result == 0
// else if i mod 3 == 0
    push i
    push 3
    call mod
    pop result
    goto fizz if result == 0
// else
    goto default
fizzbuzz:
    push 102,105,122,122,98,117,122,122,10
    print 9
    goto loop_end
buzz:
    push 98,117,122,122,10
    print 5
    goto loop_end
fizz:
    push 102,105,122,122,10
    print 5
    goto loop_end
default:
    push i
    raw_print 1
    push 10
    print 1
loop_end:
    goto loop_start if i < 100