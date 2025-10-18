AVISource("DayCAP2.avi")
Trim(550,31142)
crop(460,200,0,0)   # Chop off waving bushes

############################################
# SecurityCamExtractMotion.AVS, v2.02, By StainlessS.
#
# Requires RT_Stats v2.0, FrameSel v1.03, GScript, Grunt, mt_tools_2. [GScript not needed if Avs+]
#
# Clip, Planar, YUY2 or RGB clip, YV411 not supported due to non support in Overlay.
#  (RGB, will likely require different thresholds)
#
# MUST SCAN STRAIGHT THROUGH, NO JUMPING ABOUT IN MotDetect.
#
# MotDetect() creates four .txt command files for KEEP frames (movement), DROP frames (not movement), DUPE frames and HOLD frames.
#  HOLD frames are combination of all KEEP frames and, DROP frames where block with greatest difference is in close proximity to previous
#  KEEP frame block with greatest difference (ie there seems to be possible movement very near previously identified movement).
# Using SelectFrames() you can select frames types of each of the 4 command files, or using the Reject mode of FrameSel, you can
# instead return the frames NOT in the command file, so using the 4 created command files, you can extract 8 variations of frame types
# after a single detection scan.
#
############################################
Th      = 6.0         # Greater or equal KEEP (movement), below is DROP(or DUPE, or possibly HOLD).
                      # Need check against source, block size and almost all other settings.
#
dTH     = 4.0         # Below or equal is DUPE, 0.0 <= dTh < Th (above dTh and below Th is DROP [or possibly HOLD]).
#
BLKW    = 64          # Suggest about 16 -> 64 (even only, mod 4 else probably slower). Metrics will change with block size.
BLKH    = BLKW        # Localized movement, adjust for smallest size of moving objects to detect, makes only little difference to speed,
                      # bigger, may be a bit faster.
                      # For human target, suggest box encompassing head + shoulders of most distant human.
                      # RT_FrameMovement returns greatest average pixel difference for any one of the blocks.
                      # Block searches may be overlapped by up to half a block both horizontally and vertically and so total x,y,w,h area
                      # of each pair of frames is compared up to about 4 times due to the half block overlaps.

#
X =  16               # Area Of Interest, avoid eg passing traffic or timecode (or could use eg Overlay to blot out stuff for dclip).
Y =  16               # Suggest cut out eg sky unless looking for flying saucers (less to search, faster).
W = -16               # As for Crop. Best MOD 4 only
H = -16
#
CW = 0.0              # ChromaWeight, 0.0->1.0. 0.0 = Luma ONLY, about 0.1 suggested for color (luma ONLY faster for YUV).
                      # For RGB, Matrix used where CW==0.0 to convert to Luma-Y. If CW != 0.0, then returns average pixel differences,
                      #  (apdR+apdG+apdB)/3.0.
                      # Perhaps always CW=0.0 [luma only] for YUV night captures.
                      # Can convert RGB to YUV for Luma-Y detect and SelectFrames() using original RGB, if required.
#
AltScan=false         # If True, Scan only every other raster line starting from Y (maybe faster, especially YUV Luma scan only).
#
ChromaI=False         # If True, YV12 chroma is interlaced (ignored if not YV12 or if Luma ONLY scan [CW==0.0]).
#
Matrix=(Width>1100||Height>600)?3:2     # Matrix used for RGB conversion to Luma-Y.
                                        # Default, If (Width>1100 || Height>600) then 3(PC.709), else 2(PC.601). (0=Rec.601, 1=Rec.709)
                                        # NOTE, default PClevels conversions will likely require different thresholds to YUV because of the
                                        # greater differences in Y (after RGB-Luma-Y conversion), probably about (255.0/219.0) times greater.
