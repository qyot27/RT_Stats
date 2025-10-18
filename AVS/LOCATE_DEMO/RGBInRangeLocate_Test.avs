# RGBInRangeLocate_Test

# NOTE, Angle corners show detection.
# req RT_Stats & mt_tools_2

RED     =$AA        # Object Color to look for
GREEN   =$CC
BLUE    =$FF

OBJECT_W  = 10      # Object Width
OBJECT_H  = 10      # Object Height

AREA_X = 0          # Area of frame to search (0,0,0,0=full frame, As Crop)
AREA_Y = 0
AREA_W = 0
AREA_H = 0

R_MIN = RED     R_MAX = RED
G_MIN = GREEN   G_MAX = GREEN
B_MIN = BLUE    B_MAX = BLUE

# Overlay Converts RGB->YUV->RGB (can set inexact color). Use Layer Instead, MUST set ALPHA
RGBA=((255 * 256 + RED)*256+GREEN)*256+BLUE

COORDINATES=RT_GetFullPathName("RGB_Coordinates.txt")

# Fake input clip, for testing
a = BlankClip(length=480,width=480,height=480)
b = a.BlankClip(width=OBJECT_W, height=OBJECT_H, color=RGBA)
a.Animate (0, a.FrameCount () - 1, "Layer", b,"add",257, 0, 0, b,"add",257, 479, 479)

MarkerColor = $FFFF00       # Detection marker color
MARKER_TYPE = false         # False = Corners only marker, True=Full Rect Marker
Msk  = Hit_Marker(OBJECT_W+8,OBJECT_H+8,MARKER_TYPE)
Mrk  = Msk.BlankClip(Color=MarkerColor)

NOTFOUND="NOT FOUND"    # Will be NOT FOUND, As OBJECT moves out of frame at end of clip (can no longer find size OBJECT_W x OBJECT_H)
sep = ", "
Ket = "] "
RT_FileDelete(COORDINATES)  # Delete coordinates file
DEBUG=False
ScriptClip ("""
    Bingo=RT_RgbInRangeLocate(x=AREA_X,y=AREA_Y,w=AREA_W,h=AREA_H,
        \ RLo=R_MIN,Rhi=R_MAX,GLo=G_MIN,Ghi=G_MAX,BLo=B_MIN,Bhi=B_MAX,Baffle_W=OBJECT_W,Baffle_H=OBJECT_H,debug=DEBUG)
    (Bingo) ? WriteFile (COORDINATES,"current_frame", "Ket",  "RGBIRL_X", "sep", "RGBIRL_Y")
        \ : WriteFile (COORDINATES,"current_frame", "Ket", "NOTFOUND")

    (Bingo) ? Overlay(Mrk,x=RGBIRL_X-4,y=RGBIRL_Y-4,Mask=Msk,Mode="Blend")
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
