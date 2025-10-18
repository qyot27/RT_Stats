import(".\PlanetCrop.avs")

Fn="D:\PlanetCrop\MOON\*.jpg"
BAFFLE		= 8		# Number of consecutive scanlines that need to pass, below considered noise.
BLK			= 28		# Where black sky can vary in brightness
GROW_W		= 128		# Enlarge canvas width  by GROW_W pixels (keep surround area, Use with KEEP_MARGIN)
GROW_H		= 128		# Enlarge canvas height by GROW_H pixels
FAR			= 1.0		# Frame Aspect Ratio
STRENGTH	= 1.0		# AutoLevel Strength 0.0 -> 1.0
SHOWAL		= False		# Right Hand Side Only AutoLeveled
KEEP		= True		# True tries to keep some of the cropped area instead of AddBorders
SHOWKEEP	= False		# Show Kept margin
SHOWBORDER	= False		# True Show replaced border in Red, else Black. (FAR affects) (Test CROP)
DEBUG		= True
MATRIX		= RT_Undefined
ShowDetectOnly = False
#ShowDetectOnly = True

TimeStart = RT_Timer()

PlanetCrop(Fn,BAFFLE,BLK,GROW_W,GROW_H,FAR,STRENGTH,SHOWAL,KEEP,SHOWKEEP,SHOWBORDER,DEBUG,Matrix,ShowDetectOnly)
#PlanetCrop(Fn,Baffle=Baffle,debug=true,AutoLevelStrength=1.0)
return last
TimeEnd = RT_Timer()
SubTitle("TIME = "+String(TimeEnd-TimeStart,"%6.2f")+" secs",align=9,Y=0)
