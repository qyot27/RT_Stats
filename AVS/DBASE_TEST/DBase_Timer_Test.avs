# DBase_Timer_Test.Avs, Requires RT_Stats and GScript plugs, DebugView for  output

# Config
DB						= "DBASE.RDB"	# DBase FileName
TYPESTRING 				= "bifs64ne"	# Describes DBase Fields and optional size of any String Fields (chosen types unknown to below script)
                                        # b=Bool, i=Int,f=Float,s=String(eg "s256" is StringLen=256),n=BIN, e=Double (Get/Set as Float)
RECORDS					= 10000			# Initial number of records in DBase
DEFAULT_STRINGLENMAX	= 256			# If TYPESTRING type 's' String type Field does not have explicit size trailer.
DELETE					= true

##################################
ALPHA = "ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ"
ALPHA=ALPHA+ALPHA # Len 260
SSS=""
ERR=0

myName="DBase_Timer_Test: "
IsAvsPlus=(FindStr(UCase(versionString),"AVISYNTH+")!=0)    HasGScript=RT_FunctionExist("GScript")
Assert(IsAvsPlus || HasGScript,RT_String("%sNeed either GScript or AVS+",myName))

GS="""
	TOTAL_START=RT_TimerHP()
	S=RT_String("DBase_Timer_Test.Avs")
	RT_DebugF(S)
	SSS=SSS+S+" [See DebugView Output (Google)]" + CHR(10)+CHR(10)
	START=RT_TimerHP()
	RT_DBaseAlloc(DB,RECORDS,TYPESTRING,stringlenmax=DEFAULT_STRINGLENMAX)
	STOP=RT_TimerHP()
	S=RT_String("TYPESTRING   = %c%s%c",34,TYPESTRING,34)
	RT_DebugF(S)
	SSS=SSS+S+Chr(10)+Chr(10)
	S=RT_String("Records      = %d",RT_DBaseRecords(DB))
	RT_DebugF(S)
	SSS=SSS+S+Chr(10)+Chr(10)
	S=RT_String("RecordSize   = %d",RT_DBaseRecordSize(DB))
	RT_DebugF(S)
	SSS=SSS+S+Chr(10)+Chr(10)
	S=RT_String("RecordsMax   = %d ($%X)",RT_DBaseRecordsMax(DB),RT_DBaseRecordsMax(DB))
	RT_DebugF(S)
	SSS=SSS+S+Chr(10)+Chr(10)
	FIELDS=RT_DBaseFields(DB)
	S=RT_String("Fields       = %d",FIELDS)
	RT_DebugF(S)
	SSS=SSS+S+Chr(10)+Chr(10)
	for(i=0,Fields - 1) {
		TYPE_S=RT_DBaseTypeName(RT_DBaseFieldType(DB,i))
		RT_DebugF("  %2d ) Type = %d(%6s) Size = %d",i,RT_DBaseFieldType(DB,i),TYPE_S,RT_DBaseFieldSize(DB,i))
	}
    Attributes  = RT_DBaseGetAttrib(DB,-1)
    SAttributes = RT_DBaseGetStrAttrib(DB,-1)
    SAttribMAX  = RT_DBaseGetStrAttrib(DB,-2)
    Nids        = RT_DBaseGetID(DB,-1)
	S=RT_String("Attributes         = %d",Attributes)
	RT_DebugF(S)
	SSS=SSS+S+Chr(10)+Chr(10)
	S=RT_String("String Attributes  = %d",SAttributes)
	RT_DebugF(S)
	SSS=SSS+S+Chr(10)+Chr(10)
	S=RT_String("String AttribMaxLen= %d",SAttribMAX)
	RT_DebugF(S)
	SSS=SSS+S+Chr(10)+Chr(10)
	S=RT_String("IDs                = %d",Nids)
	RT_DebugF(S)
	SSS=SSS+S+Chr(10)+Chr(10)
	S=RT_String("RT_DBaseAlloc() = %.3f secs (Per Field Ave %f microsecs)",STOP-START,1000000.0*(STOP-START)/(RECORDS*FIELDS))
	RT_DebugF(S)
	SSS=SSS+S+CHR(10)+CHR(10)
	RT_DebugF("Check Init")
	START_INIT=RT_TimerHP()
	# You would likely know the Types in your own database (we do not, MUCH SLOWER as we have to inquire from DBASE on each Field Interation)
	# Probably faster to do nested Record, Field, if we knew DBASE types in advance
    # (The DBase field types are user configured in config section:TYPESTRING, so we dont actually know here what types were requested)
	for(field=0,FIELDS - 1) {
		type = RT_DBaseFieldType(DB,field)	# You would likely know the types of your own database (User configued at start of script).
        TYPE_S=RT_DBaseTypeName(type)
        vs=Select(type,False,0,0.0,"",0,0.0)
		RT_DebugF("Check Init on field %d Type=%d(%6s)",field,type,TYPE_S)
		START=RT_TimerHP()
		for(record=0,RECORDS - 1 ) {
		vg=RT_DBaseGetField(DB,record,field)
		if(!RT_VarIsSame(vg,vs)) {
			RT_DebugF("ERROR, Record:Field %d:%d Type %d Set=%s Get=%s",record,field,type,String(vs),String(vg))
				ERR=ERR+1
		}
		}
		STOP=RT_TimerHP()
		RT_DebugF("Check Init on field %d Type=%d(%6s) = %.3f secs (Per field Ave %f microsecs)",field,type,TYPE_S,STOP-START,1000000.0*(STOP-START)/RECORDS)
	}
	STOP_INIT=RT_TimerHP()
	S=RT_String("TOTAL Check Init = %.3f secs (Per Field Ave %f microsecs)",STOP_INIT-START_INIT,1000000.0*(STOP_INIT-START_INIT)/(RECORDS*FIELDS))
	RT_DebugF(S)
	SSS=SSS+S+CHR(10)+CHR(10)
	Try {RT_DBaseGetField(RT_DBaseRecords(DB),0)RT_DebugF("Init END Check FAILED") ERR=ERR+1} catch (msg) {RT_DebugF("Init END Check Passed")}
    RT_DebugF("Check %d Attributes 10 times each Set/Get",Attributes)
    START=RT_TimerHP()
    for(ii=1,10) {									# Loop 10 times for better timing
	    for(i=0,Attributes-1) {
	        type=(i % 2 == 0) ? 1 : 2
	        vs= (type==1) ? i*1000 : i * 64.0       # Test Int and Float Attributes
	        RT_DBaseSetAttrib(DB,i,vs)
	        vg = RT_DBaseGetAttrib(DB,i)
	        if(!RT_VarIsSame(vg,vs)) {
	            RT_DebugF("%d) TYPE=%d SetAttrib/GetAttrib Error, Set = %s Get = %s",i,type,String(vs),String(vg))
				ERR=ERR+1
	        }
	    }
    }
    STOP=RT_TimerHP()
    S=RT_String("Check Attributes Set/Get Compare = %.3f secs (Per element Ave %f microsecs)",STOP-START,1000000.0*(STOP-START)/(Attributes*10))
	RT_DebugF(S)
	SSS=SSS+S+CHR(10)+CHR(10)

    RT_DebugF("Check %d String Attributes(len=%d) Set/Get",SAttributes,SAttribMAX)
    START=RT_TimerHP()
    for(i=0,SAttributes-1) {
        vs = RT_StrPad("",SAttribMAX,Chr(65+i))
        RT_DBaseSetStrAttrib(DB,i,vs)
        vg = RT_DBaseGetStrAttrib(DB,i)
        if(!RT_VarIsSame(vg,vs)) {
            RT_DebugF("%d) SetStrAttrib/GetStrAttrib Error,\n  Set = %s\n  Get = %s",i,String(vs),String(vg))
			ERR=ERR+1
        }
    }
    STOP=RT_TimerHP()
    S=RT_String("Check String Attributes Set/Get Compare = %.3f secs (Per element Ave %f microsecs)",STOP-START,1000000.0*(STOP-START)/(SAttributes))
	RT_DebugF(S)
	SSS=SSS+S+CHR(10)+CHR(10)

	RT_DebugF("Check Set/Get Compare")
	Rand(seed=true)
	START_SETGET=RT_TimerHP()
	for(field=0,FIELDS - 1) {
		type = RT_DBaseFieldType(DB,field)
        TYPE_S=RT_DBaseTypeName(type)
		fieldsize=RT_DBaseFieldSize(DB,field)
		rnd=Rand() + 1	# ALL fields types set same as just timing
		RT_DebugF("Check Set on field %d Type=%d(%6s)",field,type,TYPE_S)
        vs=Select(Type,RT_BitTst(rnd,0),rnd,Float(rnd),RightStr(ALPHA + "_" + String(rnd),fieldsize) ,RT_BitAnd(rnd,$FF),Float(rnd))
		START=RT_TimerHP()
		for(record=0,RECORDS - 1 ) {
			RT_DBaseSetField(DB,record,field, vs)
		}
		STOP=RT_TimerHP()
		S=RT_String("Check Set on field %d Type=%d(%6s) = %.3f secs (Per field Ave %f microsecs)",field,type,TYPE_S,STOP-START,1000000.0*(STOP-START)/RECORDS)
		RT_DebugF(S)
		SSS=SSS+S+CHR(10)+CHR(10)
		RT_DebugF("Check Get on field %d Type=%d(%6s)",field,type,TYPE_S)
		START=RT_TimerHP()
		for(record=0,RECORDS - 1 ) {
			vg=RT_DBaseGetField(DB,record,field)
		if(!RT_VarIsSame(vg,vs)) {
			RT_DebugF("ERROR, Record:Field %d:%d Type %d Set=%s Get=%s",record,field,type,String(vs),String(vg))
				ERR=ERR+1
		}
		}
		STOP=RT_TimerHP()
		S=RT_String("Check Get/Compare on field %d Type=%d(%6s) = %.3f secs (Per field Ave %f microsecs)",field,type,TYPE_S,STOP-START,1000000.0*(STOP-START)/RECORDS)
		RT_DebugF(S)
		SSS=SSS+S+CHR(10)+CHR(10)
	}
	STOP_SETGET=RT_TimerHP()
	S=RT_String("TOTAL Check Set/Get Compare = %.3f secs (Per field Ave %f microsecs)",STOP_SETGET-START_SETGET,1000000.0*(STOP_SETGET-START_SETGET)/(RECORDS*FIELDS))
	RT_DebugF(S)
	SSS=SSS+S+CHR(10)+CHR(10)

	RT_DebugF("COMPARISON Get Compare on Avisynth Type Int LOCAL VAR")
	START=RT_TimerHP()
    vs   = 42
    TEST_INT = vs
	for(record=0,RECORDS - 1 ) {
		vg = TEST_INT
	if(!RT_VarIsSame(vg,vs)) {
			ERR=ERR+1
	}
	}
	STOP=RT_TimerHP()
	S=RT_String("COMPARISON Get Compare on Int LOCAL VAR = %.3f secs (Per field Ave %f microsecs)",STOP-START,1000000.0*(STOP-START)/RECORDS)
	RT_DebugF(S)
	SSS=SSS+CHR(10)+S+CHR(10)+CHR(10)

	RT_DebugF("COMPARISON Get Compare on Avisynth Type Int GLOBAL VAR")
	START=RT_TimerHP()
    vs   = 42
    G_TEST_INT = vs
	for(record=0,RECORDS - 1 ) {
		vg = G_TEST_INT
	if(!RT_VarIsSame(vg,vs)) {
			ERR=ERR+1
	}
	}
	STOP=RT_TimerHP()
	S=RT_String("COMPARISON Get Compare on Int GLOBAL VAR = %.3f secs (Per field Ave %f microsecs)",STOP-START,1000000.0*(STOP-START)/RECORDS)
	RT_DebugF(S)
	SSS=SSS+S+CHR(10)+CHR(10)

	TOTAL_STOP=RT_TimerHP()
	S=RT_String("TOTAL SCRIPT TIME = %.3f seconds\n\nERRORS=%d",TOTAL_STOP-TOTAL_START,ERR)
	RT_DebugF(S)
	SSS=SSS+S+CHR(10)
	(DELETE) ? RT_FileDelete(DB) : NOP
"""

HasGScript ? GScript(GS) : Eval(GS) # Use GSCript if installed (loaded plugs override builtin)

colorbars(Width=928,Height=696).KillAudio
MOD = RT_TxtQueryLines(SSS) * 20 + Height + 100
ScriptClip("""RT_Subtitle(SSS,y=height+100-(current_frame % MOD),expy=true)""")