#
OLapX= BlkW/2         # X Block Overlap. 0->BLKW/2 (bigger more accurate, slower)
OLapY= BlkH/2         # Y Block Overlap. 0->BLKH/2
                      #   Where YUV, CW==0.0 and AltScan==True, might try eg OLapY=(BlkH/2)-1, where would be faster due to AltScan and,
                      #   also in overlapped 'Y_Block' scan will then scan alternate scanlines that were not scanned in previous non overlapped
                      #   scan (if that makes any sense, ie even scanlines sampled in first block, odd lines sampled in overlapped block scan).

LAG  = 1              # Lag (default 1, ie no lag. 1 or more). Compares current frame n with frame n-Lag. Detection is always
                      # initially compared(n,n-1), if neither DUPE nor KEEP detected and Lag>1, then will redetect using comparison(n,n-Lag)
                      # where n-lag frame is limited to no earlier than the most recent KEEP frame.
                      # A moderate Lag (up to about 50 or so), may be more sensitive to very small amount of movement,
                      # it introduces a time delay between compared frames. There is no upper limit to Lag arg.
                      # NOTE, Lag > 1 will likely produce more KEEP and HOLD frames (ie identify more movement), and also a bit slower
                      # due to 2nd detection scan where initial scan identified DROP frame (ie DROP may be converted to KEEP or HOLD).
                      # Lag will not make any huge difference to results, small amount of movement at beginning of sequence of movements may be
                      # detected, use lag > 1 only where every possible movement frame is required.

SHOWDCLIP=false        # If True, then shows DClip in MotDetect rather than source clip (Only useful if dclip pre-processed in some fashion)
#
dclip=Last            # Detection clip.
                      # Or some kind of denoise or whatever, used for detection (visible in ShowMetrics if SHOWDCLIp==True).
                      # Use SPATIAL denoise ONLY.
#dclip=dclip.MaxContrast(Samples=64,Gamma=1.0).VagueDenoiser(threshold=0.8,method=1,nsteps=6,chromaT=0,interlaced=false) # SLOWISH
#dclip=dclip.MaxContrast(Samples=64,Gamma=1.0).hqdn3d(2.0, 0.0,0.0,0.0,0) # A bit FASTER

###
### Show Metrics ONLY
DIM=False             # Dim/darken area outside of the x,y,w,h search area. A little faster with Dim==False when showing metrics only.
SHOWMISS  =true       # Show block 'Marker' for greatest moving DROP block (miss), (markers never shown for dupes).
MISSCOLOR =$AAFF00    # Color, block 'Marker' for  greatest DROP block (when SHOWMISS==True).
HITCOLOR  =$FFFF44    # Color, block 'Marker' for  greatest KEEP block (hit).
HOLDCOLOR =$FF8800    # Color, block 'Marker' for  HOLD block (Miss converted to HIT due to Miss proximity to previous Hit).
VERBOSE=True          # Show additional metrics, Th, dTh, BLK Args
###
### Frame Extraction ONLY
SHOW    =True         # Show FrameSel() Info on frame when extracting frames (ie shows '66] Using 12345').
SHOWTIME=True         # Show original clip Time on Frame.
#
#                     # Name of command frames file returned By AutoGetFrames and SelectFrames. (Keep.Txt, Drop.txt, Dupe.txt, Hold.txt)
#ReturnFN="Keep.Txt"
ReturnFN="Hold.Txt"
#ReturnFN="Drop.Txt"
#ReturnFN="Dupe.Txt"
#
REJECT  = False       # If True, then return frames NOT in RetunFN rather than frames in ReturnFN.
###

##########################################
# Choose 1 of below options:- (uncomment)
##########################################

 # Show metrics (Multi-Instance capable) to get best Threshold 'th' (will create valid frames files if playing straight through).
MotDetect(Last,Th,dTH,BLKW,BLKH,X,Y,W,H,CW,AltScan,ChromaI,Matrix,OLapX,OLapY,LAG,dclip,Dim,SHOWMISS,MISSCOLOR,HITCOLOR,HOLDCOLOR,SHOWDCLIP,VERBOSE)

 # Make Frames Cmd files for SelectFrames(), Must Play all way through (no metrics shown ie faster).
