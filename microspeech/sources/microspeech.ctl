; Copyright Currah 1983, 2024 ArcadeGeek LTD.
; NOTE: Disassembly is Work-In-Progress.
; Label naming is loosely based on Action_ActionName_SubAction
; e.g. Print_HighScore_Loop.

> $0000 @start
> $0000 @rom
> $0000 @set-handle-unsupported-macros=1
> $0000 @org=$0000
> $0000 @expand=#DEF1(#SKOOLKID(addr,anchor=0)(name)#HTML(<a rel="noopener nofollow" href="https://skoolkit.ca/disassemblies/rom/#IF({{mode[base]}}==16)(hex/)asm/#IF({{mode[base]}}==16)(#EVAL({addr},16,4),#EVAL({addr})).html#IF({anchor})(#CHR(35)#IF({{mode[base]}}==16)(#EVAL({anchor},16,4),#EVAL({anchor})))">){name}#HTML(</a>))
> $0000 @expand=#DEF(#FACT()(anchor,text) #LINK(Facts#$anchor)($text))

b $0000 Banner Characters
@ $0000 label=BannerCharacters
D $0000 Seven 8x8 bitmaps used by #R$01AB with #R$0798 to print
. "Speech System © CURRAH 1983" into the display file. The inverse
. letters here are "R", "A" and "H" ("R" is used twice); "CU" live
. at #R$0798(#N$07F0).
  $0000,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $0008,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $0010,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $0018,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $0020,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $0028,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $0030,$08 #UDGTABLE { #UDG(#PC) } TABLE#

c $0038 Handle Interrupt
@ $0038 label=HandleInterrupt
D $0038 Any access to #R$0038 (including this opcode fetch) pages
. the μSpeech ROM in or out. The Spectrum IM1 handler lands here,
. so this ROM runs first. Every exit jumps back to #R$0038, which
. pages the Spectrum ROM in and lets IM1 finish.
  $0038,$02 #HTML[Preserve #REGaf (this <code>PUSH</code>/<code>POP</code> pair is what Rockfall II checks for).]
  $003A,$01 Keep further interrupts out while the μSpeech ROM is paged in.
  $003B,$04 Stash #REGhl, #REGaf, #REGbc and #REGde on the stack.
