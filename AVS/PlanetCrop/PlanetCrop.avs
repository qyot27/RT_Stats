Function PlanetCrop(String "FileName",int "Baffle",Int "BlackRange",int "Grow_W",int "Grow_H",Float "FAR", \
        Float "AutoLevelStrength",bool "ShowAutoLevel",bool "KeepMargin",bool "ShowMargin",bool "ShowBorder",bool "Debug",\
        int "Matrix",bool "ShowDetectOnly") {
# ------------
    VERS="PlanetCrop v1.03 - 02 Aug 2018"       # Requires GScript(or AVS+), RT_Stats v1.43.
# ------------
# Given a series of time lapse planetoid images moving across frame (due to earth rotation), locates those images in frame, crops out
# and splices them all together into a video clip of required Frame Aspect Ratio, 1 FPS, with optional Auto Luma Levelling.
#     First scans each image establishing maximum dimensions for whole sequence (after cropping out the planets). Optionally 'grows' those
# dimensions to maintain some of the area around the cropped planets. A 'canvas' size is then established to contain the now maximum
# dimensions and respecting the desired Frame Aspect Ratio, synthetic black borders are added where necessary.
# Borders are the synthetic areas added to maintain aspect ratio and can be hi-lited in red. Margins are areas that use the
# original image content instead of synthetic black borders (where possible), they replace synthetic borders, and can be hi-lited
# in green. Margins are the areas between the established crop coords and synthetic borders.
# --------------------------------------
# Args:-
#  Filename: Default "*.BMP|JPG|JPE|JPEG|PNG|TGA|TIF|GIF|TIFF". Image Path and wildcard with mulitple pipe separated extensions.
#  Baffle: Default 8. Number of scanlines that must break a threshold to be accepted as 'planet'. Avoids noise.
#   Suggest about 4 -> 32. Must NOT be greater than diameter of planets (or anywhere near not a good idea).
#  BlackRange: Default 32. Where background (sky) can vary in luminance by a significant amount. When creating detection clip, will
#    use eqivalent to Levels(YPlaneMin+BlackRange-1,1.0,YPlaneMin+BlackRange,0,255,Coring=False) for detecting planet.
#  Grow_W,Grow_H: Default 128. Size in pixels by which to 'grow' the accumulated maximum dimensions once all planets have been identified.
#  FAR: Default 4.0/3.0. Frame Aspect Ratio.
#  AutoLevelStrength: Default 0.0. Auto luma leveling, range 0.0 -> 1.0. 0.0 is OFF.
#  ShowAutoLevel: Default False. If true then shows Auto leveling on right hande side of image ONLY.
#  KeepMargin: Default True. When padding to maintain Frame Aspect Ratio, tries to keep image instead of adding synthetic borders.
#  ShowMargin: Default False. If True, shows kept margins in Green.
#  ShowBorder: Default False. When padding to maintain Frame Aspect Ratio, borders are shown in red.
#  Debug: Default False. Show debug info via DebugView. Need DebugView: http://technet.microsoft.com/en-gb/sysinternals/bb545027
#  Matrix: Default=2(PC601), 3=PC709. Used in conversion of RGB to YUV-Y. (Dont use 0 or 1, TV levels)
#  ShowDetectOnly: Default False. If True, then ONLY returns equivalent Detection clip that would be used, created using BlackRange.
#    May assist in selecting BlackRange. NOTE, All images MUST be same size else error as no cropping done. Any non-black in the detect
#    clip will be detected as possible planet (if Baffle consecutive scanlines present, then IS planet).
#

    myName      = "PlanetCrop: "
    IsAvsPlus=(FindStr(UCase(versionString),"AVISYNTH+")!=0)    HasGScript=RT_FunctionExist("GScript")
    Assert(IsAvsPlus || HasGScript,RT_String("%sNeed either GScript or AVS+",myName))

    DEBUG_YInRangeLocate=False
    FileName = Default(FileName,"*.BMP|JPG|JPE|JPEG|PNG|TGA|TIF|GIF|TIFF")
    Baffle=Default(Baffle,8)
    BlackRange=Default(BlackRange,32)                   # YPlaneMin + BlackRange and above, is possible planet
    Grow_W=Default(Grow_W,128)
    Grow_H=Default(Grow_H,128)
    FAR=Float(Default(FAR,4.0/3.0))
    AutoLevelStrength=Float(Default(AutoLevelStrength,0.0))
    ShowAutoLevel=Default(ShowAutoLevel,false)
    KeepMargin=Default(KeepMargin,True)
    ShowMargin=Default(ShowMargin,False)
    ShowBorder=Default(ShowBorder,False)
    DEBUG=Default(DEBUG,False)
    Matrix=Default(Matrix,2)                            # PC601
    ShowDetectOnly=Default(ShowDetectOnly,False)        #
    # Lesser changed stuff Hardcoded
    BORDER      = $FF0000                               # Color for replaced borders.
    MARGINBORDER= $00FF00                               # Color for KEEP_MARGIN borders.
    FPS         = 1.0                                   # Whatever.
    WMOD        = 2                                     # For Canvas Width
    HMOD        = 2                                     # For Canvas Height
    OUT_FILE    = "PLANETCROP.List"
    Assert(Baffle>0,"PlanetCrop: Baffle must be 1 or more")
    Assert(BlackRange>=0,"PlanetCrop: BlackRange must be 1 or more")
    Assert(Grow_W>=0,"PlanetCrop: Grow_W Cannot be -ve")
    Assert(Grow_H>=0,"PlanetCrop: Grow_H Cannot be -ve")
    Assert(FAR>0.0,"PlanetCrop: FAR must be greater than 0.0")
    Assert(AutoLevelStrength>=0.0 && AutoLevelStrength <= 1.0,"PlanetCrop: AutoLevelStrength must be 0.0 -> 1.0")
    Assert(Matrix>=2 && Matrix<=3,"PlanetCrop: Bad Matrix, suggest 2=PC601,3=PC709")
    ShowAutoLevel=(AutoLevelStrength==0.0) ? false : ShowAutoLevel
    PCStart=RT_Timer()
    #
    GS="""
        #
        if(DEBUG){ RT_Debug("PlanetCrop:",false) RT_Debug("PlanetCrop:",VERS,"- By StainlessS",false) RT_Debug("PlanetCrop:",false) }
        picclip = 0                                                                 # Dummy for now
        result=RT_WriteFileList(FileName,OUT_FILE)                                  # Create a listing file of Pic files
        Assert((result!=0), "No files found for "+FileName)
        FILELIST=RT_ReadTxtFromFile(OUT_FILE)                                       # Get list of files
        NFILES=RT_TxtQueryLines(FILELIST)                                           # Query Number of lines in String ie number of files.
        if(DEBUG){RT_Debug("PlanetCrop:","Found files = " + String(NFILES),false) RT_Debug("PlanetCrop:",false)}
        # Prescan to ascertain max wid/hit of all files, also Autocrop & Auto Levels
        MAXH=0 MAXW=0                                                               # init max wid and hit
        MINLUM=256 MAXLUM= -1
        CROPCOORDS=""                                                               # Clear results array (string)
        AUTOLEVEL=(AutoLevelStrength>0.0)                                           # Adjust using Levels.
        if(ShowDetectOnly) {
            For(i=0,NFILES-1) {
                FN=RT_TxtGetLine(FILELIST,i)                                        # Filename of pic file i
                k=ImageReader(FN,end=0).ConvertToRGB32()
                k.RT_YStats(0,x=4,y=4,w=-4,h=-4,threshold=0.2,matrix=Matrix,flgs=3,Prefix="PC_")    # Get GlobVars PC_yMin & PC_yMax, avoid edges
                k=k.Levels(PC_yMin+BlackRange-1,1.0,PC_yMin+BlackRange,0,255,Coring=false)
                picclip = (IsClip(picclip)) ? picclip ++ k : k
            }
        } else {
            For(i=0,NFILES-1) {
                FN=RT_TxtGetLine(FILELIST,i)                                            # Filename of pic/vid file i
                (DEBUG)?RT_Debug("PlanetCrop:",String(i+1)+"/"+String(NFILES)+") Getting File dimensions",FN,false):NOP
                k=ImageReader(FN,end=0).ConvertToRGB32()
                OrgW=k.width    OrgH=k.height
                # For QPC
                k.RT_YStats(0,x=4,y=4,w=-4,h=-4,threshold=0.2,matrix=Matrix,flgs=3,Prefix="PC_")    # Get GlobVars PC_yMin & PC_yMax, avoid edges
                if(MINLUM>PC_yMin) {MINLUM=PC_yMin}
                if(MAXLUM<PC_yMax) {MAXLUM=PC_yMax}
                IRL=k.RT_YInRangeLocate(n=0,Baffle=Baffle,Matrix=Matrix,Prefix="PC_",debug=DEBUG&&DEBUG_YInRangeLocate,lo=PC_yMin+BlackRange-1,hi=255)
                Assert(IRL==True,"PlanetCrop: Cannot Locate Planet")
                PCS="PC_X="+String(PC_X)+" PC_Y="+String(PC_Y)+" PC_W="+String(PC_W)+" PC_H="+String(PC_H)
                CROPCOORDS=RT_TxtAddStr(CROPCOORDS,PCS)
                If(MAXW<PC_W) {MAXW=PC_W}
                If(MAXH<PC_H) {MAXH=PC_H}
                if (DEBUG) {                                                # KEEP main debug messages together
                    RT_Debug ("PlanetCrop:","Orig Width =",String(orgW),"Orig Height =",String(OrgH),false)
                    if((PC_W != OrgW) || (PC_H != OrgH)) {                  # Was Caused by AUTOCROP
                        RT_Debug("PlanetCrop:","Crop Width =",String(PC_W),"Crop Height =",String(PC_H),false)
                    }
                    RT_Debug("PlanetCrop:","MAX Width So Far =",String(MAXW)  ,"MAX Height So Far =",String(MAXH),false)
                    RT_Debug("PlanetCrop:","MIN LUMA  So Far =",String(MINLUM)," MAX LUMA   So Far =",String(MAXLUM),false)
                    RT_Debug("PlanetCrop:"," ----------------------------- ",false)            # line separator
                }
            }
            if(Grow_W>0 || Grow_H > 0) {
                (DEBUG)?RT_Debug("PlanetCrop:","Enlarging Max Width,Height to enlarge canvas",false):NOP
                MAXW=MAXW+Grow_W
                MAXH=MAXH+Grow_H
            }
            maxFAR = Float(MAXW) / MAXH
            if(FAR >= maxFAR) {
                # Required Frame Aspect Ratio greater or same as maximum accumulated dimensions. Need to pad horizontal
                    canvasheight    = Int((MAXH  + (HMOD-1)) / HMOD) * HMOD                 # round UP to next multiple of HMOD
                    canvaswidth     = Int((canvasheight * FAR + (WMOD-1)) / WMOD) * WMOD    # round UP to next multiple of WMOD
            } else {    # Need to pad vertical
                    canvaswidth     = Int((MAXW  + (WMOD-1)) / WMOD) * WMOD
                    canvasheight    = Int((canvaswidth / FAR + (HMOD-1)) / HMOD) * HMOD
            }
            if(DEBUG){
                RT_Debug("PlanetCrop:","SETTING CanvasWidth =",String(canvaswidth)," CanvasHeight =",String(canvasheight),false)
                RT_Debug("PlanetCrop:","Clip Global MINLUM =",String(MINLUM),"  MAXLUM =",String(MAXLUM),false)
                RT_Debug("PlanetCrop:"," ----------------------------- ",false)       # line separator
            }
            CSMin = 0   CSMax = 255     Almin = CSMin   AlMax=CSMax
            LBORDER=BORDER RBORDER=BORDER           # Init Default Show border colors
            if (AUTOLEVEL || !ShowMargin || !Showborder) {                                      # We need Minlum
                if (AUTOLEVEL) {    # AutoLevel based on clip global MINLUM & MAXLUM
                    ALMin = Int(CSMin - ((CSMin - MINLUM) * AutoLevelStrength) + 0.5) # Round Up
                    ALMax = Int(CSMax - ((CSMax - MAXLUM) * AutoLevelStrength))       # Round down
                }
                BACKGROUND=(MINLUM*256+MINLUM)*256+MINLUM                           # Min Luma as RGB color for non autolevel border
                if(!Showborder) { # Show CSMin (0) where autoleveled else BACKGROUND (MINLUM)
                    RBORDER = (AUTOLEVEL)       ? CSMin         : BACKGROUND                    # Right half Border
                    LBORDER = (ShowAutoLevel)   ? BACKGROUND    : RBORDER                       # Left half Border
                }
            }
            For(i=0,NFILES-1) {                         # Cropping and adding borders, Splicing to clip
                FN=RT_TxtGetLine(FILELIST,i)            # Filename of pic file i
                if(DEBUG){RT_Debug("PlanetCrop:",string(i+1)+"/"+String(NFILES)+")","Processing File",FN,false)}
                k=ImageReader(FN,end=0).ConvertToRGB32()
                OrgW=k.width    OrgH=k.height
                Eval(RT_TxtGetLine(CROPCOORDS,i))
                Left =(canvaswidth-PC_W) / 2        Right = canvaswidth-PC_W - Left     # Borders needed to respect FAR
                Top  =(canvasheight-PC_H) /         2Bot  = canvasheight-PC_H-Top
                Left2=0 Right2=0    Top2=0  Bot2=0                  # Init margin borders
                if(KeepMargin) {                # Get margins (available image usable instead of artificial border [maintain FAR])
                    Left2   =   ((PC_X<Left) ? PC_X : Left)         # margin limited by how much image is available
                    Left=Left-Left2                                 # Reduce artificial border by margin
                    Right2  =   (((OrgW-PC_X-PC_W)<Right) ? (OrgW-PC_X-PC_W) : Right)   Right=Right-Right2
                    Top2    =   ((PC_Y<Top) ? PC_Y : Top)                               Top=Top-Top2
                    Bot2    =   (((OrgH-PC_Y-PC_H)<Bot) ? (OrgH-PC_Y-PC_H) : Bot)       Bot=Bot-Bot2
                    if(!ShowMargin) { # Reduce cropping to keep original image in margin area, ELSE AddBorders show green margins.
                            PC_X=PC_X-Left2 PC_W=PC_W+Left2+Right2  PC_Y=PC_Y-Top2  PC_H=PC_H+Top2+Bot2
                            Left2=0 Right2=0    Top2=0  Bot2=0          # Not using Margin Addborders
                    }
                }
                (DEBUG)? RT_Debug("PlanetCrop:","Crop("+String(PC_X)+","+String(PC_Y)+","+String(PC_W)+","+String(PC_H)+")",false) : NOP
                k=k.Crop(PC_X,PC_Y,PC_W,PC_H)
                tmpw=(CanvasWidth/2) - Left - Left2                 # Canvas centered rather than cropped planet centered
                LeftClip = k.Crop(0,0,tmpw,-0)
                RightClip= k.Crop(tmpw,0,-0,-0)
                if (AUTOLEVEL) {
                    (DEBUG)?RT_Debug("PlanetCrop:","Levels("+String(ALMin)+",1.0,"+String(AlMax)+","+String(CSMin)+","+String(CSMax)+",Coring=False)",false):NOP
                    RightClip = RightClip.Levels(ALMin,1.0,ALMax,CSMin,CSMax,Coring=False)              # DONT EVER USE Coring
                    if(!ShowAutoLevel) {
                        LeftClip = LeftClip.Levels(ALMin,1.0,ALMax,CSMin,CSMax,Coring=False)            # DONT EVER USE Coring
                    }
                }
                if(KeepMargin && ShowMargin) {
                    (DEBUG)?RT_Debug("PlanetCrop:","Margin AddBorders("+String(Left2)+","+String(Top2)+","+String(Right2)+","+String(Bot2)+")",false):NOP
                    LeftClip    =   LeftClip.Addborders (Left2,Top2,0,Bot2,MARGINBORDER)
                    RightClip   =   RightClip.Addborders(0,Top2,Right2,Bot2,MARGINBORDER)
                }
                (DEBUG) ? RT_Debug("PlanetCrop:","AddBorders("+String(Left)+","+String(Top)+","+String(Right)+","+String(Bot)+")",false) : NOP
                LeftClip  = LeftClip.Addborders (Left,Top,0,Bot,LBORDER)
                RightClip = RightClip.Addborders(0,Top,Right,Bot,RBORDER)
                k=StackHorizontal(LeftClip,RightClip)
                picclip = (IsClip(picclip)) ? picclip ++ k : k              # Append to  clip so far
                if(DEBUG){
                    RT_Debug("PlanetCrop:",false)
                    RT_Debug("PlanetCrop:"," ----------------------------- ",false)
                }
            }
        }
        PCEnd=RT_Timer()
        if(DEBUG) {
            RT_Debug("PlanetCrop:","Deleting",OUT_FILE,false)
            RT_Debug("PlanetCrop:","Time Taken="+String(PCEnd-PCStart,"%6.2f")+"Secs",false)
        }
        RT_FileDelete(OUT_FILE)
    """

    HasGScript ? GScript(GS) : Eval(GS) # Use GSCript if installed (loaded plugs override builtin)

    return picclip.ConvertToRGB24().assumefps(fps) # Addborders done (bug in AddBorders rgb24)
}
