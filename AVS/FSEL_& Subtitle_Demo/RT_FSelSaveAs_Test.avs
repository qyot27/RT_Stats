########
# RT_FSelSaveAs() by StainlessS
#
# Function RT_FSelSaveAs(string "title"="Open",string "dir"="",string  "filt",string "fn="",bool "debug"=false)
#
# Function to select filename for Save.
#
# Title = Title bar text.
# Dir   = Directory, "" = Current
# Filt  = Lots, most of below with a few more mpeg. [Displayed text | wildcard] [| more pairs of Displayed text and wildcard, in pairs ONLY].
#         first one is default.
# fn    = Initially presented filename (if any).
# debug = send errors to DebugView window.
#
# Returns
#   int, 0, user CANCELLED.
#   int, non zero is error (error sent to DebugView window).
#   String, Filename selected.
########

TITLE ="Save a File, if you think you know what you are doing"
DIR   =""
FILT  = "All files (*.*)|*.*|"
     \ + "Image files (*.bmp;*.jpg;*.jpe;*.jpeg;*.png;*.tga;*.tif;*.gif;*.tiff)|*.bmp;*.jpg;*.jpe;*.jpeg;*.png;*.tga;*.tif;*.gif;*.tiff|"
     \ + "Mpg files (*.vob;*.mpg;*.mpeg etc)|*.vob;*.mpg;*.mpeg;*.m1v;*.m2v;*.mpv;*.tp;*.ts;*.trp;*.m2t;*.m2ts;*.pva;*.vro|"
     \ + "Avi Files (*.avi)|*.avi|"
     \ + "Avs files (*.avs;*.avsi)|*.avs;*.avsi|"
     \ + "Text files (*.txt)|*.txt"

FN    ="AnyAnyAnyOldIron.txt"

result = RT_FSelSaveAs(title=TITLE,dir=DIR,Filt=FILT,fn=FN)
Assert(result.IsString,"RT_FSelSaveAs: Error="+String(Result))

return colorbars.Subtitle(Result)