N $003F The speech workspace is a short block at the top of the
. reserved area, between *#SKOOLKID$5CB2(RAMTOP) and the UDGs
. (low byte #N$57). A 48K machine uses #N$FF57; a 16K machine
. uses #N$7F57.
  $003F,$03 Fetch *#SKOOLKID$5CB2(RAMTOP).
  $0042,$05 Jump to #R$0050 if the low byte is not #N$57.
  $0047,$05 Jump to #R$0081 if *#SKOOLKID$5CB2(RAMTOP) is still the
. 48K power-on value (#N$FF57).
  $004C,$04 Jump to #R$0081 if it is still the 16K power-on value
. (#N$7F57).
N $0050 *#SKOOLKID$5CB2(RAMTOP) is not a power-on value; probe
. the speech workspace below it.
@ $0050 label=ProbeWorkspace
  $0050,$05 Call #R$0354 for the address of the queue head (index
. #N$06).
  $0055,$02 Copy the workspace address to #REGbc.
  $0057,$05 Call #R$0375 and jump to #R$0081 to reinstall if the
. workspace is no longer protected by *#SKOOLKID$5CB2(RAMTOP).
  $005C,$03 Call #R$037F.
  $005F,$03 Call #R$0375.
  $0062,$03 Call #R$03A2 if the buffer pointer is at or below
. *#SKOOLKID$5CB2(RAMTOP).
  $0065,$04 Call #R$0354 for the flags byte.
  $0069,$04 Jump to #R$00B7 if this is the second pass of this
. interrupt.
  $006D,$02 Flag that the next entry is the second pass.
  $006F,$04 Restore #REGde, #REGbc, #REGaf and #REGhl from the stack.
N $0073 Let the Spectrum's IM1 routine (#SKOOLKID$0038(MASK_INT))
. scan the keyboard first. When it returns, control goes to
. #R$0038, which pages this ROM back in for the second pass.
@ $0073 label=ReturnToSpectrum
  $0073,$04 Leave two copies of #REGhl below the stack.
  $0077,$04 Stack #R$0038 over the first copy, as the return address
. for the Spectrum IM1 routine.
  $007B,$03 Restore #REGhl from the stack.
  $007E,$03 Jump to #R$0038 to page the Spectrum ROM in.
N $0081 Wait a few frames, then reserve a page below
. *#SKOOLKID$5CB2(RAMTOP) for the speech workspace.
@ $0081 label=InstallWorkspace
  $0081,$08 Jump to #R$01A3 if *#SKOOLKID$5C78(FRAMES) is still less than #N$05.
  $0089,$04 Call #R$0354 for the flags byte.
  $008D,$04 Set *#SKOOLKID$5CB2(RAMTOP) one page below the workspace page.
  $0091,$03 Write #N$82 to the flags byte.
  $0094,$03 Clear workspace index #N$01.
  $0097,$02 Store the workspace page as the high byte of the
. buffer pointer (index #N$02).
  $0099,$03 Write #N$51 as its low byte (index #N$03): an empty queue.
  $009C,$04 Clear workspace indexes #N$04 and #N$05.
  $00A0,$03 Fetch the new *#SKOOLKID$5CB2(RAMTOP).
N $00A3 Plant a sentinel and move the machine stack below the
. new *#SKOOLKID$5CB2(RAMTOP).
@ $00A3 label=InstallWorkspace_Stack
  $00A3,$03 Write a #N$3E sentinel at the new
. *#SKOOLKID$5CB2(RAMTOP).
  $00A6,$01 Write #N$00 beneath it.
  $00A7,$01 Point #REGsp one byte below the new *#SKOOLKID$5CB2(RAMTOP).
  $00A8,$04 Clear the two bytes below the new stack.
N $00AC Install abandons the interrupted program: #SKOOLKID$0038(MASK_INT)
. returns to #SKOOLKID$12A2,$12A9(MAIN_1), re-entering the BASIC main
. loop with a fresh stack.
  $00AC,$03 Write the error stack to *#SKOOLKID$5C3D(ERR_SP).
  $00AF,$03 Set the return address to #SKOOLKID$12A2,$12A9(MAIN_1) in MAIN_EXEC.
  $00B2,$01 Stash the return address on the stack.
  $00B3,$01 Re-enable interrupts before handing over to the Spectrum ROM.
  $00B4,$03 Jump to #R$0038.
N $00B7 Second pass: clear the pass flag, then draw the banner once
. and speak.
@ $00B7 label=ServiceSpeech
  $00B7,$02 Clear the second-pass flag.
  $00B9,$05 Call #R$01AB if the banner has not been drawn yet.
N $00BE The Spectrum IM1 routine runs twice per frame (see #R$0073),
. so take one off *#SKOOLKID$5C78(FRAMES) to compensate for the
. extra increment.
  $00BE,$03 Fetch the *#SKOOLKID$5C78(FRAMES) word.
  $00C1,$04 Jump to #R$00C9 if the low word of *#SKOOLKID$5C78(FRAMES)
. is non-zero.
  $00C5,$04 Decrease the high byte of *#SKOOLKID$5C78(FRAMES) if the
. low word is about to wrap.
@ $00C9 label=ServiceSpeech_Tick
  $00C9,$07 Decrease the low word of *#SKOOLKID$5C78(FRAMES).
N $00D0 Likewise add one to the repeat and delay counters in each
. half of *#SKOOLKID$5C00(KSTATE), to compensate for
. #SKOOLKID$02BF(KEYBOARD)'s extra decrement. (When a set is free
. these counters just drift upwards; #SKOOLKID$02BF(KEYBOARD)
. reloads them when a new key arrives.)
  $00D0,$06 Point at the keyboard-state timers (#N$04 bytes apart).
  $00D6,$03 Call #R$034B.
  $00D9,$01 Move back to the five-call counters (#N$5C01 and #N$5C05).
  $00DA,$03 Call #R$034B.
N $00DD Programs speak by assigning the BASIC string #FACT(sstring,s$). Look
. it up and expand it into allophones if it exists.
  $00DD,$05 Call #R$01CD for "#FACT(sstring,s$)".
  $00E2,$03 Call #R$021F if #FACT(sstring,s$) exists.
  $00E5,$03 Call #R$02AD.
  $00E8,$03 Jump to #R$0166 if key speech is disabled.
  $00EB,$04 Call #R$0354 for the flags byte.
  $00EF,$03 Fetch *#SKOOLKID$5C3B(FLAGS).
  $00F2,$04 Jump to #R$00FC if no new key was pressed.
  $00F6,$04 Jump to #R$0166 if this key is already being spoken.
  $00FA,$02 Jump to #R$0100.
@ $00FC label=ServiceSpeech_NoKey
  $00FC,$04 Clear the "key held" flag and jump to #R$0166.
N $0100 A new key is in *#SKOOLKID$5C08(LAST_K); turn it into allophones.
@ $0100 label=ServiceSpeech_Key
  $0100,$02 Set the "key held" flag.
  $0102,$03 Fetch *#SKOOLKID$5C08(LAST_K).
  $0105,$04 Jump to #R$0111 if the code is #N$7B or higher.
  $0109,$04 Jump to #R$0111 if the code is below "a".
  $010D,$04 Convert a lowercase letter to uppercase and jump to #R$012C.
N $0111 Not a letter. Graphics characters (block graphics and UDGs)
. share key #N$80; other
. symbols go through #R$042D.
@ $0111 label=ServiceSpeech_NotLetter
  $0111,$04 Jump to #R$011D if the code is #N$A5 or higher.
  $0115,$04 Jump to #R$011D if the code is below #N$80.
  $0119,$04 Use dictionary key #N$80 and jump to #R$012C.
@ $011D label=ServiceSpeech_Punctuation
  $011D,$06 Search #R$042D for this character.
  $0123,$04 Jump to #R$012C if there is no mapping.
  $0127,$05 Fetch the replacement from #R$043A.
N $012C Look the key up in #R$0447.
@ $012C label=ServiceSpeech_Lookup
  $012C,$03 Point at #R$0447.
  $012F,$01 Keep the key in #REGb.
@ $0130 label=ServiceSpeech_FindKey
  $0130,$04 Jump to #R$0137 if this byte ends an allophone list.
  $0134,$01 Move to the next dictionary byte.
  $0135,$02 Jump to #R$0130.
@ $0137 label=ServiceSpeech_NextKey
  $0137,$01 Move to the next dictionary key.
  $0138,$04 Jump to #R$0166 if the table has ended.
  $013C,$04 Jump to #R$0143 if this key matches.
  $0140,$01 Move to the next dictionary byte.
  $0141,$02 Jump to #R$0130.
N $0143 Copy the matching allophones into the speech buffer.
@ $0143 label=ServiceSpeech_Copy
  $0143,$01 Move to the first allophone of this entry.
  $0144,$05 Call #R$0393 and jump to #R$0151 if the queue is empty.
  $0149,$01 Step the buffer pointer on one byte.
  $014A,$04 Jump to #R$0166 (leaving the key unspoken) if the last queued allophone does not have bit 7 set.
  $014E,$03 Call #R$03A2 to empty the queue so the new key word replaces the previous one.
@ $0151 label=ServiceSpeech_Store
  $0151,$03 Queue this allophone in the speech buffer.
  $0154,$05 Call #R$0375 and jump to #R$0160 if the buffer has hit
. *#SKOOLKID$5CB2(RAMTOP).
  $0159,$04 Jump to #R$0163 if this was the last allophone of the word.
  $015D,$01 Move to the next allophone.
  $015E,$02 Jump to #R$0151.
@ $0160 label=ServiceSpeech_Flush
  $0160,$03 Call #R$037F.
@ $0163 label=ServiceSpeech_Commit
  $0163,$03 Call #R$038A.
N $0166 The #FACT(sp0256,SP0256) is the speech-synthesiser chip. Read its
. status at #N$1000 (bit 0 is the inverted load request) and send
. the next queued allophone if the input buffer can take one.
@ $0166 label=FeedAllophone
  $0166,$03 Read the #FACT(sp0256,SP0256) status from #N$1000.
  $0169,$04 Jump to #R$01A3 if the chip's input buffer is full.
N $016D The manual notes that "the unit will remain silent until
. the first ENTER is pressed after a power up, a NEW, or after a
. 'report' has been printed at the bottom of the screen." On every
. interrupt that reaches this code where bit 7 of
. *#SKOOLKID$5C3A(ERR_NR) is reset (an error code is waiting),
. this code empties the speech queue through #R$03A2, so nothing
. is spoken until the ROM sets *#SKOOLKID$5C3A(ERR_NR) back to
. #N$FF; that happens when ENTER is pressed and on the editor's
. error paths (#SKOOLKID$107F,$1085(ED_ERROR) and
. #SKOOLKID$111D,$1172(ED_FULL) in the Spectrum ROM). The
. power-on and NEW cases are from the manual (chapter 2 also
. says any report other than OK has this effect).
  $016D,$07 Empty the speech queue (#R$03A2) if BASIC is reporting an
. error (bit 7 of *#SKOOLKID$5C3A(ERR_NR) reset).
  $0174,$05 Call #R$0393 and jump to #R$017F if anything is queued.
  $0179,$06 Keep the chip fed with PA1 (silence) and jump to #R$01A3.
N $017F The #FACT(sp0256,SP0256) can take an allophone; write the next
. queued one.
@ $017F label=FeedAllophone_Write
  $017F,$05 Call #R$0354 for the next allophone.
  $0184,$08 Point at #N$3000 (low pitch) or #N$3001 (high pitch) by
. bit 6.
@ $018C label=FeedAllophone_Port
  $018C,$01 Select the pitch (only the address matters; it switches
. the speech chip's clock between about 3.05 MHz and 3.26 MHz
. (MAME's values; see #FACT(intonation,Intonation))).
  $018D,$03 Write the allophone to the speech port (the chip ignores
. bits 6 and 7).
  $0190,$03 Work out the queue length (including the allophone just sent).
  $0193,$01 Step the queue pointer on one byte.
  $0194,$01 Stash the queue length on the stack.
  $0195,$03 Call #R$038A.
  $0198,$05 Call #R$0354 for the queue start.
  $019D,$03 Point the copy at the previous queue byte.
  $01A0,$01 Restore the queue length from the stack.
  $01A1,$02 Move the rest of the queue up one byte.
N $01A3 Restore the Spectrum registers and page its ROM back in.
@ $01A3 label=ExitInterrupt
  $01A3,$04 Restore #REGde, #REGbc, #REGaf and #REGhl from the stack.
  $01A7,$01 Re-enable interrupts before handing over to the Spectrum ROM.
  $01A8,$03 Jump to #R$0038.

c $01AB Print Banner
@ $01AB label=PrintBanner
D $01AB Copy the "Speech System © CURRAH 1983" bitmaps into
. the display file, using #R$075B.
R $01AB HL Workspace flags pointer
  $01AB,$03 Start at the top of the display file.
  $01AE,$03 Use the banner address list.
  $01B1,$02 Mark the banner as drawn.
@ $01B3 label=PrintBanner_Loop
  $01B3,$03 Fetch the next bitmap address.
  $01B6,$04 Return if the list has ended.
  $01BA,$01 Complete the bitmap pointer.
  $01BB,$01 Stash the list pointer on the stack.
  $01BC,$02 Set the row counter to #N$08.
@ $01BE label=PrintBanner_Column
  $01BE,$02 Write one pixel row to the display file.
  $01C0,$02 Move to the next pixel row.
  $01C2,$02 Decrease the row counter and loop back to #R$01BE
. until the character is done.
  $01C4,$04 Return to the top of the character cell.
  $01C8,$01 Move to the next character column.
  $01C9,$01 Restore the list pointer from the stack.
  $01CA,$01 Move to the next address.
  $01CB,$02 Jump to #R$01B3.

c $01CD Find Variable
@ $01CD label=FindVariable
D $01CD Walk the BASIC variable area looking for the name code in #REGa.
R $01CD A Name code
R $01CD O:HL Pointer to the variable
R $01CD O:F Z flag set if the name was found
  $01CD,$01 Keep the name code in #REGb.
  $01CE,$03 Fetch *#SKOOLKID$5C3B(FLAGS).
  $01D1,$03 Jump to #R$0209 if bit 7 is not set (checking syntax).
  $01D4,$03 Fetch *#SKOOLKID$5CB6(CHINFO).
  $01D7,$04 Jump to #R$01DE if it is #N$F4 (the low byte of #SKOOLKID$09F4(PRINT_OUT)).
  $01DB,$03 Jump to #R$0209 if it is not #N$00.
N $01DE Walk *#SKOOLKID$5C4B(VARS) for the requested name.
@ $01DE label=FindVariable_Start
  $01DE,$03 Start at *#SKOOLKID$5C4B(VARS).
@ $01E1 label=FindVariable_Loop
  $01E1,$03 Return if this is the requested variable.
  $01E4,$04 Jump to #R$0209 if this is the end of *#SKOOLKID$5C4B(VARS).
  $01E8,$02,b$01 Keep only bits 5-7 (the variable type).
  $01EA,$04 Jump to #R$0211 if the type is #N$60.
  $01EE,$04 Jump to #R$0217 if the type is #N$A0.
  $01F2,$04 Jump to #R$020D if the type is #N$E0.
  $01F6,$04 Jump to #R$0201 if the type is #N$C0.
  $01FA,$04 Jump to #R$0201 if the type is #N$80.
  $01FE,$03 Return (with Z clear) unless the type is #N$40 (a string).
@ $0201 label=FindVariable_SkipWord
  $0201,$08 Skip the following length word and jump to #R$01E1.
@ $0209 label=FindVariable_Miss
  $0209,$03 Clear the Z flag.
  $020C,$01 Return.
@ $020D label=FindVariable_SkipFor
  $020D,$04 Skip the limit, step, looping line and statement of a FOR-NEXT control variable.
@ $0211 label=FindVariable_SkipNumeric
  $0211,$06 Skip the numeric value and jump to #R$01E1.
@ $0217 label=FindVariable_SkipName
  $0217,$01 Move to the next letter of the long name.
  $0218,$05 Jump to #R$0217 if the name has not ended.
  $021D,$02 Jump to #R$0211.

c $021F Parse Speech String
@ $021F label=ParseSpeechString
D $021F Expand the contents of #FACT(sstring,s$) into the allophone buffer.
. A leading "*" or "?" means the string has already been spoken.
R $021F HL Pointer to #FACT(sstring,s$)
N $021F Read the length of #FACT(sstring,s$) and ignore an empty string.
  $021F,$02 Fetch the low length byte of #FACT(sstring,s$).
  $0221,$02 Test whether the low length byte is zero.
  $0223,$02 Fetch the high length byte of #FACT(sstring,s$).
  $0225,$02 Jump to #R$0229 if the low length byte is non-zero.
  $0227,$02 Return if #FACT(sstring,s$) is empty.
N $0229 Leave strings that have already been spoken.
@ $0229 label=ParseSpeechString_Body
  $0229,$01 Move to the first character.
  $022A,$04 Return if #FACT(sstring,s$) starts with "*".
  $022E,$04 Return if #FACT(sstring,s$) starts with "?".
  $0232,$01 Move back to the length.
  $0233,$01 Stash the start of #FACT(sstring,s$) on the stack.
  $0234,$02 Point #REGde at the end of #FACT(sstring,s$).
  $0236,$01 Restore the start of #FACT(sstring,s$) from the stack.
  $0237,$03 Call #R$037F.
N $023A Convert the next character of #FACT(sstring,s$) into allophones.
@ $023A label=ParseSpeechString_Next
  $023A,$01 Stash the buffer pointer on the stack.
  $023B,$02 Fetch the next character from #FACT(sstring,s$).
  $023D,$03 Call #R$035E.
  $0240,$04 Jump to #R$0250 if this is not a full stop.
  $0244,$02 Load #REGa with PA5 (the longest pause) for a full stop.
  $0246,$01 Restore the buffer pointer from the stack.
  $0247,$02 Queue the first PA5.
  $0249,$04 Call #R$0375 and return if the buffer is full.
  $024D,$01 Stash the buffer pointer on the stack.
  $024E,$02 Jump to #R$0280 to queue a second PA5, with the
. intonation bit.
N $0250 A "(" starts a parenthesised allophone name.
@ $0250 label=ParseSpeechString_TestGroup
  $0250,$04 Jump to #R$025C if this is not "(".
  $0254,$05 Call #R$02EB and jump to #R$0280 if the name was valid.
  $0259,$01 Restore the buffer pointer from the stack.
  $025A,$02 Jump to #R$0269.
N $025C Map the character through #R$03AF.
@ $025C label=ParseSpeechString_Map
  $025C,$01 Stash the string pointer on the stack.
  $025D,$0A Search #R$03AF and jump to #R$027A if this letter is known.
  $0267,$02 Restore the string pointer and the buffer pointer from the stack.
N $0269 This character is not valid. Put a "?" on the character after
. it (or on the last character), and then on the first character.
@ $0269 label=ParseSpeechString_Mark
  $0269,$02 Point #REGde one past the end of #FACT(sstring,s$) and
. #REGhl at the next character.
@ $026B label=ParseSpeechString_Bound
  $026B,$07 Jump to #R$0275 if #REGhl is still inside
. #FACT(sstring,s$).
  $0272,$01 Otherwise move back to the last character.
  $0273,$02 Jump to #R$026B.
N $0275 The "?" path and the buffer-full returns never reach #R$038A, so
. allophones already queued for this string are discarded. On
. buffer-full, #FACT(sstring,s$) is left unmarked and is retried on
. every interrupt. An #FACT(sstring,s$) too long for the buffer never
. speaks.
@ $0275 label=ParseSpeechString_Query
  $0275,$05 Write "?" there and jump to #R$02A3 to write another over
. the first character.
@ $027A label=ParseSpeechString_Mapped
  $027A,$05 Fetch the allophone at the same index in #R$03E5.
  $027F,$01 Restore the string pointer from the stack.
N $0280 Apply intonation and queue the allophone.
@ $0280 label=ParseSpeechString_Store
  $0280,$01 Keep the allophone in #REGb.
  $0281,$01 Set the flags-byte index.
  $0282,$01 Stash the string pointer on the stack.
  $0283,$03 Call #R$0354 for the flags byte.
  $0286,$01 Restore the string pointer from the stack.
  $0287,$02,b$01 Keep only bit 6 (intonation).
  $0289,$01 Apply the intonation bit to the allophone.
  $028A,$01 Restore the buffer pointer from the stack.
  $028B,$02 Queue the allophone in the speech buffer.
  $028D,$04 Call #R$0375 and return if the buffer is full.
  $0291,$06 Jump to #R$023A if there are still characters left
. in #FACT(sstring,s$).
  $0297,$03 Write PA1 (#N$00) to the speech buffer to end the phrase.
  $029A,$04 Call #R$0375 and return if the buffer is full.
  $029E,$03 Call #R$038A.
  $02A1,$02 Use "*" as the "already spoken" marker.
N $02A3 Overwrite the first character of #FACT(sstring,s$) so it will not
. be spoken again.
@ $02A3 label=ParseSpeechString_Term
  $02A3,$05 Call #R$01CD for "#FACT(sstring,s$)".
  $02A8,$03 Move to the first character of #FACT(sstring,s$).
  $02AB,$01 Mark #FACT(sstring,s$) as already spoken.
  $02AC,$01 Return.

c $02AD Test Keys Variable
@ $02AD label=TestKeysVariable
D $02AD Look up the BASIC variable "keys".
. A value of #N$01 enables speaking each key press.
R $02AD O:F Z flag set if key speech is disabled
  $02AD,$05 Call #R$01CD for "keys".
  $02B2,$02 Jump to #R$02DD if it was not found.
  $02B4,$01 Move to the first letter of the name.
  $02B5,$06 Jump to #R$02DD if this is not "e".
  $02BB,$06 Jump to #R$02DD if the next letter is not "y".
  $02C1,$06 Jump to #R$02DD if the next letter is not "s".
  $02C7,$05 Jump to #R$02DD unless keys is held as a small integer
. (first byte #N$00).
  $02CC,$04 Jump to #R$02DD if keys is negative.
  $02D0,$03 Jump to #R$02E4 if the low byte of keys is #N$00.
  $02D3,$04 Jump to #R$02DD if the low byte of keys is not #N$01 (leave the setting unchanged).
  $02D7,$04 Call #R$0354 for the flags byte.
  $02DB,$02 Enable key speech.
@ $02DD label=TestKeysVariable_State
  $02DD,$04 Call #R$0354 for the flags byte.
  $02E1,$02 Set the Z flag if key speech is disabled.
  $02E3,$01 Return.
N $02E4 keys is #N$00; turn key speech off.
@ $02E4 label=TestKeysVariable_Off
  $02E4,$03 Call #R$0354 for the flags byte.
  $02E7,$04 Disable key speech and jump to #R$02DD.

c $02EB Parse Allophone Group
@ $02EB label=ParseAllophoneGroup
D $02EB Read a parenthesised allophone name from the speech string
. (for example "(AA)" or "(SH)"). Letters are normalised, checked
. against #R$03AF, and summed; the sum selects an allophone from
. #R$03E5 (via #R$03CA). Groups with sums #N$5C/#N$64/#N$66/#N$68/#N$78
. are finished from #R$041B and #R$0424.
R $02EB HL Current string pointer
R $02EB O:A Mapped allophone
R $02EB O:F Carry set if the group is invalid
N $02EB Clear the running total that will identify the name.
  $02EB,$02 Set the running total to #N$00.
N $02ED Read letters until a closing parenthesis.
@ $02ED label=ParseAllophoneGroup_Loop
  $02ED,$02 Fetch the next character from the speech string.
  $02EF,$04 Jump to #R$0309 if this is a closing parenthesis.
  $02F3,$01 Stash the running total on the stack.
  $02F4,$03 Call #R$035E.
N $02F7 The letter must appear in the first #N$18 character keys.
  $02F7,$01 Stash the string pointer on the stack.
  $02F8,$08 Search the first #N$18 entries of #R$03AF.
  $0300,$02 Restore the string pointer and the running total from the stack.
  $0302,$02 Jump to #R$0349 if this is not a valid allophone-name
. character.
  $0304,$02 Add the letter key to the running total and return
. if the sum overflowed.
  $0306,$03 Keep the new total and jump to #R$02ED.
N $0309 The name has ended; the running total selects the allophone.
@ $0309 label=ParseAllophoneGroup_Close
  $0309,$01 Use the name sum as the lookup key.
  $030A,$04 Jump to #R$0335 if the sum is #N$64.
  $030E,$04 Jump to #R$0335 if the sum is #N$68.
  $0312,$04 Jump to #R$0335 if the sum is #N$5C.
  $0316,$04 Jump to #R$0335 if the sum is #N$66.
  $031A,$04 Jump to #R$0331 if the sum is #N$78.
N $031E Look the sum up in #R$03AF and #R$03CA.
  $031E,$03 Search the #N$36 bytes of #R$03AF and #R$03CA.
  $0321,$01 Stash the string pointer on the stack.
  $0322,$05 Search #R$03AF for the name sum.
  $0327,$03 Point at the same index in #R$03E5 (#REGhl is one past the match).
@ $032A label=ParseAllophoneGroup_Offset
  $032A,$02 Jump to #R$0348 if no match was found.
  $032C,$02 Fetch the mapped allophone from the parallel table.
  $032E,$01 Clear the carry flag (valid group).
  $032F,$01 Restore the string pointer from the stack.
  $0330,$01 Return.
N $0331 Sum #N$78 uses the character two before the ")" (the middle letter of "(aer)" or "(ear)").
@ $0331 label=ParseAllophoneGroup_Prev
  $0331,$01 Stash the string pointer on the stack.
  $0332,$01 Move back to the previous character.
  $0333,$02 Jump to #R$0336.
@ $0335 label=ParseAllophoneGroup_Look
  $0335,$01 Stash the string pointer on the stack.
N $0336 Map the selected character through the suffix tables.
@ $0336 label=ParseAllophoneGroup_Suffix
  $0336,$02 Fetch the previous character.
  $0338,$03 Call #R$035E.
  $033B,$08 Search #R$041B for the normalised character.
  $0343,$05 Use the parallel suffix value and jump to #R$032A.
N $0348 The name sum is not in the key tables; restore the
. string pointer and fail.
@ $0348 label=ParseAllophoneGroup_Fail
  $0348,$01 Restore the string pointer from the stack.
@ $0349 label=ParseAllophoneGroup_Carry
  $0349,$01 Set the carry flag to signal an invalid group.
  $034A,$01 Return.

c $034B Increment Pair
@ $034B label=IncrementPair
D $034B Add one to two addresses #REGde bytes apart. Used to tick
. both keyboard-state timers.
R $034B HL First address
R $034B DE Distance to the second address
  $034B,$01 Stash the first address on the stack.
  $034C,$02 Set the update counter to #N$02.
@ $034E label=IncrementPair_Loop
  $034E,$02 Add one to this timer and move to the next.
  $0350,$02 Decrease the counter and loop back to #R$034E
. until both timers are updated.
  $0352,$01 Restore the first address from the stack.
  $0353,$01 Return.

c $0354 Read Workspace
@ $0354 label=ReadWorkspace
D $0354 Fetch a byte from the speech workspace. The block lives
. in the page of *#SKOOLKID$5CB4(P_RAMT), at low byte #N$57-index.
R $0354 A Workspace index
R $0354 O:A Byte at that index
R $0354 O:HL Address of that index
  $0354,$03 Fetch *#SKOOLKID$5CB4(P_RAMT).
N $0357 The slot is #N$57 minus the index, in the page of
. *#SKOOLKID$5CB4(P_RAMT).
  $0357,$05 Calculate the address of this workspace index.
  $035C,$01 Fetch the workspace byte.
  $035D,$01 Return.

c $035E Normalise Character
@ $035E label=NormaliseCharacter
D $035E Convert a character towards the dictionary alphabet,
. and set workspace bit 6 for intonation (set for codes below "a").
R $035E A Character
R $035E O:A Normalised character
  $035E,$01 Stash #REGhl on the stack.
  $035F,$01 Keep the character in #REGb.
  $0360,$04 Call #R$0354 for the flags byte.
  $0364,$01 Restore the character.
N $0365 Fold the letter into the dictionary alphabet. "A" and
. "a" both become #N$21.
  $0365,$04 Jump to #R$036F if the character is below "a".
  $0369,$02 Subtract #N$40 from a character at or above "a".
  $036B,$04 Use low intonation and jump to #R$0373.
@ $036F label=NormaliseCharacter_BelowA
  $036F,$02 Subtract #N$20 from a character below "a".
  $0371,$02 Use high intonation.
@ $0373 label=NormaliseCharacter_Done
  $0373,$01 Restore #REGhl from the stack.
  $0374,$01 Return.

c $0375 Check Memory
@ $0375 label=CheckMemory
D $0375 Compare the speech-buffer pointer with
. *#SKOOLKID$5CB2(RAMTOP). Carry is set when the pointer has
. run out of the reserved page (at or below *#SKOOLKID$5CB2(RAMTOP)).
R $0375 BC Buffer pointer
R $0375 O:F Carry set if #REGbc is at or below *#SKOOLKID$5CB2(RAMTOP)
  $0375,$01 Stash #REGhl on the stack.
  $0376,$03 Fetch *#SKOOLKID$5CB2(RAMTOP).
  $0379,$04 Compare *#SKOOLKID$5CB2(RAMTOP) with the buffer pointer.
  $037D,$01 Restore #REGhl from the stack.
  $037E,$01 Return.

c $037F Read Buffer Pointer
@ $037F label=ReadBufferPointer
D $037F Fetch the allophone buffer pointer from the workspace.
R $037F O:BC Buffer pointer
  $037F,$01 Stash #REGhl on the stack.
  $0380,$05 Call #R$0354 for the buffer pointer.
  $0385,$03 Load the two-byte buffer pointer.
  $0388,$01 Restore #REGhl from the stack.
  $0389,$01 Return.

c $038A Write Buffer Pointer
@ $038A label=WriteBufferPointer
D $038A Store the allophone buffer pointer in the workspace.
R $038A BC Buffer pointer
  $038A,$05 Call #R$0354 for the buffer-pointer slot.
  $038F,$03 Write the two-byte buffer pointer.
  $0392,$01 Return.

c $0393 Is Queue Empty
@ $0393 label=IsQueueEmpty
D $0393 Compare the buffer pointer with the address of the queue head.
R $0393 O:F Z flag set if the queue is empty
  $0393,$01 Stash #REGhl on the stack.
  $0394,$05 Call #R$0354 for the address of the queue head.
  $0399,$03 Call #R$037F.
  $039C,$02 Compare the two pointers.
  $039E,$01 Restore #REGhl from the stack.
  $039F,$02 Clear the carry flag.
  $03A1,$01 Return.

c $03A2 Empty Queue
@ $03A2 label=EmptyQueue
D $03A2 Reset the buffer pointer to the queue head, discarding
. anything still queued.
R $03A2 O:BC Restored buffer pointer
  $03A2,$02 Select workspace index #N$06.
  $03A4,$01 Stash #REGhl on the stack.
  $03A5,$03 Call #R$0354 for the address of the queue head.
  $03A8,$02 Copy the queue-head address to #REGbc.
  $03AA,$03 Call #R$038A.
  $03AD,$01 Restore #REGhl from the stack.
  $03AE,$01 Return.

b $03AF Character Keys
@ $03AF label=CharacterKeys
D $03AF The #N$1B normalised characters (see #R$035E) allowed in
. #FACT(sstring,s$): "a"-"z" except "q" and "x", then ",", "'" and
. space. The first #N$18 are also the letters allowed in an
. allophone name. Searched by #R$025C and #R$02EB.
D $03AF The allophone for each key is at the same index in #R$03E5
. (#REGhl is left one past the match, then #N$35 is added).
  $03AF,$01 Key #N(#PEEK(#PC)): allophone #N(#PEEK(#PC+$36)).
L $03AF,$01,$1B

b $03CA Allophone Name Sums
@ $03CA label=MappedCharacters
D $03CA The sums of the normalised letters of each parenthesised
. allophone name, searched along with #R$03AF by #R$02EB. The
. allophone for each sum is at the same index in the second half of
. #R$03E5.
D $03CA Note that "(gg)" and "(ck)" both sum to #N$4E and "(gg)"
. finds the "(ck)" entry first, so it gives KK2. The second #N$4E
. (the seventh sum) and its GG2 allophone are never reached.
. Manual Appendix I documents "(gg)" as GG2 (#N$3D) and "(ck)" as
. KK2 (#N$29), so the ROM gives "(gg)" the "(ck)" sound instead of
. the manual's GG2; that confirms the unused GG2 entry was meant
. for "(gg)".
  $03CA,$01 Name sum #N(#PEEK(#PC)): allophone #N(#PEEK(#PC+$36)).
L $03CA,$01,$1B

b $03E5 Allophone Values
@ $03E5 label=AllophoneValues
D $03E5 Shared allophone value table: #N$1B allophones for the
. characters in #R$03AF (used by #R$027A), followed by #N$1B
. allophones for the name sums in #R$03CA (used by #R$032A). Hear
. the IDs on the #LINK(Sound)(Allophones) page.
  $03E5,$1B,$01 Allophones for the characters in #R$03AF.
@ $0400 label=GroupAllophones
  $0400,$1B,$01 Allophones for the name sums in #R$03CA.

b $041B Suffix Keys
@ $041B label=SuffixKeys
D $041B Suffix letters used after certain allophone-name sums,
. searched by #R$0336. The matching value is #N$09 bytes later in
. #R$0424.
  $041B,$01 Suffix letter #N(#PEEK(#PC)): allophone #N(#PEEK(#PC+$09)).
L $041B,$01,$09

b $0424 Suffix Values
@ $0424 label=SuffixValues
D $0424 Allophone IDs for the suffix letters in #R$041B, used by
. #R$0336.
  $0424,$01 Allophone #N(#PEEK(#PC)).
L $0424,$01,$09

b $042D Punctuation Keys
@ $042D label=PunctuationKeys
D $042D Punctuation and token bytes spoken from *#SKOOLKID$5C08(LAST_K),
. searched by #R$011D. The replacement is #N$0D bytes later in
. #R$043A.
  $042D,$01 Key #N(#PEEK(#PC)): dictionary key #N(#PEEK(#PC+$0D)).
L $042D,$01,$0D

b $043A Punctuation Values
@ $043A label=PunctuationValues
D $043A Dictionary keys for the characters in #R$042D, used by
. #R$011D.
  $043A,$01 Dictionary key #N(#PEEK(#PC)).
L $043A,$01,$0D

b $0447 Allophone Dictionary
@ $0447 label=AllophoneDictionary
D $0447 Character-to-allophone lists used from #R$012C. Each
. entry is a key byte followed by one or more #FACT(sp0256,SP0256-AL2)
. allophone IDs. Bit 6 selects high intonation; the last ID
. has bit 7 set. The table starts with a dummy terminator
. (#N$80) and ends on a key of #N$00. Each spoken list has an
. audio player. The raw AL2 set is on the
. #LINK(Sound)(Allophones) page.
  $0447,$01 Dummy list terminator.
N $0448 Control keys.
N $0448 #AUDIO0(key-edit.wav)
  $0448,$05 EDIT.
N $044D #AUDIO0(key-enter.wav)
  $044D,$07 ENTER.
N $0454 #AUDIO0(key-cursor.wav)
  $0454,$08 Cursor.
N $045C #AUDIO0(key-delete.wav)
  $045C,$06 DELETE.
N $0462 Colour tokens, graphics and symbols.
N $0462 #AUDIO0(key-ink.wav)
  $0462,$04 INK.
N $0466 #AUDIO0(key-paper.wav)
  $0466,$06 PAPER.
N $046C #AUDIO0(key-graphics.wav)
  $046C,$07 Graphics characters (block graphics and UDGs).
N $0473 #AUDIO0(key-flash.wav)
  $0473,$05 FLASH.
N $0478 #AUDIO0(key-bright.wav)
  $0478,$06 BRIGHT.
N $047E #AUDIO0(key-inverse.wav)
  $047E,$07 INVERSE.
N $0485 #AUDIO0(key-over.wav)
  $0485,$04 OVER.
N $0489 #AUDIO0(key-at.wav)
  $0489,$03 AT.
N $048C #AUDIO0(key-tab.wav)
  $048C,$05 TAB.
N $0491 #AUDIO0(key-excl.wav)
  $0491,$0C "!".
N $049D #AUDIO0(key-quot.wav)
  $049D,$05 Quotation mark.
N $04A2 #AUDIO0(key-amp.wav)
  $04A2,$04 "&".
N $04A6 #AUDIO0(key-apos.wav)
  $04A6,$0A "'".
N $04B0 #AUDIO0(key-lparen.wav)
  $04B0,$07 "(".
N $04B7 #AUDIO0(key-lt.wav)
  $04B7,$09 "<".
N $04C0 #AUDIO0(key-gt.wav)
  $04C0,$06 ">".
N $04C6 #AUDIO0(key-ge.wav)
  $04C6,$0E >=.
N $04D4 #AUDIO0(key-le.wav)
  $04D4,$11 <=.
N $04E5 #AUDIO0(key-ne.wav)
  $04E5,$0A <>.
N $04EF #AUDIO0(key-slash.wav)
  $04EF,$06 "/".
N $04F5 #AUDIO0(key-bslash.wav)
  $04F5,$09 "\".
N $04FE #AUDIO0(key-dot.wav)
  $04FE,$05 ".".
N $0503 #AUDIO0(key-comma.wav)
  $0503,$05 ",".
N $0508 #AUDIO0(key-semi.wav)
  $0508,$0A ";".
N $0512 #AUDIO0(key-und.wav)
  $0512,$08 "_".
N $051A #AUDIO0(key-star.wav)
  $051A,$04 "*".
N $051E #AUDIO0(key-grave.wav)
  $051E,$05 "£".
N $0523 #AUDIO0(key-plus.wav)
  $0523,$06 "+".
N $0529 #AUDIO0(key-minus.wav)
  $0529,$07 "-".
N $0530 #AUDIO0(key-space.wav)
  $0530,$06 Space.
N $0536 #AUDIO0(key-hat.wav)
  $0536,$05 "↑".
N $053B #AUDIO0(key-query.wav)
  $053B,$06 "?".
N $0541 #AUDIO0(key-pipe.wav)
  $0541,$03 "|".
N $0544 #AUDIO0(key-copyright.wav)
  $0544,$08 Copyright.
N $054C #AUDIO0(key-let.wav)
  $054C,$04 LET.
N $0550 #AUDIO0(key-colon.wav)
  $0550,$06 ":".
N $0556 #AUDIO0(key-eq.wav)
  $0556,$07 "=".
N $055D #AUDIO0(key-new.wav)
  $055D,$04 NEW.
N $0561 Digits.
N $0561 #AUDIO0(key-0.wav)
  $0561,$04 "0".
N $0565 #AUDIO0(key-1.wav)
  $0565,$04 "1".
N $0569 #AUDIO0(key-2.wav)
  $0569,$03 "2".
N $056C #AUDIO0(key-3.wav)
  $056C,$04 "3".
N $0570 #AUDIO0(key-4.wav)
  $0570,$03 "4".
N $0573 #AUDIO0(key-5.wav)
  $0573,$04 "5".
N $0577 #AUDIO0(key-6.wav)
  $0577,$05 "6".
N $057C #AUDIO0(key-7.wav)
  $057C,$06 "7".
N $0582 #AUDIO0(key-8.wav)
  $0582,$03 "8".
N $0585 #AUDIO0(key-9.wav)
  $0585,$05 "9".
N $058A Number sign, dollar and percent.
N $058A #AUDIO0(key-hash.wav)
  $058A,$04 "#".
N $058E #AUDIO0(key-dollar.wav)
  $058E,$05 "$".
N $0593 #AUDIO0(key-pct.wav)
  $0593,$08 "%".
N $059B Letters.
N $059B #AUDIO0(key-a.wav)
  $059B,$02 "A".
N $059D #AUDIO0(key-b.wav)
  $059D,$03 "B".
N $05A0 #AUDIO0(key-c.wav)
  $05A0,$04 "C".
N $05A4 #AUDIO0(key-d.wav)
  $05A4,$03 "D".
N $05A7 #AUDIO0(key-e.wav)
  $05A7,$02 "E".
N $05A9 #AUDIO0(key-f.wav)
  $05A9,$04 "F".
N $05AD #AUDIO0(key-g.wav)
  $05AD,$03 "G".
N $05B0 #AUDIO0(key-h.wav)
  $05B0,$03 "H".
N $05B3 #AUDIO0(key-i.wav)
  $05B3,$02 "I".
N $05B5 #AUDIO0(key-j.wav)
  $05B5,$03 "J".
N $05B8 #AUDIO0(key-k.wav)
  $05B8,$03 "K".
N $05BB #AUDIO0(key-l.wav)
  $05BB,$03 "L".
N $05BE #AUDIO0(key-m.wav)
  $05BE,$03 "M".
N $05C1 #AUDIO0(key-n.wav)
  $05C1,$03 "N".
N $05C4 #AUDIO0(key-o.wav)
  $05C4,$02 "O".
N $05C6 #AUDIO0(key-p.wav)
  $05C6,$03 "P".
N $05C9 #AUDIO0(key-q.wav)
  $05C9,$04 "Q".
N $05CD #AUDIO0(key-r.wav)
  $05CD,$02 "R".
N $05CF #AUDIO0(key-s.wav)
  $05CF,$04 "S".
N $05D3 #AUDIO0(key-t.wav)
  $05D3,$03 "T".
N $05D6 #AUDIO0(key-u.wav)
  $05D6,$03 "U".
N $05D9 #AUDIO0(key-v.wav)
  $05D9,$03 "V".
N $05DC #AUDIO0(key-w.wav)
  $05DC,$07 "W".
N $05E3 #AUDIO0(key-x.wav)
  $05E3,$04 "X".
N $05E7 #AUDIO0(key-y.wav)
  $05E7,$03 "Y".
N $05EA #AUDIO0(key-z.wav)
  $05EA,$05 "Z".
N $05EF BASIC tokens.
N $05EF #AUDIO0(key-rnd.wav)
  $05EF,$05 RND.
N $05F4 #AUDIO0(key-inkey.wav)
  $05F4,$06 INKEY$.
N $05FA #AUDIO0(key-pi.wav)
  $05FA,$03 PI.
N $05FD #AUDIO0(key-fn.wav)
  $05FD,$08 FN.
N $0605 #AUDIO0(key-screen.wav)
  $0605,$06 SCREEN$.
N $060B #AUDIO0(key-attr.wav)
  $060B,$04 ATTR.
N $060F #AUDIO0(key-valstr.wav)
  $060F,$05 VAL$.
N $0614 #AUDIO0(key-code.wav)
  $0614,$04 CODE.
N $0618 #AUDIO0(key-val.wav)
  $0618,$04 VAL.
N $061C #AUDIO0(key-len.wav)
  $061C,$04 LEN.
N $0620 #AUDIO0(key-sin.wav)
  $0620,$04 SIN.
N $0624 #AUDIO0(key-cos.wav)
  $0624,$04 COS.
N $0628 #AUDIO0(key-tan.wav)
  $0628,$04 TAN.
N $062C #AUDIO0(key-asn.wav)
  $062C,$06 ASN.
N $0632 #AUDIO0(key-acs.wav)
  $0632,$07 ACS.
N $0639 #AUDIO0(key-atn.wav)
  $0639,$06 ATN.
N $063F #AUDIO0(key-ln.wav)
  $063F,$05 LN.
N $0644 #AUDIO0(key-exp.wav)
  $0644,$05 EXP.
N $0649 #AUDIO0(key-int.wav)
  $0649,$04 INT.
N $064D #AUDIO0(key-sqr.wav)
  $064D,$04 SQR.
N $0651 #AUDIO0(key-abs.wav)
  $0651,$04 ABS.
N $0655 #AUDIO0(key-peek.wav)
  $0655,$04 PEEK.
N $0659 #AUDIO0(key-in.wav)
  $0659,$03 IN.
N $065C #AUDIO0(key-usr.wav)
  $065C,$05 USR.
N $0661 #AUDIO0(key-str.wav)
  $0661,$06 STR$.
N $0667 #AUDIO0(key-chr.wav)
  $0667,$04 CHR$.
N $066B #AUDIO0(key-not.wav)
  $066B,$04 NOT.
N $066F #AUDIO0(key-bin.wav)
  $066F,$04 BIN.
N $0673 #AUDIO0(key-or.wav)
  $0673,$02 OR.
N $0675 #AUDIO0(key-line.wav)
  $0675,$04 LINE.
N $0679 #AUDIO0(key-then.wav)
  $0679,$04 THEN.
N $067D #AUDIO0(key-to.wav)
  $067D,$03 TO.
N $0680 #AUDIO0(key-step.wav)
  $0680,$05 STEP.
N $0685 #AUDIO0(key-deffn.wav)
  $0685,$06 DEF FN.
N $068B #AUDIO0(key-cat.wav)
  $068B,$04 CAT.
N $068F #AUDIO0(key-format.wav)
  $068F,$06 FORMAT.
N $0695 #AUDIO0(key-move.wav)
  $0695,$04 MOVE.
N $0699 #AUDIO0(key-erase.wav)
  $0699,$04 ERASE.
N $069D #AUDIO0(key-open.wav)
  $069D,$05 OPEN #.
N $06A2 #AUDIO0(key-close.wav)
  $06A2,$05 CLOSE #.
N $06A7 #AUDIO0(key-merge.wav)
  $06A7,$05 MERGE.
N $06AC #AUDIO0(key-verify.wav)
  $06AC,$07 VERIFY.
N $06B3 #AUDIO0(key-beep.wav)
  $06B3,$04 BEEP.
N $06B7 #AUDIO0(key-circle.wav)
  $06B7,$06 CIRCLE.
N $06BD #AUDIO0(key-out.wav)
  $06BD,$03 OUT.
N $06C0 #AUDIO0(key-lprint.wav)
  $06C0,$09 LPRINT.
N $06C9 #AUDIO0(key-llist.wav)
  $06C9,$08 LLIST.
N $06D1 #AUDIO0(key-stop.wav)
  $06D1,$05 STOP.
N $06D6 #AUDIO0(key-read.wav)
  $06D6,$04 READ.
N $06DA #AUDIO0(key-data.wav)
  $06DA,$05 DATA.
N $06DF #AUDIO0(key-restore.wav)
  $06DF,$06 RESTORE.
N $06E5 #AUDIO0(key-border.wav)
  $06E5,$05 BORDER.
N $06EA #AUDIO0(key-continue.wav)
  $06EA,$09 CONTINUE.
N $06F3 #AUDIO0(key-dim.wav)
  $06F3,$04 DIM.
N $06F7 #AUDIO0(key-rem.wav)
  $06F7,$04 REM.
N $06FB #AUDIO0(key-for.wav)
  $06FB,$03 FOR.
N $06FE #AUDIO0(key-goto.wav)
  $06FE,$06 GO TO.
N $0704 #AUDIO0(key-gosub.wav)
  $0704,$07 GO SUB.
N $070B #AUDIO0(key-input.wav)
  $070B,$06 INPUT.
N $0711 #AUDIO0(key-load.wav)
  $0711,$04 LOAD.
N $0715 #AUDIO0(key-list.wav)
  $0715,$05 LIST.
N $071A #AUDIO0(key-pause.wav)
  $071A,$04 PAUSE.
N $071E #AUDIO0(key-next.wav)
  $071E,$06 NEXT.
N $0724 #AUDIO0(key-poke.wav)
  $0724,$04 POKE.
N $0728 #AUDIO0(key-print.wav)
  $0728,$06 PRINT.
N $072E #AUDIO0(key-plot.wav)
  $072E,$05 PLOT.
N $0733 #AUDIO0(key-run.wav)
  $0733,$04 RUN.
N $0737 #AUDIO0(key-save.wav)
  $0737,$04 SAVE.
N $073B #AUDIO0(key-randomize.wav)
  $073B,$09 RANDOMIZE.
N $0744 #AUDIO0(key-if.wav)
  $0744,$03 IF.
N $0747 #AUDIO0(key-draw.wav)
  $0747,$04 DRAW.
N $074B #AUDIO0(key-clear.wav)
  $074B,$04 CLEAR.
N $074F #AUDIO0(key-return.wav)
  $074F,$06 RETURN.
N $0755 #AUDIO0(key-copy.wav)
  $0755,$05 COPY.
  $075A,$01 Table end.

w $075B Banner Addresses
@ $075B label=BannerAddresses
D $075B Pointers to the 8x8 bitmaps in #R$0000 and #R$0798 that spell
. "Speech System © CURRAH 1983", used by #R$01AB. A high byte of #N$FF
. ends the list.
  $075B,$02 #R$0798(#N$07A0) ("S").
  $075D,$02 #R$0798(#N$07A8) ("p").
  $075F,$02 #R$0798(#N$07B0) ("e").
  $0761,$02 #R$0798(#N$07B0) ("e").
  $0763,$02 #R$0798(#N$07B8) ("c").
  $0765,$02 #R$0798(#N$07C0) ("h").
  $0767,$02 #R$0798 (space).
  $0769,$02 #R$0798(#N$07A0) ("S").
  $076B,$02 #R$0798(#N$07C8) ("y").
  $076D,$02 #R$0798(#N$07E0) ("s").
  $076F,$02 #R$0798(#N$07D8) ("t").
  $0771,$02 #R$0798(#N$07B0) ("e").
  $0773,$02 #R$0798(#N$07D0) ("m").
  $0775,$02 #R$0798 (space).
  $0777,$02 #R$0798(#N$07E8) (copyright).
  $0779,$02 #R$0798 (space).
  $077B,$02 #R$0798(#N$07F0) ("C").
  $077D,$02 #R$0798(#N$07F8) ("U").
  $077F,$02 #R$0000(#N($0008,$04,$04)) ("R").
  $0781,$02 #R$0000(#N($0008,$04,$04)) ("R").
  $0783,$02 #R$0000(#N($0010,$04,$04)) ("A").
  $0785,$02 #R$0000(#N($0018,$04,$04)) ("H").
  $0787,$02 #R$0798 (space).
  $0789,$02 #R$0000(#N($0020,$04,$04)) ("1").
  $078B,$02 #R$0000(#N($0028,$04,$04)) ("9").
  $078D,$02 #R$0000(#N($0030,$04,$04)) ("8").
  $078F,$02 #R$0000(#N($0000,$04,$04)) ("3").
  $0791,$02 Terminator.

t $0793 Programmer Credit
@ $0793 label=ProgrammerCredit
D $0793 #HTML[Mark Anson ("Anson"), named on the programming manual
. title page (see <a href="https://archive.org/stream/currahuspeech/Currah_uSPEECH_djvu.txt" rel="noopener noreferrer nofollow">archive.org</a>).]
  $0793,$05 "Anson".

b $0798 Banner Bitmaps
@ $0798 label=BannerBitmaps
D $0798 Space, "Speech System" letters, the copyright mark and
. inverse "CU". Inverse "R", "A" and "H" and the "1983" digits live at #R$0000.
. Reached by #R$01AB through #R$075B.
  $0798,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $07A0,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $07A8,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $07B0,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $07B8,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $07C0,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $07C8,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $07D0,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $07D8,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $07E0,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $07E8,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $07F0,$08 #UDGTABLE { #UDG(#PC) } TABLE#
  $07F8,$08 #UDGTABLE { #UDG(#PC) } TABLE#

i $0800
