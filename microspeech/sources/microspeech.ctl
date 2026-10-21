; Copyright Currah 1983, 2024 ArcadeGeek LTD.
; NOTE: Disassembly is Work-In-Progress.
; Label naming is loosely based on Action_ActionName_SubAction
; e.g. Print_HighScore_Loop.

> $0000 @start
> $0000 @rom
> $0000 @set-handle-unsupported-macros=1
> $0000 @org=$0000
> $0000 @expand=#DEF1(#SKOOLKID(addr)(name)#HTML(<a rel="noopener nofollow" href="https://skoolkit.ca/disassemblies/rom/hex/asm/#EVAL({addr},16,4).html">){name}#HTML(</a>))
> $0000 @expand=#DEF(#FACT()(anchor,text) #LINK(Facts#$anchor)($text))

b $0000 Banner Characters
@ $0000 label=BannerCharacters
D $0000 Seven 8x8 bitmaps used by #R$01AB with #R$0798 to print
. "speech system © CURRAH 1983" into the display file. The inverse
. letters here are "RRAH"; "CU" live at #R$0798(#N$07F0).
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
  $0038,$02 Keep #REGaf unchanged.
  $003A,$01 Disable interrupts.
  $003B,$04 Stash #REGhl, #REGaf, #REGbc and #REGde on the stack.
N $003F The speech workspace is a short block just below
. *#SKOOLKID$5CB2(RAMTOP) (low byte #N$57). A 48K machine uses
. #N$FF57; a 16K machine uses #N$7F57.
  $003F,$03 Fetch *#SKOOLKID$5CB2(RAMTOP).
  $0042,$05 Jump to #R$0050 if the low byte is not #N$57.
  $0047,$05 Jump to #R$0081 if this is a 48K machine.
  $004C,$04 Jump to #R$0081 if this is a 16K machine.
N $0050 *#SKOOLKID$5CB2(RAMTOP) is not the installed workspace yet.
@ $0050 label=ProbeWorkspace
  $0050,$05 Call #R$0354 for the saved buffer pointer.
  $0055,$02 Copy the workspace address to #REGbc.
  $0057,$05 Call #R$0375 and jump to #R$0081 if the reserved block
. is already below *#SKOOLKID$5CB2(RAMTOP).
  $005C,$03 Call #R$037F.
  $005F,$03 Call #R$0375.
  $0062,$03 Call #R$03A2 if the pointer is out of range.
  $0065,$04 Call #R$0354 for the flags byte.
  $0069,$04 Jump to #R$00B7 if the workspace is already live.
  $006D,$02 Mark the workspace as being installed.
  $006F,$04 Restore #REGde, #REGbc, #REGaf and #REGhl from the stack.
N $0073 Page the Spectrum ROM back in so IM1 can run.
@ $0073 label=ReturnToSpectrum
  $0073,$04 No operation.
  $0077,$03 Set the return address to #R$0038.
  $007A,$01 Stash the return address on the stack.
  $007B,$02 Move #REGsp down two bytes.
  $007D,$01 Restore #REGhl from the stack.
  $007E,$03 Jump to #R$0038.
N $0081 Wait a few frames, then reserve a page below
. *#SKOOLKID$5CB2(RAMTOP) for the speech workspace.
@ $0081 label=InstallWorkspace
  $0081,$08 Jump to #R$01A3 if *#SKOOLKID$5C78(FRAMES) is still less than #N$05.
  $0089,$04 Call #R$0354 for the flags byte.
  $008D,$04 Lower *#SKOOLKID$5CB2(RAMTOP) by one page.
  $0091,$03 Write #N$82 to the flags byte.
  $0094,$03 Clear workspace index #N$01.
  $0097,$02 Store the workspace page in index #N$02.
  $0099,$03 Write #N$51 to the buffer pointer (index #N$03).
  $009C,$04 Clear workspace indexes #N$04 and #N$05.
  $00A0,$03 Fetch the new *#SKOOLKID$5CB2(RAMTOP).
