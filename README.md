# TAC IR
rules:
- Each line can only have 1 statement
- lines beggining with `//` are ignored (these are comments, there are no multiline comments)
- the first line of the program **MUST** be an `entry <name>` state specifying the label where the program starts
- names (lowercase letter only) followed by a colon is a label, like `main:`
- assignments must be in the form `a = b <op> c` or just `a = c` (three variables/constants at most)
- variable names are lowercase letters only
    - all variables dissapear after a `goto` is encountered
- no function calls, if statements or whatever, only `goto` and `goto <label> if a <op> b`
    - as long as the resulting `a <op> b` is not zero, in a `goto if` then it will execute
- integers are the only supported type and constant
- there are also `push` and `pop` instructions which operate on a stack
    - these persist after `goto`
    - you can push an arbitrary amount of integers with array-like syntax `push 1,2,3,4,5`
    - you can "declare" or set variables with `pop <name>` 
- `print` statements take a number and pop that amount off the stack and print them according to ascii codes
    - `raw_print` will just print the raw integers

## OTHER NOTES
So this can be interpreted, but it's for simplifying code generation to target CPU architectures

Im thinking that maybe for interpreted mode, I will add some kind of `alloc` and `free` keywords for something like dynamic memory allocation.