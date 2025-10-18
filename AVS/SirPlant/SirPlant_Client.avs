# SirPlant_Client.avs

Import(".\SirPlant.avs")

srcFN    = "S.avi"                # Source clip
repFN    = "R.AVI"                # Replace clip, Holds sequences that will replace those in source clip.
                                   # Sequences in Replace clip should be in SAME order as in source clip.
                                   # Clips must be same size, colorspace.
                                   # When splicing sequences with Prune (later) everything must be similar, audio etc,
                                   # also audio should both be normalized for similar voume levels, this detection stage ignores audio.
                                   # In later script, Prune will replace with both video and audio from replace clip.

srcARR      = SRCFN+".ARR"         # Name of RT_QwikScan FingerPrint Array
srcNxtARR   = SRCFN+".Next.ARR"    # Name of RT_QwikScan Locator Next Array (Next == scan forward Array)
repARR      = REPFN+".ARR"         # Name of RT_QwikScan FingerPrint Array
repNxtARR   = REPFN+".Next.ARR"    # Name of RT_QwikScan Locator Next Array (Next == scan forward Array)
#
src         = AVISource(srcFN)
rep         = AVISource(repFN)

#
Th          = 0.8                  # Default 0.9(not close matching frames maybe about 0.8)
Th2         = 0.65                 # Default 0.75(not close matching frames maybe about 0.65)
LUMATOL     = 16.0                 # Default 8.0(not close matching frames maybe up to about 16.0)
MatchLen    = 32                   # Default 60(Minimum sequence length that must match (frames). Default 60(not close matching frames maybe about 32)
SEARCHSTEP  = 4                    # Default MatchLen/4(not close matching frames maybe about 4) Frames to step after match failure.
STRICT      = False                # Default True=strict 1:1 matching of frames, False=allow slight mismatch ie missing/extra frames in replacement clip.
VERBOSITY   = 5                    # Debug output verbocity level, to DebugView.
INSMODE     = 1                    # Default 0=Replace Only, 1=Insert Extras Only, 2=Replace and Insert Extras
BLKW        = 64                   # default 64
BLKH        = 64                   # default BLKW
OLAPX       = 0                    # default BLKW/2
OLAPY       = 0                    # default BLKH/2

X           =  4                   # Avoid edge noise or logos. (All default 0)
Y           =  4
W           = -4
H           = -4

### !!! MUST SET TRUE FIRST, THEN FALSE to RUN !!! ###
CREATE      = True               # Set True to Create QWikScan arrays for SirPlant. (View progress in DebugView)


(CREATE) ? RT_QwikScanCreate(Src,srcARR,"",srcNxtARR,debug=true,x=X,y=Y,w=W,h=H) : NOP  # Only need create these once, Re-Create if change coords or clips.
(CREATE) ? RT_QwikScanCreate(rep,RepARR,"",repNxtARR,debug=true,x=X,y=Y,w=W,h=H) : NOP

### !!! USE DEBUGVIEW !!! ###
(!CREATE) ? SirPlant(src,rep,srcARR,srcNxtARR,repARR,repNxtARR,
                \ Th=Th,Th2=Th2,MatchLen=MatchLen,SearchStep=SEARCHSTEP,LumaTol=LUMATOL,Strict=STRICT,InsMode=INSMODE,VerBosity=VERBOSITY,
                \ Blkw=BLKW,BlkH=BLKH,OLapX=-OLAPX,OLapY=OLAPY
                \ ) : NOP

return Messageclip("All Done" + ((Create)?" Set Create=False":""))
