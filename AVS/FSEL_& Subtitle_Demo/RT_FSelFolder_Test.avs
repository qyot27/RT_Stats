########
# RT_FSelFolder() by StainlessS
#
# Function RT_FSelFolder(string "title"="",string "dir"=".",bool "debug"=false)
#
# Function to select Folder.
#
# Title = UNDERNEATH the title bar text, for instructions.
# Dir   = Directory, Default "." = Current, ""=Root.
# debug = Send errors to DebugView window.
#
# Returns
#   int, 0, user CANCELLED.
#   int, non zero is error (ie -1, error sent to DebugView window, usually selecting non Folder object eg 'My Computer').
#   String, Folder selected (minus trailing BackSlash).
########

TITLE ="USE THIS TO SELECT A FOLDER"
DIR="."         # Current Dir (Default)
#DIR=""         # Root, My Computer
#DIR="D:\avs\"  # Something Else
result = RT_FSelFolder(title=TITLE,dir=DIR)

Assert(result.IsString,"FSelFolder: Error="+String(Result))

return colorbars.Subtitle(result)