#MotDetect(Last,Th,dTH,BLKW,BLKH,X,Y,W,H,CW,AltScan,ChromaI,Matrix,OLapX,OLapY,LAG,dclip,Hide=True)

 # Make Frames command files and then extract ReturnFN frames (Keep.txt default) automatically in 1 pass (Auto scans entire file before display).
 # Fastest possible scanning, faster than eg VDub video analysis pass as no video shown at all during scan, Speed FPS result shown via DebugView.
#AutoGetFrames(Last,Th,dTh,BlkW,BLKH,X,Y,W,H,CW,AltScan,ChromaI,Matrix,OlapX,OlapY,Lag,dclip,show=SHOW,showTime=SHOWTIME,ReturnFN=ReturnFN,Reject=REJECT)

 # Return Frames using EXISTING ReturnFN frames Command file (after making ReturnFN using one of above options)
#SelectFrames(Last,ReturnFN,show=SHOW,showTime=SHOWTIME,reject=REJECT)

#AssumeFPS(250.0)
return Last
##########################################
##########################################
##########################################

Function MotDetect(clip c,float th,Float "dth", int "BlkW",int "BlkH",int "X",int "Y",int "W",int "H",
    \ Float "CW",Bool "AltScan",Bool "ChromaI",int "Matrix",int "OLapX",int "OLapY",Int "Lag",
    \ clip "dclip",bool "dim",Bool "ShowMiss",int "MissColor",int "HitColor",int "HoldCOLOR",bool "ShowDClip",bool "Verbose",
    \ String "KeepFN",String "DropFN",String "DupeFN",String "HoldFN",
    \ bool "Hide") {
    myName="MotDetect: "
    IsAvsPlus=(FindStr(UCase(versionString),"AVISYNTH+")!=0) HasGScript=RT_FunctionExist("GScript")
    Assert(RT_FunctionExist("GScriptClip"),myName+"Essential GRunT installed, http://forum.doom9.org/showthread.php?t=139337")
    Assert(IsAvsPlus||HasGScript,myName+"Essential GScript installed, http://forum.doom9.org/showthread.php?t=147846")
    Assert(RT_FunctionExist("RT_FrameMovement"),myName+"Essential RT_Stats v2.0 installed, http://forum.doom9.org/showthread.php?t=165479")
    dth=Float(Default(dth,0.001))
    BlkW=Default(BlkW,64)                   BlkH=Default(BlkH,BlkW)
    X=default(X,0)                          Y=default(Y,0)                       W=default(W,0)                     H=default(H,0)
    CW=Default(CW,1.0/3.0)                  AltScan=Default(AltScan,false)       CI=Default(ChromaI,false)
    Lag=Default(Lag,1)
    dclip=Default(dclip,c)
    ShowMiss=Default(ShowMiss,true)         MissColor=Default(MissColor,$AAFF00)
    HitColor=Default(HitColor,$FFFF44)       HoldColor=Default(HoldColor,$FF8800)
    ShowDClip=Default(ShowDClip,false)
    Verbose=Default(Verbose,true)
    c=(ShowDClip)?dclip:c
    Hide=Default(Hide,false)
    Dim=(!Hide)?Default(dim,true):False
    KeepFN=Default(KeepFN,"Keep.Txt")   DropFN=Default(DropFN,"Drop.Txt")
    DupeFN=Default(DupeFN,"Dupe.Txt")   HoldFN=Default(HoldFN,"Hold.Txt")

    c
    Matrix=Default(Matrix,Width>1100||Height>600?3:2)                            OLapX=Default(OLapX,BlkW/2)        OLapY=Default(OLapY,BlkH/2)
    Assert(CW>=0 && CW<=1.0,RT_String("%s0.0 <= CW <= 1.0",myName))
    Assert(Width==dclip.Width&&Height==dclip.Height&&FrameCount==dclip.FrameCount, RT_String("%sDissimilar detection clip",myName))
    Assert(dTh>=0.0 && dTh<Th && Th<=255.0,RT_String("%s0.0 <= dTh < Th <= 255.0",myName))
    Assert(Lag>=1, RT_String("%sLag Must be 1 or more",myName))
	W = (W > 0) ? (W + X) - Width  : W	   H = (H > 0) ? (H + Y) - Height : H    # Make -ve relative width,height
    X = (X+3) / 4 * 4                      Y = (Y+3)  / 4 * 4                    # Round UP  (inwards) Mod 4
    W = (W-3) / 4 * 4                      H = (H-3)  / 4 * 4                    # Round DOWN(inwards) Mod 4
	W = Width - X + W				       H = Height - Y + H                    # +ve width,height
    Cropped=Crop(X,Y,W,H)                   BlkW=Min(Cropped.Width,BlkW)            BlkH=Min(Cropped.Height,BlkH)
    (Dim && (W!=Width || H!=Height)) ? levels(0,1.0,255,0,128).Overlay(Cropped,x=X,y=Y,opacity=1.0) : Last
    (Exist(KeepFN)) ? RT_FileDelete(KeepFN) : NOP
    (Exist(DropFN)) ? RT_FileDelete(DropFN) : NOP
    (Exist(DupeFN)) ? RT_FileDelete(DupeFN) : NOP
    (Exist(HoldFN)) ? RT_FileDelete(HoldFN) : NOP
    MissMsk = Hit_Marker(BlkW,BlkH,false)
    HitMsk  = Hit_Marker(BlkW,BlkH,true)
    HoldMsk = Hit_Marker(BlkW,BlkH,true)

    MissMrk = MissMsk.BlankClip(Color=MissColor,pixel_type="YV12")
    HitMrk  = HitMsk.BlankClip(Color=HitColor,pixel_type="YV12")
    HoldMrk = HoldMsk.BlankClip(Color=HoldColor,pixel_type="YV12")

    OutCS=IsRGB24?"RGB24":IsRGB32?"RGB32":IsYUY2?"YUY2":IsYV12?"YV12":VersionNumber<2.6?"UNK"
        \ :IsY8?"Y8":IsYV16?"YV16":IsYV24?"YV24":IsYV411?"YV411":"UNK"   # YV411 not actually supported by Overlay output.
    Fmt=
        \ "%d ] %s{%c} BlkMaxDif=%7.3f\n"     +
        \ "LAG=%-13d  : CompFrm=%d\n"            +
        \ "KEEP=%-6d %5.2f%% : MinKeep=%.3f\n"  +
        \ "DROP=%-6d %5.2f%% : MaxDrop=%.3f\n"  +
        \ "DUPE=%-6d %5.2f%% : MaxDupe=%.3f\n"  +
        \ "HOLD=%-6d %5.2f%% : LastKFrm=%d"
    vFmt="nBlks=%d : BlkAveDif=%.3f\n" +
    \ "nAboveTh=%2d (%.2f%%)\n" +
    \ "Th=%.2f DTh=%.3f : CW=%.3f\nAlt=%c : Blk=%dx%d : OLap=%dx%d"

    FuncS="""
        Function Fn@@@(clip clp,Float th,Float dth,int BlkW,int BlkH,int x,int y,int w,int h,
                \ Float CW,bool AltScan,bool CI,int Matrix,int OLapX,int OLapY,Int Lag,
                \ clip dclip,bool ShowMiss,clip MissMrk,clip HitMrk,clip HoldMrk,clip MissMsk,clip HitMsk,clip HoldMsk,bool Verbose,
                \ String Fmt,String vFmt,String Prefix,string OutCS,
                \ String KeepFN,String DropFN,String DupeFN,String HoldFN,
                \ bool Hide) {
            clp
            n=current_frame
            if(PrevN@@@ != n) {
                # Always check against n-1 for DROP and KEEP
                cmp = n-1
                if(PrevN@@@!=cmp) {                                                             # Reset (jump about or frame 0)
                    cmp = max(n-1,0)
                    Global RecentKeep@@@=cmp                                                    # Most recent KEEP frame number
                    Global PrevMat@@@=1                                                         # Prev vist match type DROP
                    Global CurrXOff@@@=-6666                                                    # Invalid Coords of current KEEP or HOLD
                    Global HoldXOff@@@=-6666                                                    # Invalid Coords of Most recent KEEP or HOLD
                }
                dif=RT_FrameMovement(dclip,dclip,n,cmp,CW,x,y,w,h,x,y,altscan,CI,Matrix,BlkW,BlkH,OLapX,OLApY,Th,Prefix)
                mat=(dif>dth) ? (dif<th?1:2) : (n==0) ? 2 : 0   # 0=DUPE : 1=DROP : 2=KEEP : 3=HOLD(Not used here)

                if(Lag>1 && mat==1 && cmp-RecentKeep@@@>=1) {
                    # If DROP will be converted to HOLD, then dont compare LAG frame
                    if(MOTD_XOff<HoldXOff@@@-BlkW || MOTD_XOff>HoldXOff@@@+BlkW || MOTD_YOff<HoldYOff@@@-BlkH || MOTD_YOff>HoldYOff@@@+BlkH) {
                        # Limit RecentKeep@@@ usage to inital lag,
                        # avoid small remnants of objects moving out of frame from being used in later compare
                        cmp = (n-RecentKeep@@@==2) ? RecentKeep@@@ : max(RecentKeep@@@+1,n-Lag)
                        dif=RT_FrameMovement(dclip,dclip,n,cmp,CW,x,y,w,h,x,y,altscan,CI,Matrix,BlkW,BlkH,OLapX,OLApY,Th,Prefix)
                        mat=(dif>dth) ? (dif<th?1:2) : 0
                    }
                }

                if(mat==0) {        # Dupe
                    (DupeFN!="") ? RT_WriteFile(DupeFN,"%d",n,append=true) : NOP
                } else if(mat==1) { # Drop
                    if(HoldXOff@@@ >= 0) {    # HOLD Disabled ? (will quite often be disabled)
                        if(   MOTD_XOff>=HoldXOff@@@-BlkW && MOTD_XOff<=HoldXOff@@@+BlkW &&
                            \ MOTD_YOff>=HoldYOff@@@-BlkH && MOTD_YOff<=HoldYOff@@@+BlkH) {
                            mat=3 # Convert to HOLD
                            (HoldFN!="") ? RT_WriteFile(HoldFN,"%d",n,append=true) : NOP
                        } else { # Wandered too far from most recent hold coords, Disable HOLD locking
                            Global HoldXOff@@@ = -6666
                        }
                    }
                    (DropFN!="") ? RT_WriteFile(DropFN,"%d",n,append=true) : NOP
                    Global PrevMat@@@ = 1
                } else {         # Keep
                    if(n!=0 || PrevN@@@==-6666) {   # Block nasty VDub Analysis pass writing 0 on re-seek to 0 at end
                        (KeepFN!="") ? RT_WriteFile(KeepFN,"%d",n,append=true) : NOP
                        (HoldFN!="") ? RT_WriteFile(HoldFN,"%d",n,append=true) : NOP
                    }
                    Global PrevMat@@@    = 2
                    Global RecentKeep@@@ = n
                    Global HoldXOff@@@   = MOTD_XOff        # From Locals set by RT_FrameMovement()
                    Global HoldYOff@@@   = MOTD_YOff
                }

                if(!Hide) {
                    Global CmpFrm@@@            = cmp
                    Global Mat@@@               = mat
                    Global Dif@@@               = dif
                    Global CurrXOff@@@          = MOTD_XOff
                    Global CurrYOff@@@          = MOTD_YOff
                    if(mat==0) {
                        Global nDupe@@@         = nDupe@@@ + 1
                        Global DupeMax@@@       = max(dif,DupeMax@@@)
                    } else if(mat==1) {
                        Global nDrop@@@         = nDrop@@@ + 1
                        Global KeepMin@@@       = 255.0
                        Global DropMax@@@       = max(dif,DropMax@@@)
                    } else if(mat==2) {
                        Global nKeep@@@         = nKeep@@@ + 1
                        Global KeepMin@@@       = min(dif,KeepMin@@@)
                        Global DropMax@@@       = 0.0
                        Global nHold@@@         = nHold@@@ + 1
                    } else {
                        Global nHold@@@         = nHold@@@ + 1
                    }
                    if(VerBose) {
                        Global TotalBlks@@@     = MOTD_TotalBlks
                        Global BlkAveDf@@@      = MOTD_BlkAveDf
                        Global nAboveTh@@@      = MOTD_nAboveTh
                        Global PercAboveTh@@@   = MOTD_PercAboveTh
                    }
                }
            }

            if(!Hide) {
                mat = Mat@@@
                z=RT_Ord("-123",mat+1)
                RT_SubTitle(Fmt,n,(mat==0)?"DUPE":(mat==1)?"DROP":(mat==2)?"KEEP":"HOLD",
                    \ z,Dif@@@,max(n-CmpFrm@@@,0),CmpFrm@@@,
                    \ nKeep@@@, nKeep@@@*100.0 / (n+1.0),KeepMin@@@,
                    \ nDrop@@@, nDrop@@@*100.0 / (n+1.0),DropMax@@@,
                    \ nDupe@@@, nDupe@@@*100.0 / (n+1.0),DupeMax@@@,
                    \ nHold@@@, nHold@@@*100.0 / (n+1.0),RecentKeep@@@
                    \ )
                Verbose ? RT_Subtitle(vFmt,TotalBlks@@@,BlkAveDf@@@,nAboveTh@@@,PercAboveTh@@@,th,dth,CW,(altScan)?84:70,BlkW,BlkH,OLapX,OLapY,Align=1) : NOP
                if((mat>0 && (mat!=1||ShowMiss)) && n>0) {
                    Overlay(mat==1?MissMrk:mat==2?HitMrk:HoldMrk,x=x+CurrXOff@@@,y=y+CurrYOff@@@,
                        \ Mask=mat==1?MissMsk:mat==2?HitMsk:HoldMsk,Mode="Blend",output=OutCS)
                }
            }
            Global PrevN@@@ = n
            return Last
        }
        #######################################
        # Unique Global Variables Initialization
        #######################################
        Global PrevN@@@=-6666                                                                   # Previously visited Frame Number
        Global RecentKeep@@@=0                                                                  # Most recent KEEP frame number
        Global PrevMat@@@=1                                                                     # Prev vist match type (1,2,only, not DUPE)
        Global HoldXOff@@@=-6666                                                                # Coords of Most recent KEEP or HOLD
        Global HoldYOff@@@=-6666
        # Required for Metrics ONLY
        Global CmpFrm@@@=0                                                                      # Current comparison frame for decision
        Global Mat@@@=0                                                                         # Current visit Match type
        Global Dif@@@=0.0                                                                       # Current visit dif
        Global TotalBlks@@@=0
        Global BlkAveDf@@@=0.0
        Global nAboveTh@@@=0
        Global PercAboveTh@@@=0.0
        Global CurrXOff@@@=-6666                                                                # Current Coords
        Global CurrYOff@@@=-6666
        Global nKeep@@@=0       Global nDrop@@@=0       Global nDupe@@@=0    Global nHold@@@=0  # Counts
        Global KeepMin@@@=0.0   Global DropMax@@@=0.0   Global DupeMax@@@=0.0                   # Dif limits
        Prefix="MOTD_"
        #######################################
        # Unique Runtime Call, GScriptClip must be a one-liner:
        #######################################
        ARGS = "th,dth,BlkW,BlkH,x,y,w,h,CW,AltScan,CI,Matrix,OLapX,OLapY,Lag," +
            \  "dclip,ShowMiss,MissMrk,HitMrk,HoldMrk,MissMsk,HitMsk,HoldMsk,Verbose,Fmt,vFmt,Prefix,OutCS," +
            \  "KeepFN,DropFN,DupeFN,HoldFN,Hide"
        Last.GScriptClip("Fn@@@(last, "+ARGS+")", local=true, args=ARGS)
    """
    #######################################
    # Unique Identifier Definition
    #######################################
    GIFunc ="MOTD"                                  # Function Name, Supply unique name for your multi-instance function.
    GIName =GIFunc+"_InstanceNumber"                # Name of the Instance number Global
    RT_IncrGlobal(GIName)                           # Increment Instance Global (init to 1 if not already exists)
    GID = GIFunc + "_" + String(Eval(GIName))
    InstS = RT_StrReplace(FuncS,"@@@","_"+GID)
#   RT_WriteFile("DEBUG_"+GID+".TXT","%s",InstS)    # Resulting Instance script, for debug perusal.
    IsAvsPlus?Eval(InstS):HasGScript?GScript(InstS):Assert(False,RT_String("%sNeed either GScript or AVS+",myName))
    Return KillAudio
}


