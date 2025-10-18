Import(".\ImageSplicer.avs")

FN=".\*.BMP|JPG|JPE|JPEG|PNG|TGA|TIF|GIF|TIFF"
SzLimit= -768
FAR=1.333
AutoCrop=True
AutoLevelStrength=1.0
ShowBorder=True
ShowAutoLevel = True
Subs          = True
CropThresh    = -0.5
FPS           = 1.0
WMOD          = 4
HMOD          = 4
IGNORE        = 0.4
ScanPerc      = 49.0
Baffle        = 4
Debug         = True
Debug_QBC     = False
Resizer       = "Spline64resize(_W_,_H_)"       # Change to eg "Spline36resize(_W_,_H_)"
Matrix        = 2
ATM           = 0.5

TimeStart = RT_Timer()

ImageSplicer(FN,SzLimit,FAR=FAR,AutoCrop=AutoCrop,AutoLevelStrength=AutoLevelStrength,ShowBorder=ShowBorder,ShowAutoLevel=ShowAutoLevel,
	\ Subs=Subs, CropThresh=CropThresh,Fps=FPS,Wmod=WMOD,Hmod=HMOD,Baffle=Baffle,ScanPerc=ScanPerc,Debug=Debug,Debug_QBC=Debug_QBC,
    \ Ignore=IGNORE,Resizer=Resizer,matrix=matrix,ATM=ATM)
#ImageSplicer(FN,SzLimit=1024)


TimeEnd = RT_Timer()
SubTitle("TIME = "+String(TimeEnd-TimeStart,"%6.2f")+" secs",align=9,Y=0)
