avi = RT_FSelOpen("Please select an AVI file",Filt="*.AVI|*.AVI")
Assert(avi.IsString,"RT_FSelOpen: Error="+String(avi))
AVISource(AVI)
txt = RT_FSelOpen("And now select a Text file",Filt="*.txt|*.txt")
Assert(txt.IsString,"RT_FSelOpen: Error="+String(txt))
Txt=RT_ReadTxtFromFile(txt)
Lines=RT_TxtQueryLines(Txt)
# config
DELAY=100
ALIGN=5			# As Numeric KeyPad
SCROLL=0		# 0 = Upwards : 1 = Downwards : 2 = Right to Left : 3 = Left to right : 4 = Karaoke
#
ORG=Last
Last=(SCROLL==4)? ORG.Blankclip(height=80) : Last
CMD_0 = """RT_Subtitle("%s",Txt,align=ALIGN,y=height+DELAY-current_frame,expx=true,expy=true)"""
CMD_1 = """RT_Subtitle("%s",Txt,align=ALIGN,y=-(Lines*20+DELAY) + current_frame,expx=true,expy=true)"""
CMD_2 = """RT_Subtitle("%s",Txt,align=ALIGN,x=width+DELAY-current_frame,expx=true,vcent=true)"""
CMD_3 = """RT_Subtitle("%s",Txt,align=ALIGN,x=-(width+DELAY)+current_frame,expx=true,vcent=true)"""
CMD_4 = """RT_Subtitle("%s",Txt,align=ALIGN,y=height+DELAY-current_frame,expx=true,expy=true)"""
CMD_5 = """RT_Subtitle("BAD SCROLL COMMAND (0->4)")"""
CMD = (SCROLL<0 || SCROLL>4) ? CMD_5 : Select(Scroll,CMD_0,CMD_1,CMD_2,CMD_3,CMD_4)
ScriptClip(CMD)
Return (SCROLL==4)? StackVertical(ORG,Last) : Last
