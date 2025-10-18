#RT_YInRAngeLocate() Tester

# NOTE, Angle corners show detection.
# req RT_Stats & mt_tools_2

OBJECT_W  = 20      # Object to find, size in pixels
OBJECT_H  = 40      # Object to find, size in pixels

AREA_X = 0          # Area of frame to search (0,0,0,0=full frame {As Crop})
AREA_Y = 0
AREA_W = 0
AREA_H = 0

LUMA_MIN = 235      # Luma minimum of object to find
LUMA_MAX = 255

# Fake input clip, for testing
a = BlankClip(length=481,width=480,height=480)
b = BlankClip (width=OBJECT_W, height=OBJECT_H, color=$FFFFFF)
a.Animate (0, a.FrameCount () - 1, "Overlay", b, 0, 0, b, 480, 480)

ConvertToYV12()     # Any colorspace ok so long as LUMA_MIN/MAX OK (RGB -> Luma-Y)

MarkerColor = $FFFF00       # Detection marker color
MARKER_TYPE = False         # False = Corners only marker, True=Full Rect Marker
Msk  = Hit_Marker(OBJECT_W+8,OBJECT_H+8,MARKER_TYPE)
Mrk  = Msk.BlankClip(Color=MarkerColor)

DEBUG=True
NOTFOUND="NOT FOUND"    # Last few frames should show not found, depends upon OBJECT_W/H (as partially disappears off frame).
sep = ", "
ket = "] "
COORDINATES=RT_GetFullPathName("Y_Coordinates.txt")
RT_FileDelete(COORDINATES)  # Delete coordinates file

ScriptClip ("""
    Bingo=RT_YInRangeLocate(debug=DEBUG,Baffle_W=OBJECT_W,Baffle_H=OBJECT_H,x=AREA_X,y=AREA_Y,w=AREA_W,h=AREA_H,Lo=LUMA_MIN,hi=LUMA_MAX)
    (Bingo) ? WriteFile (COORDINATES,"current_frame","KET", "YIRL_X", "sep", "YIRL_Y", "sep", "YIRL_W", "sep", "YIRL_H")
            \ : WriteFile (COORDINATES,"current_frame","KET", "NOTFOUND")
    (Bingo) ? Overlay(Mrk,x=YIRL_X-4,y=YIRL_Y-4,Mask=Msk,Mode="Blend",output="YV12")
            \ : NOP
    Return Last
""")

Return Last

Function Hit_Marker(int W, Int H, Bool "Hit", Int "BW", Int "BH",Int "PW",Int "PH",Bool "YV12",Bool "Mod2") {
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
