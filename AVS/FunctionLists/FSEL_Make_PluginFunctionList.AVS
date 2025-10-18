# Make_PluginFunctionList.AVS by StainlessS.
# Requires either Avs+ or GScript.
# Avs+, does not return Plugins directory to RT_Stats, so must navigate to plugins dir in file selector.
# Extracts names and args of Filters and Functions contained in an autoloaded dll, results written to text file.
# Plugins need to be auto loaded in Plugins Dir.
# May not work if more than 50 plugs in plugins dir (Avisynth max 50 auto loaded).

ORDER=True

HEAD="""
There follows a list of all function names together with CPP style argument specifiers that inform
Avisynth the argument types and optional names. Optional arguments have square brackets surrounding
their name as in [name] and are followed by a type specifier character that gives the type.
Unnamed arguments are not optional. eg "cc[arg1]b[arg2]i" would be two compulsory unnamed clip args,
followed by optional 'arg1' of type bool and optional 'arg2' of type int.

# Argument type specifier strings.
 c - Video Clip
 i - Integer number
 f - Float number
 s - String
 b - boolean
 . - Any type (dot)
# Array Specifiers
 i* - Integer Array, zero or more
 i+ - Integer Array, one or more
 .* - Any type Array, zero or more
 .+ - Any type Array, one or more
#    Etc
###################################
"""

	myName="FSEL_Make_PluginFunctionList: "
	IsAvsPlus = (FindStr(VersionString, "AviSynth+")>0 || FindStr(VersionString, "AviSynth Neo")>0)
	HasGScript=RT_FunctionExist("GScript")
    Assert(IsAvsPlus || HasGScript,RT_String("%sNeed either GScript or AVS+",myName))
    FSEL_TITLE="Select DLL file"
    FSEL_DIR=RT_PluginDir()
    FSEL_FILT="DLL files|*.dll"
    FSEL_MULTI=False
    DLLFILE_LIST = RT_FSelOpen(title=FSEL_TITLE,dir=FSEL_DIR,filt=FSEL_FILT,multi=FSEL_MULTI)
    Assert(DLLFILE_LIST.IsString,"RT_FSelOpen: Error="+String(DLLFILE_LIST))
    DLLFN=RT_TxtGetLine(DLLFILE_LIST,0)
    PREFIX = RT_FilenameSplit(DLLFN,4) + "_"
    PREFIX_LEN=StrLen(PREFIX)
    ALLPLUGS = RT_StrReplace(RT_PluginFunctions," ",Chr(10))
    Assert(RT_TxtFindStr(ALLPLUGS,PREFIX,Sig=False,Start=0)>=0,PREFIX+" Not found, Not an AutoLoad plugin(or more than 50 plugs)")
	LINES = RT_TxtQueryLines(ALLPLUGS)
    PLUGS = ""
    PARMS = ""
    MaxLen  = 0
    DQUOT=34                                                                            # Double Quote Chr(34)
    GS="""
        for(i=0,LINES-1) {
            i=RT_TxtFindStr(ALLPLUGS,PREFIX,Sig=False,Start=i)
            if(i >= 0) {
                PLG=RT_TxtGetLine(ALLPLUGS,Line=i)
                if(RT_FindStr(PLG,PREFIX,Sig=False)==1) {                               # match at start ?
                    SHORTPLG=MIDStr(PLG,PREFIX_LEN+1)
                    MaxLen=Max(MaxLen,StrLen(SHORTPLG))
                    PLUGS=RT_TxtAddStr(PLUGS,SHORTPLG)
                    PARMS=RT_TxtAddStr(PARMS,RT_String(" %c%s%c",DQUOT,RT_PluginParam(PLG),DQUOT))
                }
            } Else {
                i = LINES   # break, no more to find
            }
        }
        LINES = RT_TxtQueryLines(PLUGS)
        PLUGS_AND_PARMS=""
        for(i=0,LINES-1) {
            PLUGS_AND_PARMS=RT_TxtAddStr(PLUGS_AND_PARMS,RT_StrPad(RT_TxtGetLine(PLUGS,Line=i),MaxLen)+RT_TxtGetLine(PARMS,Line=i))
        }
    """
    HasGScript ? GScript(GS) : Eval(GS) # Use GSCript if installed (loaded plugs override builtin)

    PLUGS_AND_PARMS = (ORDER) ? RT_TxtSort(PLUGS_AND_PARMS) : PLUGS_AND_PARMS   # Order Alphabetical
    TXT = RT_String("%s%sFunction_List",PREFIX,(ORDER)?"ORDERED_":"")
    FN=TXT+".TXT"
    S=RT_String("\n        %s \n\n%s\n\n%s",TXT,HEAD,PLUGS_AND_PARMS)
    RT_TxtWriteFile(S,FN)
    S=RT_TxtAddStr(S,RT_String("\n\n%s\n\nCreated in current directory\n",FN))
    W=1280 H=640 LINES=RT_TxtQueryLines(S)
    L=LINES*20+H+100
	Global Glb_S=S  # Avisynth NEO fix
    BlankClip(Width=W,Height=H,Length=L).ScriptClip("""RT_Subtitle("%s",Glb_S,x=10,y=height+100-current_frame,expx=true,expy=true)""")
