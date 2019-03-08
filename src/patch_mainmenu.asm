;;
;; Tarpeeksi Hyvae Soft 2017 /
;; U7DCP (Ultima VII DOS Cache Patch)
;;
;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Opens the MAINMENU.EXE file for reading/writing, and verifies that its size is as expected.
;;;
;;; EXPECTS:
;;;     (- unspecified)
;;; DESTROYS:
;;;     (- unspecified)
;;; RETURNS:
;;;     (- unspecified)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Open_Mainmenu_exe:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; open MAINMENU.EXE
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    xor cx,cx
    mov dx,fn_mainmenu_exe
    mov ah,3dh                              ; request to open
    mov al,0010b                            ; for read/write.
    int 21h
    jnc .l2                                 ; error-checking (the cf flag will be set by int 21h if there was an error).
    mov [err_additional],err_no_file_mainmenu
    jmp .exit_fail
    .l2:
    mov [fh_mainmenu_exe],ax                ; store the file handle for later use.

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; verify that the file size of MAINMENU.EXE is as expected.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; seek to the end of the file.
    mov dx,0
    mov cx,0
    mov bx,[fh_mainmenu_exe]
    mov ax,4202h
    int 21h
    jnc .get_file_len                       ; error-checking (the cf flag will be set by int 21h if there was an error).
    jmp .exit_fail
    .get_file_len:
    mov bx,dx
    shl ebx,16
    mov bx,ax
    cmp ebx,MAINMENU_EXE_BYTESIZE
    je .rewind_file
    mov [err_additional],err_file_size_mainmenu
    jmp .exit_fail
    .rewind_file:
    mov bx,[fh_mainmenu_exe]
    mov dx,0
    mov cx,0
    mov ax,4200h
    int 21h
    jc .exit_fail                           ; error-checking (the cf flag will be set by int 21h if there was an error).

    jmp .exit_success

    .exit_fail:
    mov al,0
    jmp .exit

    .exit_success:
    mov al,1
    jmp .exit

    .exit:
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Patch the MAINMENU.EXE file.
;;;
;;; EXPECTS:
;;;     (- unspecified)
;;; DESTROYS:
;;;     (- unspecified)
;;; RETURNS:
;;;     (- unspecified)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Patch_Mainmenu_exe:
    mov dx,msg_patching_mainmenu
    mov ah,9h
    int 21h

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; seek to the start of the data block we want to patch.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov bx,[fh_mainmenu_exe]
    mov cx,0
    mov dx,9406
    mov ax,4200h                            ; set to move file position, offset from the beginning.
    int 21h                                 ; move file position.
    jc .exit_fail                           ; error-checking (the cf flag will be set by int 21h if there was an error).

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; read in the block's data.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; read the data.
    mov dx,file_buffer                      ; read from disk into the file buffer
    mov cx,FILE_BUFFER_SIZE                 ; as much as there's room in the buffer. (cross fingers that the buffer is large enough.)
    mov ah,3fh
    int 21h
    jc .exit_fail                           ; error-checking (the cf flag will be set by int 21h if there was an error).
    ; seek back to the start of the block.
    mov cx,-1
    mov dx,-FILE_BUFFER_SIZE
    mov ax,4201h
    int 21h
    jc .exit_fail                           ; error-checking (the cf flag will be set by int 21h if there was an error).

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; patch the 1st instance.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov di,0                                ; the offset in the data block to operate on.
    xor bx,bx                               ; the offset in the patch to read from.
    .p1_1:
        mov al,[patch_1+bx]                 ; get the next patch byte.
        mov [file_buffer+di+bx],al          ; apply it to the buffer to be patched with.
        add bx,1
        cmp bx,patch_1_len
        jb .p1_1
    mov di,37
    xor bx,bx
    .p1_2:
        mov al,[patch_2+bx]                 ; get the next patch byte.
        mov [file_buffer+di+bx],al          ; apply it to the buffer to be patched with.
        add bx,1
        cmp bx,patch_2_len
        jb .p1_2

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; patch the 2nd instance.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov di,223
    xor bx,bx
    .p2_1:
        mov al,[patch_1+bx]
        mov [file_buffer+di+bx],al
        add bx,1
        cmp bx,patch_1_len
        jb .p2_1
    mov di,260
    xor bx,bx
    .p2_2:
        mov al,[patch_2+bx]
        mov [file_buffer+di+bx],al
        add bx,1
        cmp bx,patch_2_len
        jb .p2_2

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; patch the 3rd instance.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov di,410
    xor bx,bx
    .p3_1:
        mov al,[patch_1+bx]
        mov [file_buffer+di+bx],al
        add bx,1
        cmp bx,patch_1_len
        jb .p3_1
    mov di,444
    xor bx,bx
    .p3_2:
        mov al,[patch_2+bx]
        mov [file_buffer+di+bx],al
        add bx,1
        cmp bx,patch_2_len
        jb .p3_2

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; write the data back into the executable on disk.
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov bx,[fh_mainmenu_exe]
    mov dx,file_buffer
    mov cx,FILE_BUFFER_SIZE
    mov ah,40h
    int 21h
    jc .exit_fail                           ; error-checking (the cf flag will be set by int 21h if there was an error).

    jmp .exit_success

    .exit_fail:
    mov al,0
    jmp .exit

    .exit_success:
    mov al,1
    jmp .exit

    .exit:
    ret
