# DBase_Append_Test.Avs, Requires RT_Stats and GScript plugs, Needs DebugView (google) to view output

# Config
DB						= "DBASE.RDB"		# DBase FileName
RECORDS					= 10000				# Initial number of records in DBase
DELETE					= true
##################################
ERR=0

myName="DBase_Append_Test: "
IsAvsPlus=(FindStr(UCase(versionString),"AVISYNTH+")!=0)    HasGScript=RT_FunctionExist("GScript")
Assert(IsAvsPlus || HasGScript,RT_String("%sNeed either GScript or AVS+",myName))

GS="""
	SLEN=4078
	TYPESTRING=RT_String("bifs%dne",SLEN)
	RT_DebugF("DBase_Append_Test.Avs")
	RT_DBaseAlloc(DB,0,TYPESTRING)
	RT_DebugF("TYPESTRING   = %c%s%c",34,TYPESTRING,34)
	RT_DebugF("Records      = %d",RT_DBaseRecords(DB))
	RT_DebugF("RecordSize   = %d",RT_DBaseRecordSize(DB))
	RT_DebugF("RecordsMax   = %d ($%X)",RT_DBaseRecordsMax(DB),RT_DBaseRecordsMax(DB))
	FIELDS=RT_DBaseFields(DB)
	RT_DebugF("Fields       = %d",FIELDS)
	for(i=0,Fields - 1) {
		TYPE_S=RT_DBaseTypeName(RT_DBaseFieldType(DB,i))
		RT_DebugF("  %2d ) Type = %d(%6s) Size = %d",i,RT_DBaseFieldType(DB,i),TYPE_S,RT_DBaseFieldSize(DB,i))
	}
	RT_DebugF("Extending to %d records",RECORDS)
	RT_DBaseExtend(DB,RECORDS)
	RT_DebugF("Check Extended Init To Zero")
	vs_0 = False vs_1 = 0 vs_2 = 0.0 vs_3 = "" vs_4 = 0 vs_5 = 0.0
	for(record=0,RECORDS - 1 ) {
	vg_0=RT_DBaseGetField(DB,record,0)
	vg_1=RT_DBaseGetField(DB,record,1)
	vg_2=RT_DBaseGetField(DB,record,2)
	vg_3=RT_DBaseGetField(DB,record,3)
	vg_4=RT_DBaseGetField(DB,record,4)
	vg_5=RT_DBaseGetField(DB,record,5)
		if(!RT_VarIsSame(vs_0,vg_0) || !RT_VarIsSame(vs_1,vg_1) || !RT_VarIsSame(vs_2,vg_2) ||
				\ !RT_VarIsSame(vs_3,vg_3) || !RT_VarIsSame(vs_4,vg_4) || !RT_VarIsSame(vs_5,vg_5)) {
		RT_DebugF("ERROR_1, @ Record %d",record)
		ERR=ERR+1
		}
	}
	Try {RT_DBaseGetField(RT_DBaseRecords(DB),0) RT_DebugF("Init END Check FAILED")  ERR=ERR+1} catch (msg) {RT_DebugF("Init END Check Passed")}
	RT_DebugF("RT_DBaseSet")
	for(record=0,RECORDS - 1 ) {
		vs_0 = RT_BitTst(record,0)
		vs_1 = record
		vs_2 = Float(record)
		vs_3 = RT_StrPad("",SLEN,Chr((record % 25) + 65))
		vs_4 = RT_BitAnd(record,$FF)
		vs_5 = Float(record)
		RT_DBaseSet(DB,record,vs_0,vs_1,vs_2,vs_3,vs_4,vs_5)
	}
	RT_DebugF("RT_DBaseSet/Get Compare")
	for(record=0,RECORDS - 1 ) {
		vs_0 = RT_BitTst(record,0)
		vs_1 = record
		vs_2 = Float(record)
		vs_3 = RT_StrPad("",SLEN,Chr((record % 25) + 65))
		vs_4 = RT_BitAnd(record,$FF)
		vs_5 = Float(record)
	vg_0=RT_DBaseGetField(DB,record,0)
	vg_1=RT_DBaseGetField(DB,record,1)
	vg_2=RT_DBaseGetField(DB,record,2)
	vg_3=RT_DBaseGetField(DB,record,3)
	vg_4=RT_DBaseGetField(DB,record,4)
	vg_5=RT_DBaseGetField(DB,record,5)
		if(!RT_VarIsSame(vs_0,vg_0) || !RT_VarIsSame(vs_1,vg_1) || !RT_VarIsSame(vs_2,vg_2) ||
				\ !RT_VarIsSame(vs_3,vg_3) || !RT_VarIsSame(vs_4,vg_4) || !RT_VarIsSame(vs_5,vg_5)) {
		RT_DebugF("ERROR_2, @ Record %d",record)
		ERR=ERR+1
		}
	}
	RT_DebugF("RT_DBase Append()")
	for(i=RECORDS,RECORDS*2 - 1 ) {
		vs_0 = RT_BitTst(i,0)
		vs_1 = i
		vs_2 = Float(i)
		vs_3 = RT_StrPad("",SLEN,Chr((i % 25) + 65))
		vs_4 = RT_BitAnd(i,$FF)
		vs_5 = Float(i)
		RT_DBaseAppend(DB,vs_0,vs_1,vs_2,vs_3,vs_4,vs_5)
	}
	RT_DebugF("RT_DBaseAppend() Compare")
	for(i=RECORDS,RECORDS*2 - 1 ) {
		vs_0 = RT_BitTst(i,0)
		vs_1 = i
		vs_2 = Float(i)
		vs_3 = RT_StrPad("",SLEN,Chr((i % 25) + 65))
		vs_4 = RT_BitAnd(i,$FF)
		vs_5 = Float(i)
	vg_0=RT_DBaseGetField(DB,i,0)
	vg_1=RT_DBaseGetField(DB,i,1)
	vg_2=RT_DBaseGetField(DB,i,2)
	vg_3=RT_DBaseGetField(DB,i,3)
	vg_4=RT_DBaseGetField(DB,i,4)
	vg_5=RT_DBaseGetField(DB,i,5)
		if(!RT_VarIsSame(vs_0,vg_0) || !RT_VarIsSame(vs_1,vg_1) || !RT_VarIsSame(vs_2,vg_2) ||
				\ !RT_VarIsSame(vs_3,vg_3) || !RT_VarIsSame(vs_4,vg_4) || !RT_VarIsSame(vs_5,vg_5)) {
		RT_DebugF("ERROR_3, @ Record %d",record)
		ERR=ERR+1
		}
	}
	Try {RT_DBaseGetField(DB,RECORDS*2-1,5) RT_DebugF("FINAL_END_1 Check PASSED")} catch (msg) {RT_DebugF("FINAL_END_1 Check FAILED") ERR=ERR+1}
	Try {RT_DBaseGetField(DB,RECORDS*2,0)   RT_DebugF("FINAL_END_2 Check FAILED")  ERR=ERR+1} catch (msg) {RT_DebugF("FINAL_END_2 Check PASSED")}
	if(RT_DBaseRecords(DB) != RECORDS*2) {
		RT_DebugF("ERROR_4, RT_DBaseRecords INCORRECT")
		ERR=ERR+1
	}
	RT_DebugF("TYPESTRING   = %c%s%c",34,TYPESTRING,34)
	RT_DebugF("Records      = %d (Should be %d)",RT_DBaseRecords(DB),RECORDS*2)
	RT_DebugF("RecordSize   = %d",RT_DBaseRecordSize(DB))
	RT_DebugF("RecordsMax   = %d ($%X)",RT_DBaseRecordsMax(DB),RT_DBaseRecordsMax(DB))
	FIELDS=RT_DBaseFields(DB)
	RT_DebugF("Fields       = %d",FIELDS)
	for(i=0,Fields - 1) {
		TYPE_S=RT_DBaseTypeName(RT_DBaseFieldType(DB,i))
		RT_DebugF("  %2d ) Type = %d(%6s) Size = %d",i,RT_DBaseFieldType(DB,i),TYPE_S,RT_DBaseFieldSize(DB,i))
	}
	(DELETE) ? RT_FileDelete(DB) : NOP
	RT_DebugF("ALL DONE, ERRORS=%d",ERR)
"""

HasGScript ? GScript(GS) : Eval(GS) # Use GSCript if installed (loaded plugs override builtin)

colorbars.KillAudio.RT_Subtitle("ALL DONE, ERRORS=%d",ERR)
