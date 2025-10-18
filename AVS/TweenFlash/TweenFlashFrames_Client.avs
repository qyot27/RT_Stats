Import("TweenFlashFrames.avs")

AVISource("D:\avs\test.avi")

# Pick a simulated test below

#Return TweenFlashFrames_TestClip($FFFFFF)                                                  # White NOFIX
#Return TweenFlashFrames_TestClip($FFFFFF).TweenFlashFrames(FlashThresh=1.15,Show=true)     # Fix White frames PROGRESSIVE

#Return TweenFlashFrames_TestClip($000000)                                                  # BLACK NOFIX
#Return TweenFlashFrames_TestClip($000000).TweenFlashFrames(FlashThresh=0.87,Show=true)     # Fix Black frames PROGRESSIVE

Function TweenFlashFrames_TestClip(clip c,int "Color") {
# Replace every 8th frame with blank.
    c
    Color=Default(Color,$FFFFFF)
    BAD=Last.BlankClip(color=Color)
    A=SelectEvery(8,0)  B=SelectEvery(8,1)  C=SelectEvery(8,2)  D=SelectEvery(8,3)
    E=SelectEvery(8,4)  F=SelectEvery(8,5)  G=SelectEvery(8,6)
    Interleave(A,B,C,D,E,F,G,BAD)   # every 8th frame replaced with BAD
    Return Trim(0,1000)
}