N $00A3 Plant a sentinel and move the machine stack below the
. new *#SKOOLKID$5CB2(RAMTOP).
@ $00A3 label=InstallWorkspace_Stack
  $00A3,$03 Write a #N$3E sentinel at the new
. *#SKOOLKID$5CB2(RAMTOP).
  $00A6,$01 Write #N$00 beneath it.
  $00A7,$01 Point #REGsp at the new *#SKOOLKID$5CB2(RAMTOP).
  $00A8,$04 Clear the two bytes below the new stack.
  $00AC,$03 Write the error stack to *#SKOOLKID$5C3D(ERR_SP).
  $00AF,$03 Set the return address to #SKOOLKID$12A9(MAIN-5).
  $00B2,$01 Stash the return address on the stack.
  $00B3,$01 Enable interrupts.
  $00B4,$03 Jump to #R$0038.
N $00B7 The workspace is live. Draw the banner once, then speak.
@ $00B7 label=ServiceSpeech
  $00B7,$02 Clear the "installing" flag.
  $00B9,$05 Call #R$01AB if the banner has not been drawn yet.
N $00BE Keep *#SKOOLKID$5C78(FRAMES) moving while this ROM owns the
. interrupt.
  $00BE,$03 Fetch the *#SKOOLKID$5C78(FRAMES) word.
  $00C1,$04 Jump to #R$00C9 if *#SKOOLKID$5C78(FRAMES) is non-zero.
  $00C5,$04 Decrease the third *#SKOOLKID$5C78(FRAMES) byte.
@ $00C9 label=ServiceSpeech_Tick
  $00C9,$07 Decrease the *#SKOOLKID$5C78(FRAMES) word.
