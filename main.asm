;;
;; Tarpeeksi Hyvae Soft 2017 /
;; U7DCP (Ultima VII DOS Cache Patch)
;;
;; Patches a bug in Ultima 7, where the game will enable L1 cache on launch and thus prevent
;; the user from running with the cache disabled (for 486-like performance on faster PCs).
;;
;; Based on initial detective work by a guy on the VOGONS forum, whose name I now forget, who
;; found the bug to result from the game clearing the cache disable bit in CR0 at certain
;; locations in MAINMENU.EXE and ENDGAME.EXE.
;;
;; This patch makes the assumption that in manipulating CR0, the game is intending to enter
;; unreal mode, and thus only wants to deal with bit #0 rather than to wipe CR0 entirely by
;; setting it to 1 as it does without the patch. The patch modifies the above-mentioned
;; executables, accordingly.
;;
;; The code here includes some sloppy duplication, but good enough for the quick job it
;; is. THERE IS NO WARRANTY NOR GUARANTEE FOR THIS SOFTWARE. IT IS AN UNOFFICIAL THIRD-PARTY
;; MODIFICATION.
;;
;;

format MZ

entry @CODE:start
; default stack size = 4096 bytes.

segment @CODE use16

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; includes.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
include "patch_mainmenu.asm"
include "patch_endgame.asm"

start:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; assign data segments.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov ax,@BASE_DATA
mov ds,ax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; display to the user an info message about what the program does.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mov dx,msg_program
mov ah,9h
int 21h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; open the game's files for patching, and patch away.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.open_mainmenu:
call Open_Mainmenu_exe
cmp al,1
je .open_endgame
jmp .exit_fail

.open_endgame:
call Open_Endgame_exe
cmp al,1
je .patch_mainmenu
jmp .exit_fail

.patch_mainmenu:
call Patch_Mainmenu_exe
cmp al,1
je .patch_endgame
jmp .exit_fail

.patch_endgame:
call Patch_Endgame_exe
cmp al,1
je .exit
jmp .exit_fail

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; done.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.exit:
mov dx,msg_success
mov ah,9h
int 21h
mov ah,4ch
mov al,0
int 21h

.exit_fail:
mov dx,[err_additional]
mov ah,9h
int 21h
mov ah,4ch
mov al,1
int 21h

segment @BASE_DATA
    ; file names.
    fn_mainmenu_exe db "MAINMENU.EXE",0,'$'
    fn_endgame_exe db "ENDGAME.EXE",0,'$'

	; expected file sizes of the executables.
	MAINMENU_EXE_BYTESIZE = 127116
	ENDGAME_EXE_BYTESIZE = 107630

    ; file handles.
    fh_mainmenu_exe dw 0
    fh_endgame_exe dw 0

    ; patches.
    patch_1 db 0fh,20h,0c3h     ; mov ebx,cr0
            db 80h,0cbh,01h     ; or bl,1
            db 0fh,22h,0c3h     ; mov cr0,ebx
    patch_1_len = $ - patch_1

    patch_2 db 80h,0e3h,0feh    ; and bl,0feh
            db 0fh,22h,0c3h     ; mov cr0,ebx
    patch_2_len = $ - patch_2

    ; info strings.
    msg_program db "U7DCP - Ultima VII DOS Cache Patch.",0ah,0dh,0ah,0dh,'$'
    msg_success db 0ah,0dh,"The patching appears to have gone well.",0ah,0dh,'$'
    msg_patching_endgame db "Patching ENDGAME.EXE...",0ah,0dh,'$'
    msg_patching_mainmenu db "Patching MAINMENU.EXE...",0ah,0dh,'$'

    ; error strings.
    err_generic db "ERROR: Unknown error. Exiting.",0ah,0dh,'$'
    err_no_file_mainmenu db "ERROR: MAINMENU.EXE not found. Exiting.",0ah,0dh,'$'
    err_no_file_endgame db "ERROR: ENDGAME.EXE not found. Exiting.",0ah,0dh,'$'
    err_file_size_mainmenu db "ERROR: MAINMENU.EXE has an incompatible byte size. Exiting.",0ah,0dh,'$'
    err_file_size_endgame db "ERROR: ENDGAME.EXE has an incompatible byte size. Exiting.",0ah,0dh,'$'
    err_additional dw err_generic           ; a pointer to an additional error message string.

	FILE_BUFFER_SIZE = 500
    file_buffer rb FILE_BUFFER_SIZE         ; a memory buffer for reading data from disk into.

