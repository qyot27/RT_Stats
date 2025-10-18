TITLE="RT_Stats Timing Test"
RUNS = 5			# Number of runs of each function, slowest and fastest discarded, timed on average of remainder
NFRAMES=1000		# Number of Frames to use from Source Clip

#AVISource("F:\V\StarWars.avi")
Colorbars(Width=720,pixel_type="YV12")

Trim(0,NFRAMES-1).KillAudio()

# Function names for Display only
Names="
	RT_YankChain
	YPlaneMin
	RT_YPlaneMin
	YPlaneMax
	RT_YPlaneMax
	YPlaneMinMaxDif
	RT_YPlaneMinMaxDif
	YPlaneMedian
	RT_YPlaneMedian
	AverageLuma
	RT_AverageLuma
	Avisynth_ALL
	RT_Avisynth_ALL
	RT_ALL
"

TESTS=14	# Total number of test incl RT_Yankchain

myName="RT_YStats_TestTimer: "
IsAvsPlus=(FindStr(UCase(versionString),"AVISYNTH+")!=0)    HasGScript=RT_FunctionExist("GScript")
Assert(IsAvsPlus || HasGScript,RT_String("%sNeed either GScript or AVS+",myName))


GS="""
    TESTS=Min(14,TESTS)
	Function Test_00(clip c){c for(i=0,framecount-1){current_frame=i RT_YankChain(Last)} return c}
	Function Test_01(clip c){c for(i=0,framecount-1){current_frame=i YPlaneMin(Last)} return c}
	Function Test_02(clip c){c for(i=0,framecount-1){current_frame=i RT_YPlaneMin(Last)} return c}
	Function Test_03(clip c){c for(i=0,framecount-1){current_frame=i YPlaneMax(Last)} return c}
	Function Test_04(clip c){c for(i=0,framecount-1){current_frame=i RT_YPlaneMax(Last)} return c}
	Function Test_05(clip c){c for(i=0,framecount-1){current_frame=i YPlaneMinMaxDifference(Last)} return c}
	Function Test_06(clip c){c for(i=0,framecount-1){current_frame=i RT_YPlaneMinMaxDifference(Last)} return c}
	Function Test_07(clip c){c for(i=0,framecount-1){current_frame=i YPlaneMedian(Last)} return c}
	Function Test_08(clip c){c for(i=0,framecount-1){current_frame=i RT_YPlaneMedian(Last)} return c}
	Function Test_09(clip c){c for(i=0,framecount-1){current_frame=i AverageLuma(Last)} return c}
	Function Test_10(clip c){c for(i=0,framecount-1){current_frame=i RT_AverageLuma(Last)} return c}
	Function Test_11(clip c){c for(i=0,framecount-1){current_frame=i \
			YPlaneMin(Last) YPlaneMax(Last) YPlaneMinMaxDifference(Last) YPlaneMedian(Last) AverageLuma(Last)} return c}
	Function Test_12(clip c){c for(i=0,framecount-1){current_frame=i RT_YStats(Last,flgs=$1F)} return c}		# As Test_11
	Function Test_13(clip c){c for(i=0,framecount-1){current_frame=i RT_YStats(Last,flgs=$7F,lo=0,hi=255)} return c}# As Test_12 + RT_Stdev+RT_YInRange
	Assert(RUNS>=3,"RUNS MUST be at least 3")
	Frames=FrameCount()
	YankAve=0.0												# Adjustment, will be subtracted from timings of non YankChain fns
	PStr=RT_String("%s\nTiming %dx%d(%d) runs on %d Frames (Total Frames=%d)",TITLE,TESTS,RUNS,TESTS*RUNS,NFRAMES,TESTS*RUNS*NFRAMES)
	RT_debugF("%s",Pstr)
	TStart=RT_TimerHP()										# Total Runtime Start
	For(Test=0,TESTS-1) {
		EStr="Test_"+RT_NumberString(Test,10,2)+"()"		# Func to EVALuate
		Times=""
		for(Run=1,RUNS) {
			s=RT_TimerHP()	Eval(EStr)	e=RT_TimerHP()	t = e-s		# Time Function
			Times=RT_TxtAddStr(Times,String(t))
#			RT_DebugF("%s %d] S=%6.2f E=%6.2f Time=%6.2f",EStr,Run,s,e,t)
		}
		Times=RT_TxtSort(Times,9)								# Sort Float strings ascending
		Ave = 0.0												#
		for(i=1,RUNS-2) {Ave=Ave+Value(RT_TxtGetLine(Times,i))}	# excluding slowest and fastest run
		Ave=Ave / Float(RUNS-2)									# Get Average Time, discarding slowest and fastest run
		FPS=Frames / Ave										# Ave FPS
		Title = RT_StrReplaceMulti(RT_TxtGetLine(Names,Line=Test+1)," "+Chr(10)+Chr(9),Chr(10)+Chr(10))	# Remove any SPACE + TAB
		Title = RT_StrPad(Title,18)																		# Align
		OStr=RT_String("%2d) %s %7.3fSecs : %9.2fFPS",Test+1,Title,ave,FPS)
		if(Test==0) {
			YankAve=Ave											# Average of basic GetFrame() ONLY time
			OStr=OStr+" :: Basic GetFrame() [ADJUSTMENT]"
		} else {
			AdjustedTime = Ave-YankAve
			AdjustedFPS = Frames / AdjustedTime
			OStr=RT_String("%s :: ADJUSTED %7.3fSecs %8.2fFPS",OStr,AdjustedTime,AdjustedFPS)
		}
		RT_DebugF("%s",OStr)
		PStr=RT_TxtAddStr(PStr,OStr)
	}
	TEnd=RT_TimerHP()												# Total Runtime End
	TTime=RT_String("Total Runtime = %7.2fMins",(TEnd-TStart)/60.0)
	RT_DebugF("%s",TTime)
	PStr=RT_TxtAddStr(PStr,TTime)
#	RT_DebugF("%s",PStr)
	SStr=RT_StrReplace(PStr,Chr(10),"\n")						# Convert Chr(10) to '\n' for correct Subtitle display
	SubTitle(Sstr,font="Courier New",size=16,lsp=0)
"""

HasGScript ? GScript(GS) : Eval(GS) # Use GSCript if installed (loaded plugs override builtin)

Return Last
