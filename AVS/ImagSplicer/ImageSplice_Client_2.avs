import(".\ImageSplicer.avs")

FN=".\*.BMP|JPG|JPE|JPEG|PNG|TGA|TIF|GIF|TIFF"
SZLIMIT     =   -768        # Height=Abs(SZLIMIT)
FAR         =   4.0/3.0
AUTOCROP    =   TRUE
STRENGTH    =   0.66
SHOWAL      =   False
SHOWBORD    =   False
SUBS        =   False
CROPTHRESH  =   -0.5
FPS         =   1.0
WMOD        =   4
HMOD        =   4
DEBUG       =   TRUE
IGNORE      =   0.4
BORDCOL     =   $001144     # Added for goorawin
ATM         =   0.5         # Added, arg to QueryborderCrop

myName="ImageSplice_Client_2: "
IsAvsPlus=(FindStr(UCase(versionString),"AVISYNTH+")!=0)    HasGScript=RT_FunctionExist("GScript")
Assert(IsAvsPlus || HasGScript,RT_String("%sNeed either GScript or AVS+",myName))

Anim = ImageSplicer(FN,SzLimit=SZLIMIT,Far=FAR,AutoCrop=AUTOCROP,AutoLevelStrength=STRENGTH,ShowAutoLevel=SHOWAL,ShowBorder=SHOWBORD,
                \ Subs=SUBS,CropThresh=CROPTHRESH,Fps=FPS,Wmod=WMOD,Hmod=HMOD,Debug=DEBUG,IGnore=IGNORE,BorderColor=BORDCOL,ATM=ATM)

OUT_SecondsPerFrame = 5  # How long each frame is diplayed for
OUT_FPS             = 25.0 # Final Output FrameRate
FADE_FRAMES         = Int(OUT_FPS/2)
T1                  = Int(OUT_SecondsPerFrame*OUT_FPS)
T2                  = T1+FADE_FRAMES

anim.AssumeFPS(1).ChangeFPS(T2) # repeat each frame for OUT_SecondsPerFrame + ~0.5 sec overlap

Vid = Trim(FADE_FRAMES, -T1)       # first chunk


GS="""
    for (f=T2, Framecount-T2, T2) {
        next = Trim(f, -T2) # next chunk, incl overlap
        vid = Dissolve(vid, next, FADE_FRAMES)
    }
"""

HasGScript ? GScript(GS) : Eval(GS) # Use GSCript if installed (loaded plugs override builtin)


Return Vid.AssumeFPS(OUT_FPS)