Function Hit_Marker(int W, Int H, Bool "Hit", Int "BW", Int "BH",Int "PW",Int "PH",Bool "YV12",Bool "Mod2") {
/*
    Req RT_Stats & mt_tools v2.     http://forum.doom9.org/showthread.php?t=174527
    Creates a marker mask WxH, for use with Overlay as Mask arg.
    Intended for use via some kind of detector to show detection Hit, or Miss.
    Returns Single frame clip with null audio, the marker top left hand side is aligned to 0,0.
            Default return clip colorspace is Y8 for Avisynth v2.6 and above, or YV12 if defunct version.
    Args:-
        W,H,    Size of marker mask (can be odd), return clip dimensions are rounded up to next multiple of 2 if YV12 return clip.
                  Bare minimum usable size is 4x4 with defaulted BW, BH, PW, PH.
        HIT,    Default False, returns marker as angled corners (Thickness set by BW and BH).
                        True,  returns marker as angled corners + outer perimeter where perimeter thickness set by PW and PH.
        BW,     Default Max(W/8,1). Horizontal thickness of the marker corners.
        BH,     Default Max(H/8,1). Vertical   thickness of the marker corners.
        PW,     Default Max(BW/8,1). Horizontal thickness of the vertical perimeter.
        PH,     Default Max(BH/8,1). Vertical thickness of the horizontal perimeter.
        YV12,   Default False if Avisynth version 2.6 or greater(Y8), else true(YV12). Selects return clip colorspace.
        Mod2,   Default True. If Y8 then round odd dimensions up modulo 2 (the mask is still WxH).

    Example:-
        Import("Hit_Marker.avs")
        WW=128  HH=WW   HIT=True
        BlankClip
        Yell=Last.BlankClip(Width=WW,Height=HH,Length=1,Color=$FFFF00)
        Return OverLay(Yell,x=(Width-WW)/2,y=(Height-HH)/2,mask=Hit_Marker(WW,HH,HIT))
*/
    Hit=Default(hit,False)                    BW=Max(Default(BW,W/8),1)   BH=Max(Default(BH,H/8),1)
    BW2=(W>4)?BW*2:BW                         BH2=(H>4)?BH*2:BH
    PW=Max(Default(PW,BW/8),1)                PH=Max(Default(PH,BH/8),1)  is26 = VersionNumber>=2.6
    YV12=(!is26) ? True : Default(YV12,False) Mod2=Default(Mod2,True)     Mod = (YV12||Mod2) ? 2 : 1
    CanvasW=(W+Mod-1)/Mod*Mod                 CanvasH=(H+Mod-1)/Mod*Mod
    Rpn= RT_String("x %d < x %d >= | y %d < | y %d >= | x %d < x %d >= | & y %d < y %d >= | & ",BW,W-BW,BH,H-BH,BW2,W-BW2,BH2,H-BH2)
    Rpn= (Hit) ? Rpn + RT_String("x %d < x %d >= | y %d < | y %d >= | | ",PW,W-PW,PH,H-PH) : Rpn
    Rpn= Rpn + RT_String("x %d < y %d < & & 255 0 ?",W,H)
    Blankclip(width=CanvasW,height=CanvasH,Length=1,pixel_type=YV12?"YV12":"Y8").Killaudio
    return mt_lutspa(relative = false,yExpr=Rpn, chroma = "-128")
}


