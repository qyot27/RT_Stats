# RT_Test_Array_1_Dim.Avs, 1 Dimensional array

ARRAY="TestArray.ARR"   # ARRAY name
START_TYPE   = 0        # 0=Bool,1=Int,2=Float,3=String,4=BIN(BYTE sized int),5=Double(8 byte double, Set/Get as Float)
END_TYPE     = 5        # 0=Bool,1=Int,2=Float,3=String,4=BIN(BYTE sized int),5=Double(8 byte double, Set/Get as Float) ## >= START_TYPE ##
DIM1         = 10000    # Inital Number of Array elements (init'ed to zero's) [Will be tripled by Append/Get and Extend/Get]
STRINGLENMAX = 64       # Excluding Nul Term.
                        # Take care with DIM1 and STRINGLENMAX when processing Type=String.
                        # Approx string usage greater than (DIM1 * (STRINGLENMAX+1) * ~12)
                        # String memory not released till Avisynth closure, no dead string garbage collection by Avisynth.
DELETE = True           # True = Delete ARRAY file when done

ALPHA = "ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ"
ALPHA=ALPHA+ALPHA # Len 260
ALPHA=(STRINGLENMAX<STRLEN(ALPHA)) ? LeftStr(ALPHA,STRINGLENMAX) : ALPHA        # cut down string manips and usage

NELS = DIM1

ERR=0

myName="RT_Test_Array_1_Dim: "
IsAvsPlus=(FindStr(UCase(versionString),"AVISYNTH+")!=0)    HasGScript=RT_FunctionExist("GScript")
Assert(IsAvsPlus || HasGScript,RT_String("%sNeed either GScript or AVS+",myName))

