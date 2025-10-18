# SirPlant_ShowNonReplaced.avs

repFN="R.AVI"

Project="Default"

Cmd=Project+"_UnUsed.txt"

A=AVISource(repFN)

Nicks="""
    ShortRangeLessThanMinReplace=0
    SkippedExtras=1
"""
SHOW=True

Prune(A,A,cmd=Cmd,NickName=Nicks,Show=SHOW)
