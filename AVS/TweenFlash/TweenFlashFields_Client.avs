Import("TweenFlashFields.avs")

AVISource("D:\avs\test.avi")

# Pick a Simulated test below

#Return TweenFlashFields_TEST($FFFFFF)                                                  # White NOFIX
#Return TweenFlashFields_TEST($FFFFFF).TweenFlashFields(FlashThresh=1.15,Show=True)     # Fix White fields INTERLACED

#Return TweenFlashFields_TEST($000000)                                                  # BLACK NOFIX
#Return TweenFlashFields_TEST($000000).TweenFlashFields(FlashThresh=0.87,Show=True)     # Fix Black fields INTERLACED

Function TweenFlashFields_TEST(clip c,int "Color") {
# Replace every 8th EVEN field and every 12th ODD field with a blank.
    Color=Default(Color,$FFFFFF)
    SEP=c.SeparateFields    BAD=SEP.BlankClip(color=Color)  EVEN=SEP.SelectEven()
    A=EVEN.SelectEvery(8,0) B=EVEN.SelectEvery(8,1) C=EVEN.SelectEvery(8,2) D=EVEN.SelectEvery(8,3)
    E=EVEN.SelectEvery(8,4) F=EVEN.SelectEvery(8,5) G=EVEN.SelectEvery(8,6) EVEN=Interleave(A,B,C,D,E,F,G,BAD)
    ODD=SEP.SelectODD()     A=ODD.SelectEvery(12,0) B=ODD.SelectEvery(12,1) C=ODD.SelectEvery(12,2)
    D=ODD.SelectEvery(12,3) E=ODD.SelectEvery(12,4) F=ODD.SelectEvery(12,5) G=ODD.SelectEvery(12,6)
    H=ODD.SelectEvery(12,7) I=ODD.SelectEvery(12,8) J=ODD.SelectEvery(12,9) K=ODD.SelectEvery(12,10)
    ODD=Interleave(A,B,C,D,E,F,G,H,I,J,K,BAD)   Interleave(EVEN,ODD)    Weave()
    Return Trim(0,1000)
}