GS="""
    RT_DebugF("RT_Test_Array_1_Dim.avs - Single Dimension Array")
    TOTAL_START=RT_TimerHP()
    RT_DebugF("")
    For(TYPE=START_TYPE,END_TYPE) {
        RT_DebugF("==============================")
        TYPE_START=RT_TimerHP()
        RT_ArrayAlloc(ARRAY,Type=TYPE,dim1=DIM1,stringlenmax=STRINGLENMAX)
        STOP=RT_TimerHP()
        RT_DebugF("Type            = %d (%s)",RT_ArrayGetType(ARRAY),RT_ArrayTypeName(Type))
        RT_DebugF("ElSize          = %d",RT_ArrayGetElSize(ARRAY))
        RT_DebugF("Dimensions      = %d",RT_ArrayGetDim(ARRAY))
        RT_DebugF("Dim1            = %d",RT_ArrayGetDim(ARRAY,1))
        RT_DebugF("Dim1Max         = %d ($%X)",RT_ArrayGetDim1Max(ARRAY),RT_ArrayGetDim1Max(ARRAY))
        RT_DebugF("AttribCnt       = %d",RT_ArrayGetAttrib(ARRAY,-1))
        RT_DebugF("StrAttribCnt    = %d",RT_ArrayGetStrAttrib(ARRAY,-1))
        RT_DebugF("StrAttribMaxLen = %d",RT_ArrayGetStrAttrib(ARRAY,-2))
        RT_DebugF("IDCnt           = %d", RT_ArrayGetID(ARRAY,-1))
        RT_DebugF("Alloc Time = %.3f secs (Per element %f microsecs)",STOP-TYPE_START,1000000.0*(STOP-TYPE_START)/NELS)
        RT_DebugF("\nCheck Init")
        START=RT_TimerHP()
        TYPENAME = RT_ArrayTypeName(Type)
        if(TYPE==0) {        # Bool
            for(i=0,DIM1-1) {if(!RT_VarIsSame(RT_ArrayGet(ARRAY,i),False)) {RT_DebugF("BOOL(%d) Init != False",i) ERR=ERR+1}}
        } Else if(TYPE==1) { # Int
            for(i=0,DIM1-1) {if(!RT_VarIsSame(RT_ArrayGet(ARRAY,i),0)) {RT_DebugF("INT(%d) Init != 0",i) ERR=ERR+1}}
        } Else if(TYPE==2 || TYPE==5) { # Float OR Double
            for(i=0,DIM1-1) {if(!RT_VarIsSame(RT_ArrayGet(ARRAY,i),0.0)) {RT_DebugF("%s(%d) Init != 0.0",TYPENAME,i) ERR=ERR+1}}
        } Else if(TYPE==3) { # String
            for(i=0,DIM1-1) {if(!RT_VarIsSame(RT_ArrayGet(ARRAY,i),"")){RT_DebugF("STRING(%d) Init != %c%c",i,34,34) ERR=ERR+1}}
        } Else if(TYPE==4) { # BIN
            for(i=0,DIM1-1) {if(!RT_VarIsSame(RT_ArrayGet(ARRAY,i),0)) {RT_DebugF("BIN(%d) Init != 0",i) ERR=ERR+1}}
        }
        Try {RT_ArrayGet(ARRAY,DIM1) RT_DebugF("Init END Check FAILED") ERR=ERR+1} catch (msg) {RT_DebugF("Init END Check Passed")}
        STOP=RT_TimerHP()
        RT_DebugF("Check Init Time = %.3f secs (Per element %f microsecs)",STOP-START,1000000.0*(STOP-START)/NELS)

        RT_DebugF("Check Attributes Set/Get")
        NATTRIB = RT_ArrayGetAttrib(ARRAY,-1)
        START=RT_TimerHP()
        for(ii=1,20) {						  		        # loop 20 times for better timing
	        for(i=0,NATTRIB-1) {
	            vs= (i % 2 == 0) ? i*1000 : i * 64.0      	# Test Int and Float Attributes
	            RT_ArraySetAttrib(ARRAY,i,vs)
	            vg = RT_ArrayGetAttrib(ARRAY,i)
	            if(!RT_VarIsSame(vg,vs)) {
	                RT_DebugF("%d) TYPE=%d SetAttrib/GetAttrib Error, Set = %s Get = %s",i,TYPE,String(vs),String(vg))
	                ERR=ERR+1
	            }
	        }
        }
        STOP=RT_TimerHP()
        RT_DebugF("Check Attributes Set/Get = %.3f secs (Per element %f microsecs)",STOP-START,1000000.0*(STOP-START)/(NATTRIB*20))

        RT_DebugF("Check String Attributes Set/Get")
        NSATTRIB = RT_ArrayGetStrAttrib(ARRAY,-1)
        START=RT_TimerHP()
        for(ii=1,20) {						  		        # loop 20 times for better timing
	        for(i=0,NSATTRIB-1) {
                vs=RightStr(ALPHA + "_" + String(i),STRINGLENMAX)
	            RT_ArraySetStrAttrib(ARRAY,i,vs)
	            vg = RT_ArrayGetStrAttrib(ARRAY,i)
	            if(!RT_VarIsSame(vg,vs)) {
	                RT_DebugF("%d) TYPE=%d SetStrAttrib/GetStrAttrib Error, Set = %s Get = %s",i,TYPE,String(vs),String(vg))
	                ERR=ERR+1
	            }
	        }
        }
        STOP=RT_TimerHP()
        RT_DebugF("Check String Attributes Set/Get = %.3f secs (Per element %f microsecs)",STOP-START,1000000.0*(STOP-START)/(NSATTRIB*20))

        RT_DebugF("Check ID Set/Get")
        NID = RT_ArrayGetID(ARRAY,-1)
        START=RT_TimerHP()
        for(ii=1,20) {						  		        # loop 20 times for better timing
	        for(i=0,NID-1) {
	            vs= (i % 2 == 0) ? i*1000 : i * 64.0      	# Test Int and Float Attributes
	            RT_ArraySetID(ARRAY,i,vs)
	            vg = RT_ArrayGetID(ARRAY,i)
	            if(!RT_VarIsSame(vg,vs)) {
	                RT_DebugF("%d) TYPE=%d SetID/GetID Error, Set = %s Get = %s",i,TYPE,String(vs),String(vg))
	                ERR=ERR+1
	            }
	        }
        }
        STOP=RT_TimerHP()
        RT_DebugF("Check ID Set/Get = %.3f secs (Per element %f microsecs)",STOP-START,1000000.0*(STOP-START)/(NID*20))
        RT_DebugF("")

        RT_DebugF("Check Set only Time Test on %d Nels of type='%s'",NELS,RT_ArrayTypeName(Type))
        vs=Select(TYPE,True,42,42.0,RightStr(ALPHA + "_" + String(42),STRINGLENMAX) ,42,42.0)
        START=RT_TimerHP()
        for(i=0,DIM1-1) {
            RT_ArraySet(ARRAY,vs,i)
        }
        STOP=RT_TimerHP()
        RT_DebugF("Check Set Only Time = %.3f secs (Per element %f microsecs)",STOP-START,1000000.0*(STOP-START)/NELS)
        RT_DebugF("Check Get only Time Test on %d Nels of type='%s'",NELS,RT_ArrayTypeName(Type))
        START=RT_TimerHP()
        for(i=0,DIM1-1) {RT_ArrayGet(ARRAY,i)}
        STOP=RT_TimerHP()
        RT_DebugF("Check Get Only Time = %.3f secs (Per element %f microsecs)",STOP-START,1000000.0*(STOP-START)/NELS)
        RT_DebugF("Check Compare Set/Get - SET ONLY")
        START=RT_TimerHP()
        if(TYPE==0) {        # Bool
            for(i=0,DIM1-1) {
                vs = RT_BitTST(i,0) RT_ArraySet(ARRAY,vs,i)
            }
        } Else if(TYPE==1) { # Int
            for(i=0,DIM1-1) {
                vs = i RT_ArraySet(ARRAY,vs,i)
            }
        } Else if(TYPE==2 || TYPE==5) { # Float OR Double
            for(i=0,DIM1-1) {
                vs = Float(i) RT_ArraySet(ARRAY,vs,i)
            }
        } Else if(TYPE==3) { # String
            for(i=0,DIM1-1) {
                vs=RightStr(ALPHA + "_" + String(i),STRINGLENMAX) RT_ArraySet(ARRAY,vs,i)
            }
        } Else if(TYPE==4) { # BIN
            for(i=0,DIM1-1) {
                vs = RT_BitAnd(i,$FF) RT_ArraySet(ARRAY,vs,i)
            }
        }
        STOP=RT_TimerHP()
        RT_DebugF("Check Compare Set/Get - SET ONLY Time = %.3f secs (Per element %f microsecs) [Including Data generation]",STOP-START,1000000.0*(STOP-START)/NELS)
        RT_DebugF("Check Compare Set/Get - GET & COMPARE")
        START=RT_TimerHP()
        if(TYPE==0) {        # Bool
            for(i=0,DIM1-1) {
                vs = RT_BitTST(i,0) vg=RT_ArrayGet(ARRAY,i)
                if(!RT_VarIsSame(vs,vg)) {
                    RT_DebugF("%d) TYPE=%d Set/Get Error, Set = %s Get = %s",i,TYPE,String(vs),String(vg))
                    ERR=ERR+1
                }
            }
        } Else if(TYPE==1) { # Int
            for(i=0,DIM1-1) {
                vs = i vg=RT_ArrayGet(ARRAY,i)
                if(!RT_VarIsSame(vs,vg)) {
                    RT_DebugF("%d) TYPE=%d Set/Get Error, Set = %s Get = %s",i,TYPE,String(vs),String(vg))
                    ERR=ERR+1
                }
            }
        } Else if(TYPE==2 || TYPE == 5) { # Float OR Double
            for(i=0,DIM1-1) {
                vs = Float(i) vg=RT_ArrayGet(ARRAY,i)
                if(!RT_VarIsSame(vs,vg)) {
                    RT_DebugF("%d) TYPE=%d Set/Get Error, Set = %s Get = %s",i,TYPE,String(vs),String(vg))
                    ERR=ERR+1
                }
            }
        } Else if(TYPE==3) { # String
            for(i=0,DIM1-1) {
                vs=RightStr(ALPHA + "_" + String(i),STRINGLENMAX) vg=RT_ArrayGet(ARRAY,i)
                if(!RT_VarIsSame(vs,vg)) {
                    RT_DebugF("%d) TYPE=%d Set/Get Error, Set = %s Get = %s",i,TYPE,String(vs),String(vg))
                    ERR=ERR+1
                }
            }
        } Else if(TYPE==4) { # BIN
            for(i=0,DIM1-1) {
                vs = RT_BitAnd(i,$FF) vg=RT_ArrayGet(ARRAY,i)
                if(!RT_VarIsSame(vs,vg)) {
                    RT_DebugF("%d) TYPE=%d Set/Get Error, Set = %s Get = %s",i,TYPE,String(vs),String(vg))
                    ERR=ERR+1
                }
            }
        }
        STOP=RT_TimerHP()
        RT_DebugF("Check Compare Set/Get - GET & COMPARE Time = %.3f secs (Per element %f microsecs) [Including Data generation]",STOP-START,1000000.0*(STOP-START)/NELS)
        RT_DebugF("Check Compare Append/Get")
        START=RT_TimerHP()
        if(TYPE==0) {        # Bool
            for(i=DIM1,DIM1*2-1) {
                vs = RT_BitTST(i,0) RT_ArrayAppend(ARRAY,vs) vg=RT_ArrayGet(ARRAY,i)
                if(!RT_VarIsSame(vs,vg)) {
                    RT_DebugF("%d) TYPE=%d Set/Get Error, Set = %s Get = %s",i,TYPE,String(vs),String(vg))
                    ERR=ERR+1
                }
            }
        } Else if(TYPE==1) { # Int
            for(i=DIM1,DIM1*2-1) {
                vs = i RT_ArrayAppend(ARRAY,vs) vg=RT_ArrayGet(ARRAY,i)
                if(!RT_VarIsSame(vs,vg)) {
                    RT_DebugF("%d) TYPE=%d Append/Get Error, Set = %s Get = %s",i,TYPE,String(vs),String(vg))
                    ERR=ERR+1
                }
            }
        } Else if(TYPE==2 || TYPE == 5) { # Float OR Double
            for(i=DIM1,DIM1*2-1) {
                vs = Float(i) RT_ArrayAppend(ARRAY,vs) vg=RT_ArrayGet(ARRAY,i)
                if(!RT_VarIsSame(vs,vg)) {
                    RT_DebugF("%d) TYPE=%d Append/Get Error, Set = %s Get = %s",i,TYPE,String(vs),String(vg))
                    ERR=ERR+1
                }
            }
        } Else if(TYPE==3) { # String
            for(i=DIM1,DIM1*2-1) {
                vs=RightStr(ALPHA + "_" + String(i),STRINGLENMAX) RT_ArrayAppend(ARRAY,vs) vg=RT_ArrayGet(ARRAY,i)
                if(!RT_VarIsSame(vs,vg)) {
                    RT_DebugF("%d) TYPE=%d Append/Get Error, Set = %s Get = %s",i,TYPE,String(vs),String(vg))
                    ERR=ERR+1
                }
            }
        } Else if(TYPE==4) { # BIN
            for(i=DIM1,DIM1*2-1) {
                vs = RT_BitAnd(i,$FF) RT_ArrayAppend(ARRAY,vs) vg=RT_ArrayGet(ARRAY,i)
                if(!RT_VarIsSame(vs,vg)) {
                    RT_DebugF("%d) TYPE=%d Append/Get Error, Set = %s Get = %s",i,TYPE,String(vs),String(vg))
                    ERR=ERR+1
                }
            }
        }
        STOP=RT_TimerHP()
        RT_DebugF("Check Compare Append/Get Time = %.3f secs (Per element %f microsecs) [Including Data generation]",STOP-START,1000000.0*(STOP-START)/NELS)
		RT_DebugF("New Appended DIM=(%d)",RT_ArrayGetDim(ARRAY,1))
        RT_DebugF("Check Extend")
        START=RT_TimerHP()
		RT_ArrayExtend(ARRAY,DIM1)
        STOP=RT_TimerHP()
        RT_DebugF("Check Extend Time = %.3f secs (Per element %f microsecs)",STOP-START,1000000.0*(STOP-START)/NELS)
		RT_DebugF("New Extended DIM=(%d)",RT_ArrayGetDim(ARRAY,1))
        RT_DebugF("Check Extend Readable")
        START=RT_TimerHP()
        for(i=DIM1*2,DIM1*3-1) {
            RT_ArrayGet(ARRAY,i)
        }
        STOP=RT_TimerHP()
        RT_DebugF("Check Extend Readable Time = %.3f secs (Per element %f microsecs)",STOP-START,1000000.0*(STOP-START)/NELS)
        Try {RT_ArrayGet(ARRAY,DIM1*3) RT_DebugF("Final END Check FAILED") ERR=ERR+1} catch (msg) {RT_DebugF("Final END Check Passed")}
        if(RT_ArrayGetDim(ARRAY,1) != DIM1 * 3) {
            RT_DebugF("Final DIM1 Check ERROR, RT_ArrayGetDim(ARRAY,1) != DIM1 * 3 (is %d)",RT_ArrayGetDim(ARRAY,1))
            ERR=ERR+1
        }
        RT_DebugF("ALL Checks Done\n")
        RT_DebugF("Type            = %d (%s)",RT_ArrayGetType(ARRAY),RT_ArrayTypeName(Type))
        RT_DebugF("ElSize          = %d",RT_ArrayGetElSize(ARRAY))
        RT_DebugF("Dimensions      = %d",RT_ArrayGetDim(ARRAY))
        RT_DebugF("Dim1            = %d (should have tripled[%d])",RT_ArrayGetDim(ARRAY,1),DIM1*3)
        RT_DebugF("Dim1Max         = %d ($%X)",RT_ArrayGetDim1Max(ARRAY),RT_ArrayGetDim1Max(ARRAY))
        RT_DebugF("AttribCnt       = %d",RT_ArrayGetAttrib(ARRAY,-1))
        RT_DebugF("StrAttribCnt    = %d",RT_ArrayGetStrAttrib(ARRAY,-1))
        RT_DebugF("StrAttribMaxLen = %d",RT_ArrayGetStrAttrib(ARRAY,-2))
        RT_DebugF("IDCnt           = %d", RT_ArrayGetID(ARRAY,-1))
        STOP=RT_TimerHP()
        RT_DebugF("Total Time Type=%d (%s) = %.3f secs",Type,RT_ArrayTypeName(Type),STOP-TYPE_START)
    }
    (DELETE) ? RT_FileDelete(ARRAY) : NOP
    TOTAL_STOP=RT_TimerHP()
    SSS=RT_String("SCRIPT TOTAL TIME = %.3f secs\nERRORS=%d",TOTAL_STOP-TOTAL_START,ERR)
    RT_DebugF(SSS)
"""

HasGScript ? GScript(GS) : Eval(GS) # Use GSCript if installed (loaded plugs override builtin)

return colorbars().KillAudio.RT_SubTitle(SSS)