N $00D0 Tick the two keyboard-state timer pairs.
  $00D0,$06 Point at the keyboard-state timers (#N$04 bytes apart).
  $00D6,$03 Call #R$034B.
  $00D9,$01 Move back one byte.
  $00DA,$03 Call #R$034B.
N $00DD Programs speak by assigning the BASIC string #FACT(sstring,s$). Look
. it up and expand it into allophones if it exists.
  $00DD,$05 Call #R$01CD for "#FACT(sstring,s$)".
  $00E2,$03 Call #R$021F if #FACT(sstring,s$) exists.
  $00E5,$03 Call #R$02AD.
  $00E8,$03 Jump to #R$0166 if key speech is enabled.
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
N $0111 Not a letter. Block graphics share key #N$80; other
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
  $0144,$05 Call #R$0393 and jump to #R$0151 if the buffer pointers
. already match.
  $0149,$01 Step the buffer pointer on one byte.
  $014A,$04 Jump to #R$0166 if the previous allophone is not a terminator.
  $014E,$03 Call #R$03A2.
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
. busy flag at #N$1000 and send the next queued allophone if
. it is idle.
@ $0166 label=FeedAllophone
  $0166,$03 Read the #FACT(sp0256,SP0256) status from #N$1000.
  $0169,$04 Jump to #R$01A3 if the chip is still busy.
  $016D,$03 Fetch *#SKOOLKID$5C3A(ERR_NR).
  $0170,$04 Call #R$03A2 if BASIC is not reporting an error.
  $0174,$05 Call #R$0393 and jump to #R$017F if there is something left to say.
  $0179,$06 Silence the #FACT(sp0256,SP0256) and jump to #R$01A3.
N $017F The #FACT(sp0256,SP0256) is idle; write the next queued allophone.
@ $017F label=FeedAllophone_Write
  $017F,$05 Call #R$0354 for the next allophone.
  $0184,$03 Use the low-intonation port (#N$3000).
  $0187,$04 Jump to #R$018C if bit 6 is reset.
  $018B,$01 Use the high-intonation port instead (#N$3001).
@ $018C label=FeedAllophone_Port
  $018C,$01 Select the intonation.
  $018D,$03 Write the allophone to the #FACT(sp0256,SP0256).
  $0190,$03 Work out how many bytes remain in the queue.
  $0193,$01 Step the queue pointer on one byte.
  $0194,$01 Stash the remaining length on the stack.
  $0195,$03 Call #R$038A.
  $0198,$05 Call #R$0354 for the queue start.
  $019D,$03 Point the copy at the previous queue byte.
  $01A0,$01 Restore the remaining length from the stack.
  $01A1,$02 Shuffle the queued allophones down.
N $01A3 Restore the Spectrum registers and page its ROM back in.
@ $01A3 label=ExitInterrupt
  $01A3,$04 Restore #REGde, #REGbc, #REGaf and #REGhl from the stack.
  $01A7,$01 Enable interrupts.
  $01A8,$03 Jump to #R$0038.

c $01AB Print Banner
@ $01AB label=PrintBanner
D $01AB Copy the "speech system © CURRAH 1983" bitmaps into
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
  $01D1,$03 Jump to #R$0209 if bit 7 is not set.
  $01D4,$03 Fetch *#SKOOLKID$5CB6(CHINFO).
  $01D7,$04 Jump to #R$01DE if it is #N$F4.
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
  $01FE,$03 Return if the type is not a simple numeric.
@ $0201 label=FindVariable_SkipWord
  $0201,$08 Skip the following length word and jump to #R$01E1.
@ $0209 label=FindVariable_Miss
  $0209,$03 Clear the Z flag.
  $020C,$01 Return.
@ $020D label=FindVariable_SkipArray
  $020D,$04 Skip the array header.
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
  $0244,$02 Queue a short pause.
  $0246,$01 Restore the buffer pointer from the stack.
  $0247,$02 Write the pause to the speech buffer.
  $0249,$04 Call #R$0375 and return if the buffer is full.
  $024D,$01 Stash the buffer pointer on the stack.
  $024E,$02 Jump to #R$0280.
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
N $0269 This character is not in the key tables; mark #FACT(sstring,s$)
. with "?".
@ $0269 label=ParseSpeechString_Mark
  $0269,$02 Step past this character.
@ $026B label=ParseSpeechString_Bound
  $026B,$05 Test whether the string pointer has reached the end
. of #FACT(sstring,s$).
  $0270,$02 Jump to #R$0275 if it has.
  $0272,$01 Move back one character.
  $0273,$02 Jump to #R$026B.
@ $0275 label=ParseSpeechString_Query
  $0275,$05 Mark #FACT(sstring,s$) with "?" and jump to #R$02A3.
@ $027A label=ParseSpeechString_Mapped
  $027A,$05 Fetch the mapped allophone from #R$03CA.
  $027F,$01 Restore the string pointer from the stack.
N $0280 Apply intonation and queue the allophone.
@ $0280 label=ParseSpeechString_Store
  $0280,$01 Keep the allophone in #REGb.
  $0281,$01 Set the flags-byte index.
  $0282,$01 Stash the string pointer on the stack.
  $0283,$03 Call #R$0354.
  $0286,$01 Restore the string pointer from the stack.
  $0287,$02,b$01 Keep only bit 6 (intonation).
  $0289,$01 Apply the intonation bit to the allophone.
  $028A,$01 Restore the buffer pointer from the stack.
  $028B,$02 Queue the allophone in the speech buffer.
  $028D,$04 Call #R$0375 and return if the buffer is full.
  $0291,$06 Jump to #R$023A if there are still characters left
. in #FACT(sstring,s$).
  $0297,$03 Write a terminator to the speech buffer.
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
R $02AD O:F Z flag set if key speech is enabled
  $02AD,$05 Call #R$01CD for "keys".
  $02B2,$02 Jump to #R$02DD if it was not found.
  $02B4,$01 Move to the first letter of the name.
  $02B5,$06 Jump to #R$02DD if this is not "e".
  $02BB,$06 Jump to #R$02DD if the next letter is not "y".
  $02C1,$06 Jump to #R$02DD if the next letter is not "s".
  $02C7,$05 Jump to #R$02DD if the name has not ended.
  $02CC,$04 Jump to #R$02DD if the value header is not empty.
  $02D0,$03 Jump to #R$02E4 if keys is #N$00.
  $02D3,$04 Jump to #R$02DD if keys is not #N$01.
  $02D7,$04 Call #R$0354 for the flags byte.
  $02DB,$02 Enable key speech.
@ $02DD label=TestKeysVariable_State
  $02DD,$04 Call #R$0354 for the flags byte.
  $02E1,$02 Set the Z flag from the key-speech flag.
  $02E3,$01 Return.
N $02E4 keys is #N$00; turn key speech off.
@ $02E4 label=TestKeysVariable_Off
  $02E4,$03 Call #R$0354.
  $02E7,$04 Disable key speech and jump to #R$02DD.

c $02EB Parse Allophone Group
@ $02EB label=ParseAllophoneGroup
D $02EB Read a parenthesised allophone name from the speech string
. (for example "(AA)" or "(SH)"). Letters are normalised, checked
. against #R$03AF, and summed; the sum selects an allophone from
. the parallel tables.
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
N $031E Look the sum up across both character-key tables.
  $031E,$03 Search #N$36 bytes of the character-key tables.
  $0321,$01 Stash the string pointer on the stack.
  $0322,$05 Search #R$03AF for the name sum.
  $0327,$03 Use the parallel mapped value (#N$35 bytes on).
@ $032A label=ParseAllophoneGroup_Offset
  $032A,$02 Jump to #R$0348 if no match was found.
  $032C,$02 Fetch the mapped allophone from the parallel table.
  $032E,$01 Set the flags from the mapped allophone.
  $032F,$01 Restore the string pointer from the stack.
  $0330,$01 Return.
N $0331 Sum #N$78 uses the character before the ")".
@ $0331 label=ParseAllophoneGroup_Prev
  $0331,$01 Stash the string pointer on the stack.
  $0332,$01 Move back to the previous character.
  $0333,$02 Jump to #R$0336.
@ $0335 label=ParseAllophoneGroup_Look
  $0335,$01 Stash the string pointer on the stack.
N $0336 Map the previous character through the suffix tables.
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
  $0349,$01 Set the carry flag.
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
  $035C,$01 Fetch the byte.
  $035D,$01 Return.

c $035E Normalise Character
@ $035E label=NormaliseCharacter
D $035E Convert a character towards the dictionary alphabet,
. and set workspace bit 6 for intonation (uppercase vs lowercase).
R $035E A Character
R $035E O:A Normalised character
  $035E,$01 Stash #REGhl on the stack.
  $035F,$01 Keep the character in #REGb.
  $0360,$04 Call #R$0354 for the flags byte.
  $0364,$01 Restore the character.
N $0365 Fold the letter into the dictionary alphabet. "A" and
. "a" both become #N$21.
  $0365,$04 Jump to #R$036F if this is not a lowercase letter.
  $0369,$02 Subtract #N$40 from a lowercase letter.
  $036B,$04 Use low intonation and jump to #R$0373.
@ $036F label=NormaliseCharacter_Upper
  $036F,$02 Subtract #N$20 from an uppercase letter.
  $0371,$02 Use high intonation.
@ $0373 label=NormaliseCharacter_Done
  $0373,$01 Restore #REGhl from the stack.
  $0374,$01 Return.

c $0375 Check Memory
@ $0375 label=CheckMemory
D $0375 Compare the speech-buffer pointer with
. *#SKOOLKID$5CB2(RAMTOP). Carry is set when the pointer has
. dropped into the reserved workspace.
R $0375 BC Buffer pointer
R $0375 O:F Carry set if #REGbc is below *#SKOOLKID$5CB2(RAMTOP)
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

c $0393 Compare Buffer
@ $0393 label=CompareBuffer
D $0393 Compare the live buffer pointer with the saved pointer
. in the workspace.
R $0393 O:F Z flag set when the two pointers match
  $0393,$01 Stash #REGhl on the stack.
  $0394,$05 Call #R$0354 for the saved pointer.
  $0399,$03 Call #R$037F.
  $039C,$02 Compare the two pointers.
  $039E,$01 Restore #REGhl from the stack.
  $039F,$02 Clear the carry flag.
  $03A1,$01 Return.

c $03A2 Reset Buffer Pointer
@ $03A2 label=ResetBufferPointer
D $03A2 Copy the saved queue pointer back over the live buffer pointer.
R $03A2 O:BC Restored buffer pointer
  $03A2,$02 Select workspace index #N$06.
  $03A4,$01 Stash #REGhl on the stack.
  $03A5,$03 Call #R$0354.
  $03A8,$02 Copy the saved pointer to #REGbc.
  $03AA,$03 Call #R$038A.
  $03AD,$01 Restore #REGhl from the stack.
  $03AE,$01 Return.

b $03AF Character Keys
@ $03AF label=CharacterKeys
D $03AF Letters and symbols that can appear in an allophone name.
. The matching allophone is #N$35 bytes later in #R$03CA.
  $03AF,$1B,$1B

b $03CA Mapped Characters
@ $03CA label=MappedCharacters
D $03CA Parallel table to #R$03AF.
  $03CA,$1B,$1B

b $03E5 Allophone Values
@ $03E5 label=AllophoneValues
D $03E5 Extra allophone bytes used when a parenthesised group
. is closed. Hear the IDs on the #LINK(Sound)(Allophones) page.
  $03E5,$36,$12

b $041B Suffix Keys
@ $041B label=SuffixKeys
D $041B Suffix letters used after certain allophone-name sums.
. The matching value is #N$08 bytes later in #R$0424.
  $041B,$09,$09

b $0424 Suffix Values
@ $0424 label=SuffixValues
D $0424 Parallel table to #R$041B.
  $0424,$09,$09

b $042D Punctuation Keys
@ $042D label=PunctuationKeys
D $042D Punctuation and token bytes spoken from *#SKOOLKID$5C08(LAST_K).
. The replacement is #N$0C bytes later in #R$043A.
  $042D,$0D,$0D

b $043A Punctuation Values
@ $043A label=PunctuationValues
D $043A Parallel table to #R$042D.
  $043A,$0D,$0D

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
  $0448,$05 EDIT. #AUDIO0(key-edit.wav)
  $044D,$07 ENTER. #AUDIO0(key-enter.wav)
  $0454,$08 Cursor. #AUDIO0(key-cursor.wav)
  $045C,$06 DELETE. #AUDIO0(key-delete.wav)
N $0462 Colour tokens, graphics and symbols.
  $0462,$04 INK. #AUDIO0(key-ink.wav)
  $0466,$06 PAPER. #AUDIO0(key-paper.wav)
  $046C,$07 Block graphics. #AUDIO0(key-graphics.wav)
  $0473,$05 FLASH. #AUDIO0(key-flash.wav)
  $0478,$06 BRIGHT. #AUDIO0(key-bright.wav)
  $047E,$07 INVERSE. #AUDIO0(key-inverse.wav)
  $0485,$04 OVER. #AUDIO0(key-over.wav)
  $0489,$03 AT. #AUDIO0(key-at.wav)
  $048C,$05 TAB. #AUDIO0(key-tab.wav)
  $0491,$0C "!". #AUDIO0(key-excl.wav)
  $049D,$05 Quotation mark. #AUDIO0(key-quot.wav)
  $04A2,$04 "&". #AUDIO0(key-amp.wav)
  $04A6,$0A "'". #AUDIO0(key-apos.wav)
  $04B0,$07 "(". #AUDIO0(key-lparen.wav)
  $04B7,$09 "<". #AUDIO0(key-lt.wav)
  $04C0,$06 ">". #AUDIO0(key-gt.wav)
  $04C6,$0E >=. #AUDIO0(key-ge.wav)
  $04D4,$11 <=. #AUDIO0(key-le.wav)
  $04E5,$0A <>. #AUDIO0(key-ne.wav)
  $04EF,$06 "/". #AUDIO0(key-slash.wav)
  $04F5,$09 "\". #AUDIO0(key-bslash.wav)
  $04FE,$05 ".". #AUDIO0(key-dot.wav)
  $0503,$05 ",". #AUDIO0(key-comma.wav)
  $0508,$0A ";". #AUDIO0(key-semi.wav)
  $0512,$08 "_". #AUDIO0(key-und.wav)
  $051A,$04 "*". #AUDIO0(key-star.wav)
  $051E,$05 "`". #AUDIO0(key-grave.wav)
  $0523,$06 "+". #AUDIO0(key-plus.wav)
  $0529,$07 "-". #AUDIO0(key-minus.wav)
  $0530,$06 Space. #AUDIO0(key-space.wav)
  $0536,$05 "^". #AUDIO0(key-hat.wav)
  $053B,$06 "?". #AUDIO0(key-query.wav)
  $0541,$03 "|". #AUDIO0(key-pipe.wav)
  $0544,$08 Copyright. #AUDIO0(key-copyright.wav)
  $054C,$04 LET. #AUDIO0(key-let.wav)
  $0550,$06 ":". #AUDIO0(key-colon.wav)
  $0556,$07 "=". #AUDIO0(key-eq.wav)
  $055D,$04 NEW. #AUDIO0(key-new.wav)
N $0561 Digits.
  $0561,$04 "0". #AUDIO0(key-0.wav)
  $0565,$04 "1". #AUDIO0(key-1.wav)
  $0569,$03 "2". #AUDIO0(key-2.wav)
  $056C,$04 "3". #AUDIO0(key-3.wav)
  $0570,$03 "4". #AUDIO0(key-4.wav)
  $0573,$04 "5". #AUDIO0(key-5.wav)
  $0577,$05 "6". #AUDIO0(key-6.wav)
  $057C,$06 "7". #AUDIO0(key-7.wav)
  $0582,$03 "8". #AUDIO0(key-8.wav)
  $0585,$05 "9". #AUDIO0(key-9.wav)
N $058A Number sign, dollar and percent.
  $058A,$04 "#". #AUDIO0(key-hash.wav)
  $058E,$05 "$". #AUDIO0(key-dollar.wav)
  $0593,$08 "%". #AUDIO0(key-pct.wav)
N $059B Letters.
  $059B,$02 "A". #AUDIO0(key-a.wav)
  $059D,$03 "B". #AUDIO0(key-b.wav)
  $05A0,$04 "C". #AUDIO0(key-c.wav)
  $05A4,$03 "D". #AUDIO0(key-d.wav)
  $05A7,$02 "E". #AUDIO0(key-e.wav)
  $05A9,$04 "F". #AUDIO0(key-f.wav)
  $05AD,$03 "G". #AUDIO0(key-g.wav)
  $05B0,$03 "H". #AUDIO0(key-h.wav)
  $05B3,$02 "I". #AUDIO0(key-i.wav)
  $05B5,$03 "J". #AUDIO0(key-j.wav)
  $05B8,$03 "K". #AUDIO0(key-k.wav)
  $05BB,$03 "L". #AUDIO0(key-l.wav)
  $05BE,$03 "M". #AUDIO0(key-m.wav)
  $05C1,$03 "N". #AUDIO0(key-n.wav)
  $05C4,$02 "O". #AUDIO0(key-o.wav)
  $05C6,$03 "P". #AUDIO0(key-p.wav)
  $05C9,$04 "Q". #AUDIO0(key-q.wav)
  $05CD,$02 "R". #AUDIO0(key-r.wav)
  $05CF,$04 "S". #AUDIO0(key-s.wav)
  $05D3,$03 "T". #AUDIO0(key-t.wav)
  $05D6,$03 "U". #AUDIO0(key-u.wav)
  $05D9,$03 "V". #AUDIO0(key-v.wav)
  $05DC,$07 "W". #AUDIO0(key-w.wav)
  $05E3,$04 "X". #AUDIO0(key-x.wav)
  $05E7,$03 "Y". #AUDIO0(key-y.wav)
  $05EA,$05 "Z". #AUDIO0(key-z.wav)
N $05EF BASIC tokens.
  $05EF,$05 RND. #AUDIO0(key-rnd.wav)
  $05F4,$06 INKEY$. #AUDIO0(key-inkey.wav)
  $05FA,$03 PI. #AUDIO0(key-pi.wav)
  $05FD,$08 FN. #AUDIO0(key-fn.wav)
  $0605,$06 SCREEN$. #AUDIO0(key-screen.wav)
  $060B,$04 ATTR. #AUDIO0(key-attr.wav)
  $060F,$05 VAL$. #AUDIO0(key-valstr.wav)
  $0614,$04 CODE. #AUDIO0(key-code.wav)
  $0618,$04 VAL. #AUDIO0(key-val.wav)
  $061C,$04 LEN. #AUDIO0(key-len.wav)
  $0620,$04 SIN. #AUDIO0(key-sin.wav)
  $0624,$04 COS. #AUDIO0(key-cos.wav)
  $0628,$04 TAN. #AUDIO0(key-tan.wav)
  $062C,$06 ASN. #AUDIO0(key-asn.wav)
  $0632,$07 ACS. #AUDIO0(key-acs.wav)
  $0639,$06 ATN. #AUDIO0(key-atn.wav)
  $063F,$05 LN. #AUDIO0(key-ln.wav)
  $0644,$05 EXP. #AUDIO0(key-exp.wav)
  $0649,$04 INT. #AUDIO0(key-int.wav)
  $064D,$04 SQR. #AUDIO0(key-sqr.wav)
  $0651,$04 ABS. #AUDIO0(key-abs.wav)
  $0655,$04 PEEK. #AUDIO0(key-peek.wav)
  $0659,$03 IN. #AUDIO0(key-in.wav)
  $065C,$05 USR. #AUDIO0(key-usr.wav)
  $0661,$06 STR$. #AUDIO0(key-str.wav)
  $0667,$04 CHR$. #AUDIO0(key-chr.wav)
  $066B,$04 NOT. #AUDIO0(key-not.wav)
  $066F,$04 BIN. #AUDIO0(key-bin.wav)
  $0673,$02 OR. #AUDIO0(key-or.wav)
  $0675,$04 LINE. #AUDIO0(key-line.wav)
  $0679,$04 THEN. #AUDIO0(key-then.wav)
  $067D,$03 TO. #AUDIO0(key-to.wav)
  $0680,$05 STEP. #AUDIO0(key-step.wav)
  $0685,$06 DEF FN. #AUDIO0(key-deffn.wav)
  $068B,$04 CAT. #AUDIO0(key-cat.wav)
  $068F,$06 FORMAT. #AUDIO0(key-format.wav)
  $0695,$04 MOVE. #AUDIO0(key-move.wav)
  $0699,$04 ERASE. #AUDIO0(key-erase.wav)
  $069D,$05 OPEN #. #AUDIO0(key-open.wav)
  $06A2,$05 CLOSE #. #AUDIO0(key-close.wav)
  $06A7,$05 MERGE. #AUDIO0(key-merge.wav)
  $06AC,$07 VERIFY. #AUDIO0(key-verify.wav)
  $06B3,$04 BEEP. #AUDIO0(key-beep.wav)
  $06B7,$06 CIRCLE. #AUDIO0(key-circle.wav)
  $06BD,$03 OUT. #AUDIO0(key-out.wav)
  $06C0,$09 LPRINT. #AUDIO0(key-lprint.wav)
  $06C9,$08 LLIST. #AUDIO0(key-llist.wav)
  $06D1,$05 STOP. #AUDIO0(key-stop.wav)
  $06D6,$04 READ. #AUDIO0(key-read.wav)
  $06DA,$05 DATA. #AUDIO0(key-data.wav)
  $06DF,$06 RESTORE. #AUDIO0(key-restore.wav)
  $06E5,$05 BORDER. #AUDIO0(key-border.wav)
  $06EA,$09 CONTINUE. #AUDIO0(key-continue.wav)
  $06F3,$04 DIM. #AUDIO0(key-dim.wav)
  $06F7,$04 REM. #AUDIO0(key-rem.wav)
  $06FB,$03 FOR. #AUDIO0(key-for.wav)
  $06FE,$06 GO TO. #AUDIO0(key-goto.wav)
  $0704,$07 GO SUB. #AUDIO0(key-gosub.wav)
  $070B,$06 INPUT. #AUDIO0(key-input.wav)
  $0711,$04 LOAD. #AUDIO0(key-load.wav)
  $0715,$05 LIST. #AUDIO0(key-list.wav)
  $071A,$04 PAUSE. #AUDIO0(key-pause.wav)
  $071E,$06 NEXT. #AUDIO0(key-next.wav)
  $0724,$04 POKE. #AUDIO0(key-poke.wav)
  $0728,$06 PRINT. #AUDIO0(key-print.wav)
  $072E,$05 PLOT. #AUDIO0(key-plot.wav)
  $0733,$04 RUN. #AUDIO0(key-run.wav)
  $0737,$04 SAVE. #AUDIO0(key-save.wav)
  $073B,$09 RANDOMIZE. #AUDIO0(key-randomize.wav)
  $0744,$03 IF. #AUDIO0(key-if.wav)
  $0747,$04 DRAW. #AUDIO0(key-draw.wav)
  $074B,$04 CLEAR. #AUDIO0(key-clear.wav)
  $074F,$06 RETURN. #AUDIO0(key-return.wav)
  $0755,$05 COPY. #AUDIO0(key-copy.wav)
  $075A,$01 Table end.

w $075B Banner Addresses
@ $075B label=BannerAddresses
D $075B Pointers to the 8x8 bitmaps that spell
. "speech system © CURRAH 1983". #N$FFFF ends the list.
  $075B,$02 #N$07A0 ("s").
  $075D,$02 #N$07A8 ("p").
  $075F,$02 #N$07B0 ("e").
  $0761,$02 #N$07B0 ("e").
  $0763,$02 #N$07B8 ("c").
  $0765,$02 #N$07C0 ("h").
  $0767,$02 #N$0798 (space).
  $0769,$02 #N$07A0 ("s").
  $076B,$02 #N$07C8 ("y").
  $076D,$02 #N$07E0 ("s").
  $076F,$02 #N$07D8 ("t").
  $0771,$02 #N$07B0 ("e").
  $0773,$02 #N$07D0 ("m").
  $0775,$02 #N$0798 (space).
  $0777,$02 #N$07E8 (copyright).
  $0779,$02 #N$0798 (space).
  $077B,$02 #N$07F0 ("C").
  $077D,$02 #N$07F8 ("U").
  $077F,$02 #N$0008 ("R").
  $0781,$02 #N$0008 ("R").
  $0783,$02 #N$0010 ("A").
  $0785,$02 #N$0018 ("H").
  $0787,$02 #N$0798 (space).
  $0789,$02 #N$0020 ("1").
  $078B,$02 #N$0028 ("9").
  $078D,$02 #N$0030 ("8").
  $078F,$02 #N$0000 ("3").
  $0791,$02 Terminator.

t $0793 Programmer Credit
@ $0793 label=ProgrammerCredit
D $0793 Name stored after the banner address table.
  $0793,$05 "Anson".

b $0798 Banner Bitmaps
@ $0798 label=BannerBitmaps
D $0798 Space, "speech system" letters, the copyright mark and
. inverse "CU". Inverse "RRAH" and the "1983" digits live at #R$0000.
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
