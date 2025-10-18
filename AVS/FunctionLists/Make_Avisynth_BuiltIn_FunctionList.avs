# Make_Avisynth_BuiltIn_FunctionList.avs by StainlessS.
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
	myName="Make_Avisynth_BuiltIn_FunctionList: "
	IsAvsPlus = (FindStr(VersionString, "AviSynth+")>0 || FindStr(VersionString, "AviSynth Neo")>0)
	HasGScript=RT_FunctionExist("GScript")
    Assert(IsAvsPlus || HasGScript,RT_String("%sNeed either GScript or AVS+",myName))
    ALL_PLUGS = RT_StrReplace(RT_InternalFunctions," ",Chr(10))
    LINES = RT_TxtQueryLines(ALL_PLUGS)
    PLUGS = ""
    PARMS = ""
    MaxLen  = 0
    DQUOT=34                                                                            # Double Quote Chr(34)
    GS="""
        for(i=0,LINES-1) {
            PLG=RT_TxtGetLine(ALL_PLUGS,Line=i)
            MaxLen=Max(MaxLen,StrLen(PLG))
            PARAM=RT_PluginParam(PLG)
            PLUGS=RT_TxtAddStr(PLUGS,PLG)
            PARMS=RT_TxtAddStr(PARMS,RT_String(" %c%s%c",DQUOT,PARAM,DQUOT))
        }
        PLUGS_AND_PARMS=""
        for(i=0,LINES-1) {
            PLUGS_AND_PARMS=RT_TxtAddStr(PLUGS_AND_PARMS,RT_StrPad(RT_TxtGetLine(PLUGS,Line=i),MaxLen)+RT_TxtGetLine(PARMS,Line=i))
        }
    """
    HasGScript ? GScript(GS) : Eval(GS) # Use GScript if installed (loaded plugs override builtin)

    PLUGS_AND_PARMS = (ORDER) ? RT_TxtSort(PLUGS_AND_PARMS) : PLUGS_AND_PARMS   # Order Alphabetical
	FND_S=RT_string(" \n:\n-\n\\\n/\n")
	REP_S=RT_string("_\n_\n_\n_\n_\n")
	VER = RT_StrReplaceMulti(VersionString,FND_S,REP_S)
	TXT = VER
	INTERN=RT_String("_%sFunction_List",(ORDER)?"ORDERED_":"")
    FN = TXT+INTERN+".TXT"
    S=RT_String("\n        %s%s\n\n%s\n\n%s",VER,INTERN,HEAD,PLUGS_AND_PARMS)
    RT_WriteFile(FN,S)
    S2=RT_String("\n\n%s\n\nCreated in current directory\n",FN)
    S=RT_TxtAddStr(S,S2)
    W=1280 H=640 LINES=RT_TxtQueryLines(S)
    L= LINES*20 + H + 100
	Global Glb_S=S # Avisynth NEO fix
    BlankClip(Width=W,Height=H,Length=L).ScriptClip("""RT_Subtitle("%s",Glb_S,x=10,y=height+100-current_frame,expx=true,expy=true)""")
