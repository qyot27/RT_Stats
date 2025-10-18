Function ImageSplicer(String "FileName",int "SzLimit",Float "FAR",Bool "AutoCrop",Float "AutoLevelStrength",bool "ShowAutoLevel",bool "ShowBorder", \
        bool "Subs", Float "CropThresh",Float "FPS",int "WMod",int "HMod",int "Baffle",Float "ScanPerc", \
        bool "Debug", bool "Debug_QBC",String "Resizer",int "Matrix",float "Ignore",Int "BorderColor",float "ATM") {
##########################################
    VERS="ImageSplicer v1.11 - 17 Mar 2015"     # Requires GScript, RT_Stats v1.4
#
# ImageSplicer, joins together images of different sizes into a sort of slideshow, auto cropping borders, auto levelling, resizing or original size,
#  border padding to chosen aspect ratio.
#  Gets max width/height of all images (after optional auto cropping) and creates a background 'canvas' based on SzLimit & FAR.
#  SzLimit==0: Images kept at original dimensions (post cropping), canvas made to encompass all cropped images.
#  SzLimit>0:  The shorter canvas dimension (FAR) limited to AT MOST SzLimit, where images will be resized to fit canvas.
#    Avoids upsizing to a larger size than biggest cropped source image, if biggest less than SzLimit then output is biggest.
#  SzLimit<0:  The shorter canvas dimension (FAR) set at abs(SzLimit) and images resized to fit canvas.
#
# Args:-
#  Filename: Default "*.BMP|JPG|JPE|JPEG|PNG|TGA|TIF|GIF|TIFF". Image Path and wildcard with mulitple pipe separated extensions.
#  SzLimit: Default=0, 0=No resize. Greater than 0 is limit on shorter dimension (see FAR), -ve resize to abs(SzLimit) shorter dimension.
#  FAR: Default 4.0/3.0. Output Frame Aspect Ratio, if FAR>=1.0 then SzLimit affects height, else affects width.
#  AutoCrop: Default=True. Crops borders off images.
#  AutoLevelStrength: Default 0.0, Auto luma leveling, range 0.0 -> 1.0, 0.0 is OFF.
#  ShowAutoLevel: Default False. If true then shows Auto leveling on right hande side of image ONLY.
#  ShowBorder: Default False. When padding to maintain Frame Aspect Ratio, borders are shown in red.
#  Subs: Default False. Shows Subtitled info on frames.
#  CropThresh: Default -0.5
#    CropThresh <=0.0 is PC levels AUTO thresh where cropthresh is set to minimum luma pixel + abs(CropThresh).
#      Default is very sensitive threshold to avoid possibility of overcropping (-0.5 -> -1.0, usually safe, more -ve less safe).
#      You may raise (make more -ve) auto CropThresh if not cropping enough but risk overcropping on dark images if you do.
#    CropThresh >0.0 is explicit threshold @ PC Levels, probably best avoided.
#    RGB clips are converted to YUV-Y using Matrix arg @ PCLevels and CropThresh acting on Average Luma of scanline (h/v).
#  FPS: Default 1.0. Frames Per Second of output clip.
#  WMod: Default 2. Output clip width is a multiple of WMod.
#  HMod: Default 2. Output clip height is a multiple of HMod.
#  Baffle: Default 4 (1->32), affects cropping.
#    Number of scanlines that must break a CropThresh to be accepted as Image. Avoids noise. Not usually altered.
#    Baffle also affects speed, higher can be faster for big borders but also means that more scanlines must break threshold to be accepted as image.
#  ScanPerc: Default 49.0, cropping. Percentage of image to scan per side. Not usually altered.
#  Debug: Default False. Show debug info via DebugView. Need DebugView: http://technet.microsoft.com/en-gb/sysinternals/bb545027
#  Debug_QBC: Default False. Show debug messages from RT_QueryBorderCrop.
#  Resizer: Default "Spline36Resize(_W_,_H_)", the resizer to use. "_W_" and "_H_" are replaced by the resize width & height.
#  Matrix: 2->3, Default If pic width <=720 Then 2(PC601) Else 3(PC709). Used in converting RGB to YUV-Y.
#  Ignore: Default 0.2, Cropping. Percentage, Threshold of pixels to ignore when getting Luma minimum, avoids a few noisy pixels.
#    As for YPlaneMin Threshold arg.
#  BorderColor: Default $000000, Color used when ShowBorder=False.
#  ATM: Default 0.5. RT_QueryBorderCrop arg, See RT_QueryBorderCrop.
##########################################
    #

    myName="ImageSplicer:"
    IsAvsPlus=(FindStr(UCase(versionString),"AVISYNTH+")!=0)    HasGScript=RT_FunctionExist("GScript")
    Assert(IsAvsPlus || HasGScript,RT_String("%sNeed either GScript or AVS+",myName))

    FileName=Default(FileName,"*.BMP|JPG|JPE|JPEG|PNG|TGA|TIF|GIF|TIFF")
    SzLimit=Default(SzLimit,0)                                                  # 0 Crop only.
    FAR=Default(FAR,4.0/3.0)
    AutoCrop=Default(AutoCrop,True)
    AutoLevelStrength=Float(Default(AutoLevelStrength,0.0))
    ShowAutoLevel=Default(ShowAutoLevel,false)
    ShowBorder=Default(ShowBorder,false)
    Subs=Default(Subs,false)
    CropThresh=Float(Default(CropThresh,-0.5))
    FPS=Float(Default(FPS,1.0))
    WMod=Default(WMod,2)                                                        # Canvas
    HMod=Default(HMod,2)
    Baffle=Default(Baffle,4)
    ScanPerc=Float(Default(ScanPerc,49.0))
    DEBUG=Default(Debug,False)
    DEBUG_QBC=Default(Debug_QBC,False)
    Resizer=Default(Resizer,"Spline36Resize(_W_,_H_)")
    Mat=Default(Matrix,RT_Undefined())                                          # User supplied ?
    Ignore=Float(Default(Ignore,0.2))
    BorderColor=Default(BorderColor,$000000)
    ATM=Default(ATM,0.5)
    BORDER      = (SHOWBORDER) ? $FF0000: BorderColor                           # Color for replaced borders
    # Lesser changed settings Hard coded
    CROPMODE    = 0                                                             # 0=CropExact(RGB Only), 1=CropLess, 2=CropMore, 3=CropPlus
    OUT_FILE    = "ImageSplicer.List"                                           # Just a filename
    #
    Assert(WMOD>=1 && HMOD>=1,"ImageSplicer: WMOD and HMOD Must be at least 1")
    Assert(RT_BitSetCount(WMOD)==1 && RT_BitSetCount(HMOD)==1,"ImageSplicer: WMOD and HMOD Must be a power of 2")
    Assert(FAR>0.0,"ImageSplicer: FAR Must be greater than 0.0")
    Assert(SzLimit==0||(FAR>=1.0 || (abs(SzLimit)%HMOD==0)),"ImageSplicer: SzLimit is not a multiple of HMod")
    Assert(SzLimit==0||(FAR< 1.0 || (abs(SzLimit)%WMOD==0)),"ImageSplicer: SzLimit is not a multiple of WMod")
    Assert(AutoLevelStrength>=0.0 && AutoLevelStrength<=1.0,"ImageSplicer: AutoLevelStrength 0.0->1.0")
    Assert(Baffle>0 && Baffle<=32,"ImageSplicer: Baffle 1->32")
    Assert(ScanPerc>=1.0 && ScanPerc<=99.0,"ImageSplicer: ScanPerc 1.0->99.0")
    Assert(!Defined(Mat) || (Mat>=2 && Mat<=3),"ImageSplicer: Matrix 2->3 ONLY")
    Assert(Ignore>=0.0 && Ignore<=99.0,"ImageSplicer: ScanPerc 0.0->99.0")
    ATM=Min(Max(0.0,ATM),32.0)
    GS="""
        if(DEBUG){
            RT_Debug("ImageSplicer:",false)
            RT_Debug("ImageSplicer:",VERS,"- By StainlessS",false)
            RT_Debug("ImageSplicer:",false)
        }
        picclip = 0                                                             # Dummy
        result=RT_WriteFileList(FileName,OUT_FILE)                              # Create a listing FileName of Pic files
        Assert((result!=0), "ImageSplicer: No files found for "+FileName)
        FILELIST=RT_ReadTxtFromFile(OUT_FILE)                                   # Get list of files
        NFILES=RT_TxtQueryLines(FILELIST)                                       # Query Number of lines in String ie number of files.
        (DEBUG) ? RT_Debug("ImageSplicer:","Found files = " + String(NFILES),false) :NOP
        # Prescan to ascertain max wid/hit of all files, also Autocrop & Auto Levels
        MAXH=0 MAXW=0                                                           # init max wid and hit
        CROPCOORDS=""                                                           # Clear results array (string)
        AUTOLEVELS=""                                                           # Clear AutoLevels array (string)
        DOAUTOLEVEL=(AutoLevelStrength>0.0)                                     # Adjust using Levels.
        QBCTrailer=Select(CROPMODE,"=","L=","M=","P=")
        For(i=0,NFILES-1) {
            FN=RT_TxtGetLine(FILELIST,i)                                        # Filename of pic/vid file i
            (DEBUG)?RT_Debug("ImageSplicer:",String(i+1)+"/"+String(NFILES)+") Getting File dimensions",FN,false):NOP
            k=ImageReader(FN,end=0).ConvertToRGB32()                            # Ensure all RGB32
            OrgW=k.width    OrgH=k.height
            W=OrgW          H=OrgH                                              # Pre-Duplicate in case of no AUTOCROP
            Matrix=(Defined(Mat))?Mat:(W<=720)?2:3
            if (AutoCrop||DOAUTOLEVEL) {                                        # We still use QueryBorderCrop if Only AutoLevelling
                ignore=0.0
                QBC = k.RT_QueryBorderCrop(Thresh=CropThresh,Baffle=Baffle,laced=false,ScanPerc=ScanPerc,ignore=Ignore, \
                        debug=(DEBUG&&DEBUG_QBC),matrix=Matrix,ScaleAutoThreshRGB=False,ATM=ATM)    # No PC scale RGB auto thresh

                Eval(QBC)                                               # Set Avisynth vars
                k=k.Crop(QBCropXP,QBCropYP,QBCropWP,QBCropHP)           # OVERCROP using CropPlus
                if(AutoCrop) {
                    QBC = RT_TxtGetLine(QBC,CROPMODE)                   # Extract REQUIRED mode, CropLess, CropMore etc
                    QBC1=RT_StrReplace(QBC,QBCTrailer,"=")              # Change all to style without a trailer eg QBCropXM to QBCropX.
                    QBC2=RT_StrReplace(QBC1,"QBC","C")                  # Change all style QBCropX to CropX
                    Eval(QBC2)                                          # Get the required cropmode into CropX,CropY,CropW,CropH
                    W=CropW    H=CropH                                  # The actual required crop mode dimensions.
                    CROPCOORDS=RT_TxtAddStr(CROPCOORDS,QBC2)            # Avisynth Bugfix, same as CROPCOORDS = CROPCOORDS + QBC + Chr(10)
                }
                if (DOAUTOLEVEL) {
                    k.RT_YStats(n=0,matrix=Matrix,flgs=3,Prefix="IS_")  # Get ymin & ymax together at once
                    IS="IS_"+"yMin="+String(IS_yMin)+" IS_"+"yMax="+String(IS_yMax)
                    AUTOLEVELS=RT_TxtAddStr(AUTOLEVELS,IS)              # Avisynth Bugfix
                }
            }
            If(MAXW<W) {MAXW=W}
            If(MAXH<H) {MAXH=H}
            if (DEBUG) {                                                # KEEP main debug messages together
                RT_Debug("ImageSplicer:","Orig Width =",String(orgW),"Orig Height =",String(OrgH),false)
                if((W != OrgW) || (H != OrgH)) {                        # Was Caused by AUTOCROP
                    RT_Debug("ImageSplicer:","AutoCrop Width =",String(W),"AutoCrop Height =",String(H),false)
                    (DOAUTOLEVEL) ? RT_Debug("ImageSplicer:","AutoLevel On Cropped : MinLuma=",String(IS_yMin)," MaxLuma =",String(IS_yMax),false) : NOP
                } else {
                    (AutoCrop) ? RT_Debug("ImageSplicer:","AutoCrop Found no borders",false) : NOP
                    (DOAUTOLEVEL)? RT_Debug("ImageSplicer:","AutoLevel NonCropped : MinLuma=",String(IS_yMin)," MaxLuma =",String(IS_yMax),false) : NOP
                }
                RT_Debug("ImageSplicer:","MAX Width So Far =",String(MAXW),"MAX Height So Far =",String(MAXH),false)
                RT_Debug("ImageSplicer:"," ----------------------------- ",false)              # line separator
            }
        }
        maxFAR = Float(MAXW) / MAXH
        if(SzLimit == 0) {  # NO SIZE LIMITING, Pad Only
            if(FAR >= maxFAR) { # Need to pad horizontal
                canvasheight    = Int((MAXH  + (HMOD-1)) / HMOD) * HMOD
                canvaswidth     = Int((canvasheight * FAR + (WMOD-1)) / WMOD) * WMOD
            } else {            # Need to pad vertical
                canvaswidth     = Int((MAXW  + (WMOD-1)) / WMOD) * WMOD
                canvasheight    = Int((canvaswidth / FAR + (HMOD-1)) / HMOD) * HMOD
            }
            SZS="Crop-Only"
        } else if(SzLimit<0) {
            if(FAR>=1.0) {  # Height Resize
                canvasheight    = -SzLimit
                canvaswidth     = Int((canvasheight * FAR + (WMOD/2)) / WMOD) * WMOD
                SZS="Height-Resize"
            } else {        # Width Resize
                canvaswidth     = -SzLimit
                canvasheight    = Int((canvaswidth / FAR + (HMOD/2)) / HMOD) * HMOD
                SZS="Width-Resize"
            }
        } else {
            if(FAR>=1.0) {  # Height Limit
                SZS="NOT-Height-Limited-Resize"
                canvasheight = Int((MAXH  + (HMOD-1)) / HMOD) * HMOD
                if(canvasheight > SzLimit) {
                    canvasheight = SzLimit
                    SZS="Height-Limited-Resize"
                }
                canvaswidth     = Int((canvasheight * FAR + (WMOD/2)) / WMOD) * WMOD
            } else {        # Width Limit
                SZS="NOT-Width-Limited-Resize"
                canvaswidth = Int((MAXW  + (WMOD-1)) / WMOD) * WMOD
                if(canvaswidth > SzLimit) {
                    canvaswidth = SzLimit
                    SZS="Width-Limited-Resize"
                }
                canvasheight    = Int((canvaswidth / FAR + (HMOD/2)) / HMOD) * HMOD
            }
        }
        if(DEBUG){RT_Debug("ImageSplicer:","SET CANVAS "+SZS+", Width =",String(canvaswidth)," Height =",String(canvasheight),false)}
        if(DEBUG){RT_Debug("ImageSplicer:"," ----------------------------- ",false)}         # line separator
        For(i=0,NFILES-1) {
            FN=RT_TxtGetLine(FILELIST,i)         # Filename of pic/vid file i
            if(DEBUG){RT_Debug("ImageSplicer:",string(i+1)+"/"+String(NFILES)+")","Processing File",FN,false)}
            k=ImageReader(FN,end=0).ConvertToRGB32()                           # RGB24 problems with addborders
            OrgH=k.height    OrgW=k.width
            CropX=0 CropY=0 CropW=OrgW CropH=OrgH
            if (AutoCrop) {                                                             # We must crop first so as to centre if show AUTOLEVEL
                QBC = RT_TxtGetLine(CROPCOORDS,i)                                   # Get required coords from first pass
                Eval(QBC)                                                           # Set variables in Avisynth, ie CropX etc
            }
            if (DOAUTOLEVEL) {
                ISAL = RT_TxtGetLine(AUTOLEVELS,i)
                Eval(ISAL)
                TMP_K=k
                ALMin = Int(0 - ((0 - IS_yMin) * AutoLevelStrength) + 0.5) # Round Up
                ALMax = Int(255 - ((255 - IS_yMax) * AutoLevelStrength))       # Round down
                (DEBUG) ? RT_Debug("ImageSplicer:","Levels("+String(ALMin)+",1.0,"+String(AlMax)+",0,255"+",Coring=False)",false) : NOP
                k = k.Levels(ALMin,1.0,ALMax,0,255,Coring=False)              # DONT EVER USE Coring
                if(ShowAutoLevel) {
                    tmpw=CropX+(CropW/2)
                    LeftClip = TMP_K.Crop(0,0,tmpw,-0)
                    RightClip= k.Crop(tmpw,0,-0,-0)
                    k=StackHorizontal(LeftClip,RightClip)
                }
            }
            if(SzLimit==0) {
                Left    =   (canvaswidth-CropW) / 2
                Right   =   canvaswidth-CropW - Left
                Top     =   (canvasheight-CropH) / 2
                Bot     =   canvasheight-CropH-Top
                rwid    =   CropW   rhit    =   CropH
            } else {
                cFAR    = Float(canvaswidth) / canvasheight
                iFar    = Float(CropW) / CropH
                if(cFAR >= iFAR) {  # Canvas Aspect ratio greater (wider), resize to vertical and pad horizontal
                    rhit    =   canvasheight
                    rwid    =   Int(rhit*iFAR/WMOD)*WMOD
                    Left    =   (canvaswidth-rwid) / 2
                    Right   =   canvaswidth - rwid - Left
                    Top     =0  Bot = 0
                } else {            # Canvas Aspect ratio smaller (taller), resize to horizontal and pad vertical
                    rwid    =   canvaswidth
                    rhit    =   Int(rwid/iFAR/HMOD)*HMOD
                    Top     =   (canvasheight-rhit) / 2
                    Bot     =   canvasheight - rhit - Top
                    Left    =0  Right=0
                }
            }
            (DEBUG)? RT_Debug("ImageSplicer:","Crop("+String(CropX)+","+String(CropY)+","+String(CropW)+","+String(CropH)+")",false) : NOP
            k=k.Crop(CropX,CropY,CropW,CropH)
            if(SzLimit!=0) {
                if(k.width != rwid || k.height != rhit) {
                    Resizer_Cmd = RT_StrReplaceMulti(Resizer,RT_TxtAddStr("_W_","_H_"),RT_TxtAddStr(String(rwid),String(rhit)))
                    (DEBUG)?RT_Debug("ImageSplicer:",Resizer_Cmd,false):NOP
                    Eval("k=k."+Resizer_Cmd)
                } else {
                    (DEBUG)?RT_Debug("ImageSplicer: No Resize Necessary",false):NOP
                }
            }
            (DEBUG) ? RT_Debug("ImageSplicer:","AddBorders("+String(Left)+","+String(Top)+","+String(Right)+","+String(Bot)+")",false) : NOP
            k = k.Addborders(Left,Top,Right,Bot,BORDER)
            k = k.assumefps(fps)
            if(SUBS) {
                k=k.subtitle(String(i+1) + "/"+String(NFILES) +" " + FN)
                k=k.subtitle("Orig width=" + string(orgW) +" "   + "Orig  height=" + string(orgH) +" FAR="+String(Float(orgW) /orgH, "%.2f"),20,20)
                if (AutoCrop) {
                    if(OrgW!=CropW || OrgH!=CropH) {
                        k=k.subtitle("Crop width="+string(CropW)+" "+"Crop height="+string(CropH)+" FAR="+String(Float(CropW)/CropH,"%.2f"),20,40)
                    } else {
                        k=k.subtitle("NO CROP FOUND",20,40)
                    }
                } else {k=k.subtitle("AUTOCROP OFF",20,40)}
                k=k.subtitle("Resize width=" + string(rwid) +" " + "Resize height=" + string(rhit)+" FAR="+String(Float(rwid)/rhit,"%.2f"),20,60)
                k=k.subtitle("Out width=" + string(k.Width) +" " + "Out height=" + string(k.Height)+" FAR="+String(Float(k.Width)/k.Height,"%.2f"),20,80)
                if(DOAUTOLEVEL) {
                    k=k.subtitle("AutoLevel @ " + String(AutoLevelStrength*100.0,"%.0f") + "%",20,100)
                    k=k.subtitle("yMin = " + String(IS_yMin) + " yMax = " +String(IS_yMax),20,120)
                    if(IS_yMin==0 && IS_yMax==255) {
                        k=k.subtitle("NOT AUTOLEVELLED",20,140)
                    } else {
                        k=k.subtitle("Auto Levels(" + String(ALMin) + ",1.0," + String(ALMAx) + ",0,255)",20,140)
                    }
                } else {k=k.subtitle("NO AUTOLEVEL",20,100)}
            }
            picclip = (IsClip(picclip)) ? picclip ++ k : k              # Append to  clip so far
            k=k.ConvertToRGB24()
            if(DEBUG){
                RT_Debug("ImageSplicer:",false)
                RT_Debug("ImageSplicer:"," ----------------------------- ",false)
            }
        }
    """

    HasGScript ? GScript(GS) : Eval(GS) # Use GSCript if installed (loaded plugs override builtin)

    (DEBUG)?RT_Debug("ImageSplicer:","File Delete",OUT_FILE,false):NOP
    RT_FileDelete(OUT_FILE)
    return PicClip
}
