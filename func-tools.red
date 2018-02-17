Red[
    Title: "UFCS dialect"
    Author: "Boleslav Březovský"
    Purpose: "Provide kind of Unified Fuction Call Syntax for Red"
]

actions: has [
    "Return block of all actions"
    result
][
    result: []
    if empty? result [
        result: collect [
            foreach word words-of system/words [
                if action? get/any word [keep word]
            ]
        ]
    ]
    result
]

arity?: func [
    "Return function's arity" ; TODO: support for lit-word! and get-word! ?
    fn [any-function!]  "Function to examine"
    /local result count name count-rule refinement-rule append-name
][
    result: copy []
    count: 0
    name: none
    append-name: quote (repend result either name [[name count]][[count]]) 
    count-rule: [
        some [
            word! (count: count + 1)
        |   ahead refinement! refinement-rule
        |   skip
        ]
    ] 
    refinement-rule: [
        append-name
        set name refinement!
        (count: 0)
        count-rule
    ]
    parse spec-of :fn count-rule
    do append-name
    either find result /local [
        head remove/part find result /local 2
    ][result]
]

refinements?: func [
    "Return block of refinements for given function"
    fn      [any-function!] "Function to examine"
    /local value
][
    parse spec-of :fn [
        collect [some [set value refinement! keep (to word! value) | skip]]
    ]
]

ufcs: func [
    "Apply actions to given series"
    series  [series!]       "Series to manipulate"
    dialect [block!]        "Block of actions and arguments, without first argument (series defined above)"
    /local result action args code
][
    result: none
    code: []
    until [
        ; do some preparation
        clear code
        action: take dialect
        arity: arity? get action
        args: arity/1 - 1
        refs: refinements? get action
        ref-stack: clear []
        refs?: false
        unless zero? args [append ref-stack take dialect]
        ; check for refinements
        while [find refs first dialect][
            refs?: true
            ref: take dialect
            either path? action [
                append action ref 
            ][
                action: make path! reduce [action ref]
            ] 
            unless zero? select arity ref [
                append ref-stack take dialect 
            ]
        ]
        ; put all code together
        append/only code action 
        append/only code series
        unless empty? ref-stack [append code ref-stack]
        do code
        empty? dialect
    ]
    series
]

apply: func [
    "Apply a function to a block of arguments"
    fn      [any-function!] "Function value to apply"
    args    [block!]        "Block of arguments (to quote refinement use QUOTE keyword)"
    /local arity path? refs vals val fun
][
    arity: arity? :fn
    path?: false
    refs: copy []
    vals: copy []
    parse args [
        some [
            'quote set val skip (append vals val) 
        |   set val refinement! (path?: true append refs to word! val)
        |   set val skip (append vals val)
        ]
    ]
    fun: 'fn
    if path? [
        fun: make path! head insert refs 'fn
    ]
    do compose [(fun) (vals)]
]