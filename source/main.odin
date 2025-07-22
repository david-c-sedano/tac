package main

import "core:fmt"
import "core:os"

main :: proc() {
    if !(len(os.args) > 1) {
        fmt.println("pls supply file name in arguments")
        return
    }

    filename := os.args[1]
    fmt.println("opening:", filename)
    file, err := os.open(filename, os.O_RDWR)
    if err != os.ERROR_NONE do fmt.println(os.get_last_error(), "in main.odin:", #line)

    data: [256*256]u8
    if total_read, err := os.read(file, data[:]); err == os.ERROR_NONE {
        if total_read >= 256*256 do fmt.println("this isnt good ~ in main.odin:", #line)
        code := data[:total_read]
        tokens: [dynamic]Token
        Tokenize(code, &tokens)
        if parsed_code, ok := ParseTac(&tokens); ok {
            EvalTac(parsed_code[:])
        } else {
            fmt.println("Parsing fail")
        }
    } else {
        fmt.println(os.get_last_error(), "in main.odin:", #line)
    }
}