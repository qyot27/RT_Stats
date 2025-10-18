# Make_RT_Stats_FunctionList.avs by StainlessS.
# Requires either Avs+ or GScript.


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
	myName="Make_RT_Stats_FunctionList: "
	IsAvsPlus = (FindStr(VersionString, "AviSynth+")>0 || FindStr(VersionString, "AviSynth Neo")>0)
	HasGScript=RT_FunctionExist("GScript")
    Assert(IsAvsPlus || HasGScript,RT_String("%sNeed either GScript or AVS+",myName))
    PLUGS = RT_StrReplace(RT_PluginFunctions," ",Chr(10))
    LINES = RT_TxtQueryLines(PLUGS)
    RT_PLUGS = ""
    RT_PARMS = ""
    MaxLen  = 0
    DQUOT=34                                                                            # Double Quote Chr(34)
    GS="""
        for(i=0,LINES-1) {
            i=RT_TxtFindStr(PLUGS,"RT_",Sig=False,Start=i)
            if(i >= 0) {
                PLG=RT_TxtGetLine(PLUGS,Line=i)
                if(RT_FindStr(PLG,"RT_",Sig=False)==1) {                                # Avoid RemoveDiRT_RemoveDiRT()
                    if(RT_FindStr(PLG,"_RT_",Sig=False,Pos=8) == 0) {                   # Not the long name (incl dll name)
                        MaxLen=Max(MaxLen,StrLen(PLG))
                        RT_PLUGS=RT_TxtAddStr(RT_PLUGS,PLG)
                        RT_PARMS=RT_TxtAddStr(RT_PARMS,RT_String(" %c%s%c",DQUOT,RT_PluginParam(PLG),DQUOT))
                    }
                }
            } Else {
                i = LINES   # break, no more to find
            }
        }
        LINES = RT_TxtQueryLines(RT_PLUGS)
        RT_PLUGS_AND_PARMS=""
        for(i=0,LINES-1) {
            RT_PLUGS_AND_PARMS=RT_TxtAddStr(RT_PLUGS_AND_PARMS,RT_StrPad(RT_TxtGetLine(RT_PLUGS,Line=i),MaxLen)+RT_TxtGetLine(RT_PARMS,Line=i))
        }
    """
    HasGScript ? GScript(GS) : Eval(GS) # Use GSCript if installed (loaded plugs override builtin)

    RT_PLUGS_AND_PARMS = (ORDER) ? RT_TxtSort(RT_PLUGS_AND_PARMS) : RT_PLUGS_AND_PARMS   # Order Alphabetical
    TXT = RT_String("RT_Stats_v%s_%sFunction_List",RT_VersionString,(ORDER)?"ORDERED_":"")
    FN=TXT+".TXT"
    S=RT_String("\n        %s\n\n%s\n\n%s",TXT,HEAD,RT_PLUGS_AND_PARMS)
    RT_WriteFile(FN,S)
    S=RT_TxtAddStr(S,RT_String("\n\n%s\n\nCreated in current directory\n",FN))
    W=1280 H=640 LINES=RT_TxtQueryLines(S)
    L=LINES*20+H+100
	Global Glb_S=S # Avisynth NEO fix
    BlankClip(Width=W,Height=H,Length=L).ScriptClip("""RT_Subtitle("%s",Glb_S,x=10,y=height+100-current_frame,expx=true,expy=true)""")