Function MaxContrast(clip c,int "Samples",Float "Ignore",Float "Gamma",Bool "Show") {   # PC Levels Max Contrast
    c       Gamma=Float(Default(Gamma,1.0))     Show=Default(Show,False)
    Eval(RT_QueryLumaMinMax(Samples=Samples,Ignore=Ignore,X=4,Y=4,W=-4,H=-4,Debug=Show))
    Doit = (QLMMMin!=0 || QLMMMax != 255)
    RT_DebugF("Levels(%3d,%.2f,%3d,%d,%d,Coring=False)",QLMMMin,Gamma,QLMMMax,0,255,name="MaxContrast: ")
    (Doit && Show) ? RT_Subtitle("%sLevels(%3d,%.2f,%3d,%d,%d,Coring=False)","MaxContrast: ",QLMMMin,Gamma,QLMMMax,0,255)  : NOP
    (Doit) ? Levels(QLMMMin,Gamma,QLMMMax,0,255,Coring=False) : NOP
    Return Last
}

Function SelectFrames(clip c,String Fn,bool "Show",bool "Showtime",bool "Reject") {
    c   Show=Default(Show,False)    ShowTime=Default(ShowTime,False) Reject=Default(Reject,False)
    (ShowTime) ? ShowTime() : NOP   FrameSel(CMD=Fn,show=Show,reject=Reject)            # Returns NO audio
}

