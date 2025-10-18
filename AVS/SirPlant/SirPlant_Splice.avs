# SirPlant_Splice.avs

vSrc="S.avi"
vRep="R.avi"

#
Project="Default"
Cmd=Project+"_Command.txt"
SHOW        = True
SRC_AUDIO   = False         # Use only Source audio. ONLY if STRICT and not inserting EXTRA replacement ranges, else out of sync audio likely
                            # Use SRC_AUDIO = True, Only if STRICT==TRUE at detector stage.

STACK       = False         # Same for STACK, only True if Strict and no EXTRA replacement ranges.

NORM=(!SHOW && !STACK && !SRC_AUDIO)


A=AVISource(vSrc)
D=AVISource(vRep)

A = (NORM) ? A.Normalize : A
D = (NORM) ? D.Normalize : D

B=A     C=A
E=D     F=D

A = (SHOW) ? A.AddBorders(0,0,0,16,$000000) : A
B = (SHOW) ? B.AddBorders(0,0,0,16,$404040) : B
C = (SHOW) ? C.AddBorders(0,0,0,16,$808080) : C
D = (SHOW) ? D.AddBorders(0,0,0,16,$00FF00) : D
E = (SHOW) ? E.AddBorders(0,0,0,16,$FF0000) : E
F = (SHOW) ? F.AddBorders(0,0,0,16,$0000FF) : F

SrcAudio=A.KillVideo

Nicks="""
    InterveningSource=0
    MatchingSource=1
    EndRangeSource=2
    MatchingReplacement=3
    ExtraReplacement=4
    EndRangeReplacement=5
"""


Prune(A,B,C,D,E,F,cmd=Cmd,NickName=Nicks,Show=SHOW)

(SRC_AUDIO) ? AudioDub(SrcAudio) : NOP

return (STACK) ? StackVertical(A,Last) : Last
