Red [
	Title: "Ansi sequence dialect"
	Author: "Boleslav Březovský"
	Usage: {
CLS       - clear screen
AT pair!  - put curspor at position
FG word!  - set foregroud to color
BG word!  - set background to color
BOLD      - set bold style
ITALIC    - set italic style
UNDERLINE - set underline style
UP        - move cursor up
DOWN      - move cursor down
LEFT      - move cursor left
RIGHT     - move cursor right
RESET     - reset all styles
	}
]

ansi: context [

esc-main: "^[["
clear-screen: append copy esc-main "2J"
set-position: func [position][
	rejoin [esc-main form position/y #";" form position/x #"H"]
]

demo: does [
	do [cls at 1x1 fg red "Welcome to " fg black bg white "A" bg yellow "N" bg red "S" bg magenta "I" reset bold space underline fg bright green "con" reset fg green italic "sole" reset]
]

colors: [black red green yellow blue magenta cyan white none default]

as-rule: func [block][
	block: collect [
		foreach value block [keep reduce [to lit-word! value '|]]
	]
	also block take/last block
]

colors-list: as-rule colors
color-rule: [
	set type ['fg | 'bg]
	(bright?: false)
	opt ['bright (bright?: true)]
	set value colors-list
	keep (
		type: pick [3 4] equal? 'fg type
		if bright? [type: type + 6]
		set 'vv value
		value: -1 + index? find colors value
		rejoin [esc-main form type value #"m"]
	)
]
move-rule: [
	(value: 1)
	set type ['up | 'down | 'left | 'right]
	opt [set value integer!]
	keep (rejoin [esc-main form value #"@" + index? find [up down left right] type])
]
style-rule: [
	set type ['bold | 'italic | 'underline | 'inverse]
	keep (
		rejoin [esc-main form select [bold 1 italic 3 underline 4 inverse 7] type #"m"]
	)
]
type: value: bright?: none

trans: func [
	data
][
	parse data [
		collect [
			some [
				'reset keep (rejoin [esc-main "0m"])
			|   'cls keep (clear-screen)

			|   style-rule
			|   move-rule
			|   color-rule

			|   'at set value pair! keep (set-position value)
			|   keep [word! | string! | char!]
			]
		]
	]
]

do: func [data][
	if block? data [data: trans data]
	print rejoin data
]

vline: func [
	pos
	height
][
	collect [
		repeat i height [
			keep reduce ['at pos + (i * 0x1) "│"]
		]
	]
]

tui: func [
	data
	/local cmd value stack
		box-rule
][
	stack: []
	dialect: clear []
	box-rule: [
		(clear stack)
		'box
		set value pair! (append stack value)
		set value pair! (append stack value)
		(
			width: stack/2/x - stack/1/x - 1
			height: stack/2/y - stack/1/y - 1
			repend dialect ['at stack/1 + 1x0 append/dup copy "" #"─" width] 	; top line
			repend dialect ['at stack/1 + (height + 1 * 0x1) + 1x0 append/dup copy "" #"─" width] 	; bottom line
			append dialect vline stack/1 height
			append dialect vline stack/1 + 1x0 + (width * 1x0) height
			repend dialect ['at stack/1 "┌"] 							; top-left copner
			repend dialect ['at stack/1 + (width + 1 * 1x0) "┐"]		; top-right corner
			repend dialect ['at stack/1 + (height + 1 * 0x1) "└"]		; bottom-left copner
			repend dialect ['at stack/2 "┘"] 							; bottom-right copner
		)
	]
	pass-rule: [
		set value skip (append dialect value)
	]
	parse data [
		some [
			box-rule
		|	pass-rule
		]
	]
	dialect
]

; -- end of context
]
