########
# RT_FSelOpen() by StainlessS
#
# Function RT_FSelOpen(string "title"="Open",string "dir"="",string  "filt",string "fn="",bool "multi"=false,bool "debug"=false)
#
# Function to select EXISTING filename.
#
# Title = Title bar text.
# Dir   = Directory, "" = Current
# Filt  = Lots, most of below with a few more mpeg. [Displayed text | wildcard] [| more pairs of Displayed text and wildcard, in pairs ONLY].
#         first one is default.
# fn    = Initially presented filename (if any).
# multi = Multiply Select filenames. Allows selection of more than one filename.
# debug = Send error info to DebugView window.
#
# Returns
#   int, 0, user CANCELLED.
#   int, non zero is error (error sent to DebugView window).
#   String, Filename selected, Chr(10) separated multiline string if MULTI==true (and multiple files selected).
#
########

TITLE ="Open a File, if you really really want to"
DIR   =""
FILT  = "All files (*.*)|*.*|"
     \ + "Image files (*.bmp;*.jpg;*.jpe;*.jpeg;*.png;*.tga;*.tif;*.gif;*.tiff)|*.bmp;*.jpg;*.jpe;*.jpeg;*.png;*.tga;*.tif;*.gif;*.tiff|"
     \ + "Mpg files (*.vob;*.mpg;*.mpeg etc)|*.vob;*.mpg;*.mpeg;*.m1v;*.m2v;*.mpv;*.tp;*.ts;*.trp;*.m2t;*.m2ts;*.pva;*.vro|"
     \ + "Avi Files (*.avi)|*.avi|"
     \ + "Avs files (*.avs;*.avsi)|*.avs;*.avsi|"
     \ + "Text files (*.txt)|*.txt"

FN    ="AnyAnyAnyOldIron.txt"
MULTI = True
DEBUG=false
result = RT_FSelOpen(title=TITLE,dir=DIR,Filt=FILT,fn=FN,multi=MULTI,debug=DEBUG)

Assert(result.IsString,"RT_FSelOpen: Error="+String(Result))

colorbars

Lines = RT_TxtQueryLines(result)     				# Inquire how many filenames we got,
                                                    # Can use eg RT_TxtGetLine(result,Line) Where Line valid from 0 to Lines - 1.
Trim(0,-((2+Lines)*20+height))                      # Trim to len, Include Filename count + blank line (in RT_Subtitle).
return ScriptClip("""RT_Subtitle("We got %d Filenames\n\n%s",Lines,result,align=5,y=height-current_frame,expy=true)""")
