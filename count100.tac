call main
main:
    i = 0
loop_start:
    i = i + 1
    push i,10
    raw_print 1
    print 1
    goto loop_start if i < 100