Function AutoGetFrames(clip c,float th,Float "dth", int "BlkW",int "BlkH",int "X",int "Y",int "W",int "H",
    \ Float "CW",Bool "AltScan",Bool "ChromaI",int "Matrix",int "OLapX",int "OLapY", Int "Lag",
    \ clip "dclip",String "KeepFN",String "DropFN",String "DupeFN",String "HoldFN",
    \ bool "Show",Bool "Showtime",String "ReturnFN",Bool "Reject"
    \ ) {
    Default(dclip,c)                            # Use detection clip (denoised or whatever) for making frames command files.
    KeepFN   = Default(KeepFN,"Keep.txt")       # Filename for Keep Frames
    ReturnFN = Default(ReturnFN,KeepFN)         # Use ReturnFN if given else KeepFN
    Reject   = Default(Reject,False)
    START = RT_TimerHP()
    # Make the command file for FrameSel()
    MotDetect(Last,th,dth,BlkW,BlkH,X,Y,W,H,CW,AltScan,ChromaI,Matrix,OLapX,OLapY,Lag,Last,
        \ KeepFN=KeepFN,DropFN=DropFN,DupeFN=DupeFN,HoldFN=HoldFN,Hide=True)
    RT_ForceProcess(Debug=True)                 # Scan entire clip forcing command files to be written.
    T = RT_TimerHP() - START
    RT_DebugF("AutoGetFrames: %.2fsecs (%.2fmins) %.2fFPS",T,T/60.0,FrameCount/T)
    c.SelectFrames(ReturnFN,Show=Show,showtime=Showtime,Reject=Reject)      # Extract ReturnFN source frames and return to client
}
