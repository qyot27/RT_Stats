Function TweenFlashFields(clip c,float  "FlashThresh",bool "Show") {
# Replace single isolated bad fields eg Black or White with a field tweened from those either side using MvTools, and RT_Stats.
# Will Likely fix a single Bright/Dark Flash field after scene change where will be replaced with a blend of before and after fields.
#    This due to NoPan failure, ie fields before and after flash are likely to be more similar (even though dif scenes) than to flash field.
#    There has been no attempt to fix this fortunate failure.
# FlashThresh Default 1.15 (white flash detect), is a threshold of AveLuma_Ratio, Flash_Field_AveLuma / Adjacent_Field_AveLuma.
#   Values above 1.0 detect WHITE/Flash fields, Below 1.0 detect BLACK/Flash fields (suggest for Black eg 1.0/1.15 = 0.87)
#   When FlashThresh above 1.0 (detecting WHITE flash) :
#       If AveLuma_Ratio > FlashThresh, for both adjacent fields then is possible white flash
#   When FlashThresh below 1.0 (detecting BLACK flash) :
#       If AveLuma_Ratio < FlashThresh, for both adjacent fields then is possible black flash
#   When FlashThresh < 0.0, will simultaneously fix both White and Black Flash frames, eg -1.15 will use equivalent to 1.15 for white
#       and 1.0/1.15 for Black.
#   1.0 or -1.0 exactly, Throws an Error.
# Show: Puts indicator on fixed fields.
    c
    FlashThresh = Float(Default(FlashThresh,1.15))                  # Default detects White flash
    Show=Default(Show,False)
    Assert(FlashThresh != 1.0 && FlashThresh != -1.0,"TweenFlashFrames: FlashThresh Cannot be 1.0 Nor -1.0")
    (FlashThresh < 0.0 && FlashThresh > -1.0) ? 1.0 / FlashThresh : FlashThresh
    CondS="""
        ave_p   = Max(RT_AverageLuma(delta=-1), 0.01)               # Avoid Division By Zero
        ave     = RT_AverageLuma()
        ave_n   = Max(RT_AverageLuma(delta=1), 0.01)
        rat_p   = ave / ave_p                                       # AveLuma_Ratio for Prev
        rat_n   = ave / ave_n                                       # AveLuma_Ratio for Next
        Flash   =(FlashThresh<0.0)
            \ ? ((rat_p > -FlashThresh && rat_n > -FlashThresh) || (rat_p < -1.0/FlashThresh && rat_n < -1.0/FlashThresh))
            \ : (FlashThresh>1.0)
            \ ? (rat_p > FlashThresh && rat_n > FlashThresh)
            \ : (rat_p < FlashThresh && rat_n < FlashThresh)
        dif_p=RT_YDifference(delta=-1)                              # Diff Prev <-> Curr
        dif_n=RT_YDifference(delta=1)                               # Diff Curr <-> Next
        dif_pn=RT_YDifference(current_frame-1,delta=2)              # Diff Prev <-> Next (either side of current)
        NoPan = (dif_pn < dif_p && dif_pn < dif_n)                  # (Prev<->Next < Prev<->Curr) AND (Prev<->Next < Curr<->Next)
        clpn = (Flash && NoPan) ? 1 : 0
#       RT_DebugF("%d ] EVEN Rat_p=%.2f Rat_n=%.2f Flash=%s Dif_pn=%.2f Dif_p=%.2f Dif_n=%.2f NoPan=%s Tween=%s",
#               \ current_frame,rat_p,rat_n,(Flash)?"T":"F",Dif_pn,Dif_p,Dif_n,(NoPan)?"T":"F",(clpn==1)?"Y":"N")
        clpn
    """
    SepC=SeparateFields()
    EvenC=SEPC.SelectEven()
    PrevC=EvenC.DeleteFrame(FrameCount-1).DuplicateFrame(0) # Make clip where prev fields are aligned with curr fields (same length)
    super = PrevC.MSuper()
    backward_vectors = MAnalyse(super, isb = true,truemotion=true, delta=2)
    forward_vectors  = MAnalyse(super, isb = false,truemotion=true, delta=2)
    TweenC = PrevC.MFlowInter(super, backward_vectors, forward_vectors, time=50, ml=70)     # Tweened clip
    TweenC = (show) ? TweenC.Subtitle("EVEN FIELD FIXED",size=24,text_color=$0000FF,align=5,y=EvenC.Height/2-24) : TweenC
    CondSE=RT_StrReplace(CondS,"FlashThresh",String(FlashThresh))   # Import explicit FlashThresh into condition string
    EvenFixedC=ConditionalSelect(EvenC,CondSE,EvenC,TweenC)         # Fix bad EVEN fields
    OddC=SepC.SelectOdd()
    PrevC=OddC.DeleteFrame(FrameCount-1).DuplicateFrame(0)
    super = PrevC.MSuper()
    backward_vectors = MAnalyse(super, isb = true,truemotion=true, delta=2)
    forward_vectors  = MAnalyse(super, isb = false,truemotion=true, delta=2)
    TweenC = PrevC.MFlowInter(super, backward_vectors, forward_vectors, time=50, ml=70)     # Tweened clip
    TweenC = (show) ? TweenC.Subtitle("ODD FIELD FIXED",size=24,text_color=$0000FF,align=5,y=OddC.Height/2) : TweenC
    CondSO=RT_StrReplace(CondSE,"EVEN","ODD")
    OddFixedC=ConditionalSelect(OddC,CondSO,OddC,TweenC)                # Fix bad Odd fields
    Interleave(EvenFixedC,OddFixedC)
    Weave()
    return Last
}
