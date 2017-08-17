/****************************************************************************\
**               GOB v1.o1 Little Diary program FOR 8col Wbench             **
**                         Code : Maffia / Nerve Axis                       **
\****************************************************************************/

->FOLD HISTORY
/********************************[ History ]*********************************\
**                                                                          **
** Author: Maffia / Nerve Axis aka Matthew Bushell                          **
** 7. February 1996                                                         **
** Time: 19:15:52                                                           **
** E:Gob/gob.e                                                              **
** V1.00 - Original version                                                 **
** v1.o1 - Retrieved from HD Crash - Optimized, Conitnue Work               **
**       - Figured out how TO use STRING gadgets! Wheeyyyy!!                **
**       - Now Uses CASE instead of ELSEIF ALL the time!                    **
*****************************************************************************/
->FEND

->FOLD OPTS
/********************************[ Opts ]************************************/
OPT     OSVERSION=39        -> AGA Only
->FEND
->FOLD ENUMS
/********************************[ Enums ]***********************************/

ENUM    NONE,                     -> No Error <-
        ER_OPENLIB,               -> Fail to open needed Lib <-
        ER_SCREEN,                -> Cant open needed screen, Commonly no setpatch <-
        ER_VISUAL,                -> Cant get visual info <-
        ER_CONTEXT,               -> Cant get context <-
        ER_GADGET,                -> Cant create gadgets <-
        ER_WINDOW,                -> Cant open need window, lackof memory? <-
        ER_FILE,                  -> Cant load one or more needed game files <-
        ER_ALLOC,                 -> Cant alloc er something, i forget what. <-
        ER_MEM,                   -> Memory Err of some type <-
        ER_TEXT,
        ER_WB
->FEND
->FOLD CONSTS
/********************************[ Consts ]**********************************/

CONST   JAN=31,  -> How many days in each month?
        FEB=28,  ->  Needed, to draw calender
        MAR=31,
        APR=30,
        MAY=31,
        JUN=30,
        JUL=31,
        AUG=31,
        SEP=30,
        OCT=31,
        NOV=30,
        DCM=31
->FEND
->FOLD MODULES
/********************************[ ModUles ]*********************************/

MODULE  'intuition/intuition',
        'intuition/screens',
        'intuition/gadgetclass',
        'gadtools',
        'reqtools',
        'libraries/reqtools',
        'libraries/gadtools',
        'exec/nodes',
        'tools/file',
        'tools/ilbm',
        'tools/ilbmdefs',
        'dos/dos',
        'exec/memory',
        'graphics/text',
        'oomodules/datetime'    -> Get date & time Module
->FEND
->FOLD OBJECTS
/********************************[ Objects ]*********************************/
OBJECT oPerson PRIVATE
    aName[20]:ARRAY OF CHAR                -> Name
    aHandle[20]:ARRAY OF CHAR              -> Handle
    aGroup[20]:ARRAY OF CHAR               -> Group STRING
    aAddr0[30]:ARRAY OF CHAR               -> Address line 0
    aAddr1[30]:ARRAY OF CHAR               -> Address line 1
    aAddr2[30]:ARRAY OF CHAR               -> Address line 2
    aAddr3[30]:ARRAY OF CHAR               -> Address line 3
    aPCode[10]:ARRAY OF CHAR               -> Postcode
    aTelNo[20]:ARRAY OF CHAR               -> Telno
    aEMail[20]:ARRAY OF CHAR               -> EMail Address
    aCom[80]:ARRAY OF CHAR                 -> Comment
ENDOBJECT

->FEND
->FOLD GLOBAL DEFS
/********************************[ Global DEFS ]*****************************/

DEF pWnd:PTR TO window,          -> Program Window
    calwnd:PTR TO window,       -> Calender Window
    phnwnd:PTR TO window,       -> PhoneBook Window
    glist,                      -> Gadget list
    scr:PTR TO screen,          -> Public screen
    visual = 0,                 -> Visual Information
    g:PTR TO gadget,            -> Gadgets
    g_abt:PTR TO gadget,        ->  About gadget
    g_tim:PTR TO gadget,        ->  Time & Calender gadget
    g_add:PTR TO gadget,        ->  Add new appointment
    g_mod:PTR TO gadget,        ->  Modify Database
    g_com:PTR TO gadget,        ->  Computer specs
    g_dsk:PTR TO gadget,        ->  Disk options
    g_vew:PTR TO gadget,        ->  View database
    g_adr:PTR TO gadget,        ->  Address Book
    topaz:PTR TO textattr,      -> Default text attribute
    infos=0,                    -> Which gadget?
    mes:PTR TO intuimessage,    -> Intuition message
    offy,                       -> offset
    type,                       -> type of gadget
    key=FALSE,                  -> Keypress?
    gadtool=FALSE,              -> Gadget?
    bmap,                       -> Bitmap variable
    ilbm,                       -> more GFX vars
    bmh:PTR TO bmhd,            -> Pointer to bitmap header
    pi:PTR TO picinfo,          -> Picture info for loading
    req:PTR TO rtfilerequester, -> ReqTools Var
    lString:LONG,               -> Global stringbuffer.
    bDebugMode = FALSE          -> DebugMode ?
->FEND

->FOLD PROC MAIN
/*******************************[ PROC Main ]********************************/

PROC main() HANDLE
    IF StrCmp(arg,'-D') THEN bDebugMode:=TRUE
    setup()
    REPEAT
        infos:=0               -> Initialize CASE Variable
        wait4message(pWnd)      -> Wait FOR an Intui Message
        SELECT infos
            CASE 1
                 RtEZRequestA({helptxt},'_oh!',0,0,[RT_UNDERSCORE,"_",
                                                    RT_TEXTATTR,topaz,
                                                    RT_WINDOW,pWnd])
            CASE 2
                 shrink()
                 calender()
                 expand()
            CASE 8
                 shrink()
                 phonebook()
                 expand()
        ENDSELECT
    UNTIL infos=10
    Raise(NONE)
EXCEPT
    closedown()
    IF exception>0 THEN WriteF('NVX Standard Error #\s \n',
    ListItem(['000:No Error!',
              '001:OpenLib',
              '002:Screen',
              '003:Visual',
              '004:Context',
              '005:Gadget',
              '006:Window',
              '007:File',
              '008:Alloc',
              '009:Menus',
              '010:Font',
              '011:Workbench'],exception))
ENDPROC
->FEND
->FOLD PROC SETUP
/*******************************[ PROC Setup ]*******************************/

PROC setup()
    IF (ilbm:=ilbm_New('data/face1.iff',0))=NIL THEN Raise(ER_FILE)
    ilbm_LoadPicture(ilbm,[ILBML_GETBITMAP,{bmap},0])
    pi:=ilbm_PictureInfo(ilbm)
    bmh:=pi.bmhd
    ilbm_Dispose(ilbm)
    IF (topaz:=['topaz.font',8,0,FPF_ROMFONT]:textattr)=NIL THEN Raise(ER_TEXT)
    IF (gadtoolsbase:=OpenLibrary('gadtools.library',37))=NIL THEN Raise(ER_OPENLIB)
    IF (reqtoolsbase:=OpenLibrary('reqtools.library',37))=NIL THEN Raise(ER_OPENLIB)
    IF (req:=RtAllocRequestA(req,0))=NIL THEN Raise(ER_ALLOC)
    IF (scr:=LockPubScreen('Workbench'))=NIL THEN Raise(ER_WB)
    IF (visual:=GetVisualInfoA(scr,NIL))=NIL THEN Raise(ER_VISUAL)
    offy:=scr.wbortop+Int(scr.rastport+58)-10
    IF (g:=CreateContext({glist}))=NIL THEN Raise(ER_CONTEXT)
    IF (g:=CreateGadgetA(BUTTON_KIND,g,[530,8,84,20,'» qUIT «',topaz,10,16,visual,1]:newgadget,
        [NIL]))=NIL THEN Raise(ER_GADGET)
    IF (g:=CreateGadgetA(BUTTON_KIND,g,[530,30,84,20,'» pREFS «',topaz,9,16,visual,1]:newgadget,
        [GA_DISABLED,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
-> The buttons
    IF (g:=g_abt:=CreateGadgetA(BUTTON_KIND,g,[7,38,60,12,'aBOUT',topaz,1,16,visual,1]:newgadget,
        [NIL]))=NIL THEN Raise(ER_GADGET)
    IF (g:=g_tim:=CreateGadgetA(BUTTON_KIND,g,[71,38,60,12,'tIME &',topaz,2,16,visual,1]:newgadget,
        [GA_DISABLED,FALSE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (g:=g_add:=CreateGadgetA(BUTTON_KIND,g,[135,38,60,12,'aDD aPP',topaz,3,16,visual,1]:newgadget,
        [GA_DISABLED,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (g:=g_mod:=CreateGadgetA(BUTTON_KIND,g,[199,38,60,12,'mODIFY',topaz,4,16,visual,1]:newgadget,
        [GA_DISABLED,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (g:=g_com:=CreateGadgetA(BUTTON_KIND,g,[263,38,60,12,'cOMPUT',topaz,5,16,visual,1]:newgadget,
        [GA_DISABLED,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (g:=g_dsk:=CreateGadgetA(BUTTON_KIND,g,[327,38,60,12,'dISK',topaz,6,16,visual,1]:newgadget,
        [GA_DISABLED,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (g:=g_vew:=CreateGadgetA(BUTTON_KIND,g,[391,38,60,12,'vIEW',topaz,7,16,visual,1]:newgadget,
        [GA_DISABLED,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (g:=g_adr:=CreateGadgetA(BUTTON_KIND,g,[455,38,60,12,'aDDY',topaz,8,16,visual,1]:newgadget,
        [GA_DISABLED,FALSE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (pWnd:=OpenWindowTagList(NIL,
        [WA_LEFT,           0,
         WA_TOP,            11,
         WA_WIDTH,          640,
         WA_HEIGHT,         68,
         WA_IDCMP,          $24C077E,
         WA_FLAGS,          WFLG_ACTIVATE OR
                            WFLG_DRAGBAR OR
                            WFLG_GIMMEZEROZERO OR
                            WFLG_DEPTHGADGET OR
                            WFLG_CLOSEGADGET OR
                            WFLG_NEWLOOKMENUS,
         WA_CUSTOMSCREEN,   scr,
         WA_AUTOADJUST,     1,
         WA_GADGETS,        glist,
         WA_ACTIVATE,       TRUE,
         WA_RMBTRAP,        TRUE,
         WA_SCREENTITLE,    'GOB v1.o1 (c)1996 Maffia of Nerve Axis',
         WA_TITLE,          'GOB',
         NIL]))=NIL THEN Raise(ER_WINDOW)
    Gt_RefreshWindow(pWnd,NIL)
    DrawBevelBoxA(pWnd.rport,3,3,630,50,[GT_VISUALINFO,visual,
                                        GTBB_RECESSED,TRUE,
                                        GTBB_FRAMETYPE,BBFT_RIDGE,0])
    splat(0,0)
    splat(1,1)
    splat(2,2)
    splat(3,3)
    splat(4,4)
    splat(5,5)
    splat(6,6)
    splat(7,7)
ENDPROC
->FEND
->FOLD PROC CLOSEDOWN
/*******************************[ PROC Closedown ]***************************/

PROC closedown()
    IF bmap THEN ilbm_FreeBitMap(bmap)
    IF topaz THEN StripFont(topaz)
    IF gadtoolsbase THEN CloseLibrary(gadtoolsbase)
    IF scr THEN UnlockPubScreen(NIL,scr)
    IF pWnd THEN CloseWindow(pWnd)
    IF visual THEN FreeVisualInfo(visual)
    IF glist THEN FreeGadgets(glist)
ENDPROC
->FEND
->FOLD PROC SPLAT
/******************************[ PROC splat ]********************************/

PROC splat(ico,accross)

DEF k
    k:=(ico*64)
    accross:=(accross*64)+6
    BltBitMapRastPort(bmap,k,0,pWnd.rport,accross,5,64,32,$c0)
ENDPROC
->FEND
->FOLD PROC SHRINK
/******************************[ PROC shrink ]*******************************/

PROC shrink()
   CloseWindow(pWnd)
   IF (pWnd:=OpenWindowTagList(NIL,
        [WA_LEFT,           0,
         WA_TOP,            11,
         WA_WIDTH,          90,
         WA_HEIGHT,         25,
         WA_IDCMP,          $24C077E,
         WA_FLAGS,          WFLG_ACTIVATE OR
                            WFLG_DRAGBAR OR
                            WFLG_GIMMEZEROZERO OR
                            WFLG_DEPTHGADGET OR
                            WFLG_CLOSEGADGET OR
                            WFLG_NEWLOOKMENUS,
         WA_CUSTOMSCREEN,   scr,
         WA_AUTOADJUST,     1,
         WA_GADGETS,        glist,
         WA_ACTIVATE,       TRUE,
         WA_RMBTRAP,        TRUE,
         WA_SCREENTITLE,    'GOB v1.o1 (c)1996 Nerve Axis',
         WA_TITLE,          'GOB',
         NIL]))=NIL THEN Raise(ER_WINDOW)
    Gt_RefreshWindow(pWnd,NIL)
    PrintIText(pWnd.rport,[1,0,0,0,0,topaz,'zZZzzZzzZ',NIL]:intuitext,5,2)
ENDPROC
->FEND
->FOLD PROC EXPAND
/****************************[ PROC expand ]*********************************/

PROC expand()
    CloseWindow(pWnd)
    IF (pWnd:=OpenWindowTagList(NIL,
        [WA_LEFT,           0,
         WA_TOP,            11,
         WA_WIDTH,          640,
         WA_HEIGHT,         68,
         WA_IDCMP,          $24C077E,
         WA_FLAGS,          WFLG_ACTIVATE OR
                            WFLG_DRAGBAR OR
                            WFLG_GIMMEZEROZERO OR
                            WFLG_DEPTHGADGET OR
                            WFLG_CLOSEGADGET OR
                            WFLG_NEWLOOKMENUS,
         WA_CUSTOMSCREEN,   scr,
         WA_AUTOADJUST,     1,
         WA_GADGETS,        glist,
         WA_ACTIVATE,       TRUE,
         WA_RMBTRAP,        TRUE,
         WA_SCREENTITLE,    'GOB v1.o1 (c)1996 Nerve Axis',
         WA_TITLE,          'GOB',
         NIL]))=NIL THEN Raise(ER_WINDOW)
    Gt_RefreshWindow(pWnd,NIL)
    DrawBevelBoxA(pWnd.rport,3,3,630,50,[GT_VISUALINFO,visual,
                                        GTBB_RECESSED,TRUE,
                                        GTBB_FRAMETYPE,BBFT_RIDGE,0])
    splat(0,0)
    splat(1,1)
    splat(2,2)
    splat(3,3)
    splat(4,4)
    splat(5,5)
    splat(6,6)
    splat(7,7)
ENDPROC
->FEND
->FOLD PROC CALENDAR
/******************************[ PROC calender ]*****************************/

PROC calender()

DEF calglist,                   -> gadgets list
    calg:PTR TO gadget,         -> gadgets
    dtclass:PTR TO date_time,   -> Date & Time Variables for Calendar
    day,
    date,                       ->
    time,                       ->
    output[40]:STRING,          -> Output string for above
    dayno=1                     -> Day of the week

    IF (calg:=CreateContext({calglist}))=NIL THEN Raise(ER_CONTEXT)
    IF (calg:=CreateGadgetA(BUTTON_KIND,calg,[235,80,45,15,'Ok!',topaz,10,16,visual,1]:newgadget,
        [NIL]))=NIL THEN Raise(ER_GADGET)
    IF (calg:=CreateGadgetA(BUTTON_KIND,calg,[235,55,45,15,'Up!',topaz,1,16,visual,1]:newgadget,
        [NIL]))=NIL THEN Raise(ER_GADGET)
    IF (calwnd:=OpenWindowTagList(NIL,
        [WA_LEFT,           0,
         WA_TOP,            11,
         WA_WIDTH,          300,
         WA_HEIGHT,         155,
         WA_IDCMP,          $24C077E,
         WA_FLAGS,          WFLG_ACTIVATE OR
                            WFLG_DRAGBAR OR
                            WFLG_GIMMEZEROZERO OR
                            WFLG_DEPTHGADGET OR
                            WFLG_CLOSEGADGET OR
                            WFLG_NEWLOOKMENUS,
         WA_CUSTOMSCREEN,   scr,
         WA_AUTOADJUST,     1,
         WA_GADGETS,        calglist,
         WA_ACTIVATE,       TRUE,
         WA_RMBTRAP,        TRUE,
         WA_SCREENTITLE,    'GOB - Calender',
         WA_TITLE,          'GOB Cal 1',
         NIL]))=NIL THEN Raise(ER_WINDOW)
    DrawBevelBoxA(calwnd.rport,3,3,290,42,[GT_VISUALINFO,visual,
                                            GTBB_RECESSED,TRUE,
                                            GTBB_FRAMETYPE,BBFT_RIDGE,0])
    RectFill(calwnd.rport,6,5,288,42)
    BltBitMapRastPort(bmap,64,0,calwnd.rport,220,8,64,32,$c0)
    NEW dtclass
    day,date,time:=dtclass.date_time()
    IF (day[0]=77 AND day[1]=111 AND day[2]=110) THEN dayno:=1 -> Mon
    IF (day[0]=84 AND day[1]=117 AND day[2]=101) THEN dayno:=2 -> Tue
    IF (day[0]=87 AND day[1]=101 AND day[2]=100) THEN dayno:=3 -> Wed
    IF (day[0]=84 AND day[1]=104 AND day[2]=117) THEN dayno:=4 -> Thu
    IF (day[0]=70 AND day[1]=114 AND day[2]=114) THEN dayno:=5 -> Fri
    IF (day[0]=83 AND day[1]=97  AND day[2]=116) THEN dayno:=6 -> Sat
    IF (day[0]=83 AND day[1]=117 AND day[2]=110) THEN dayno:=7 -> Sun
    WriteF('\d:\d:\d = \c:\c:\c :Parts 1,2&3 So Dayno:\d\n',day[0],day[1],day[2],day[0],day[1],day[2],dayno)
    StringF(output,'Day..:\s',day)
    PrintIText(calwnd.rport,[1,0,0,0,0,topaz,output,NIL]:intuitext,15,10)
    StringF(output,'Date.:\s',date)
    PrintIText(calwnd.rport,[1,0,0,0,0,topaz,output,NIL]:intuitext,15,18)
    StringF(output,'Time.:\s',time)
    PrintIText(calwnd.rport,[1,0,0,0,0,topaz,output,NIL]:intuitext,15,26)
    drawcal(date,day,dayno)
    REPEAT
        day,date,time:=dtclass.date_time()
        RectFill(calwnd.rport,15,10,(16*8),34)
        StringF(output,'Day..:\s',day)
        PrintIText(calwnd.rport,[1,0,0,0,0,topaz,output,NIL]:intuitext,15,10)
        StringF(output,'Date.:\s',date)
        PrintIText(calwnd.rport,[1,0,0,0,0,topaz,output,NIL]:intuitext,15,18)
        StringF(output,'Time.:\s',time)
        PrintIText(calwnd.rport,[1,0,0,0,0,topaz,output,NIL]:intuitext,15,26)
        wait4message(calwnd)
    UNTIL (infos=10)
    END dtclass
    IF calwnd THEN CloseWindow(calwnd)
    IF calglist THEN FreeGadgets(calglist)
    infos:=0
ENDPROC
->FEND
->FOLD PROC DRAWCAL
/******************************[ PROC drawcal ]******************************/

PROC drawcal(date,day,dayn)

DEF dom[2]:STRING,
    val,
    n

    StrCopy(dom,date,2)
    val:=Val(dom)
    FOR n:=1 TO val
        dayn--
        IF dayn <= 0 THEN dayn:=7
        WriteF('#:\d - Dayn:\d - Val:\d\n',n,dayn,val)
    ENDFOR
    dayn++
    PrintIText(calwnd.rport,[1,0,0,0,0,topaz,'mon tue wed thu fri',NIL]:intuitext,5,50)
    PrintIText(calwnd.rport,[2,0,0,0,0,topaz,'sat sun',NIL]:intuitext,162,50)
    FOR n:=0 TO dayn
        BltBitMapRastPort(bmap,32,224,calwnd.rport,((n-1)*32),58,33,20,$c0)
    ENDFOR
    FOR n:=dayn TO 7
        BltBitMapRastPort(bmap,0,224,calwnd.rport,((n-1)*32),58,33,20,$c0)
        StringF(dom,'\d',(n-dayn)+1)
        PrintIText(calwnd.rport,[1,0,0,0,0,topaz,dom,NIL]:intuitext,((n-1)*32)+2,60)
    ENDFOR
    FOR n:=1 TO 7
        BltBitMapRastPort(bmap,0,224,calwnd.rport,((n-1)*32),71,33,20,$c0)
    ENDFOR
    FOR n:=1 TO 7
        BltBitMapRastPort(bmap,0,224,calwnd.rport,((n-1)*32),84,33,20,$c0)
    ENDFOR
        FOR n:=1 TO 7
        BltBitMapRastPort(bmap,0,224,calwnd.rport,((n-1)*32),97,33,20,$c0)
    ENDFOR
ENDPROC
->FEND
->FOLD PROC PHONEBOOK
/******************************[ PROC phonebook ]*****************************/

-> How DO i convert a STRING TO a LONG

PROC phonebook()

DEF phnglist,                   -> gadgets list
    phng:PTR TO gadget,         -> gadgets
    phngN:PTR TO gadget,        ->  Name
    phngH:PTR TO gadget,        ->  Handle
    phngG:PTR TO gadget,        ->  Group
    phng0:PTR TO gadget,        ->  Address0
    phng1:PTR TO gadget,        ->  Address1
    phng2:PTR TO gadget,        ->  Address2
    phng3:PTR TO gadget,        ->  Address3
    phngP:PTR TO gadget,        ->  PostCode
    phngT:PTR TO gadget,        ->  Telephone
    phngE:PTR TO gadget,        ->  EMail Address
    phngC:PTR TO gadget,        ->  Comment
    aPers[100]:ARRAY OF oPerson,-> The people
    ppointer=1,                 -> Person pointer
    lock,                       -> Datafile Lock
    mem,                        -> Memory Alloc
    memp1,                      -> Pointer TO position in above
    memp2,                      -> Ditto
    read,                       -> read?
    size,                       -> Size of datafile
    handle,                     -> handle
    info:fileinfoblock,         -> FIB
    aRecord[5]:ARRAY OF INT     -> How many records?

->----DEREKED----
->HOW TO SOLVE YOUR STRINGY PROBLEM.
->IT IS CAUSED BY YOUR USING THE SAME STRING FOR EACH PERSON. PERS[POINTER.SNAME
->IS NOT A STRING, BUT A POINTER TO A STRING. SO EVERY TIME YOU CHANGE
->STEMP YOU CHANGE ALL THE PERS[].SNAME BECAUSE THEY ALL POINT TO THE SAME
->PIECE OF MEMORY.
->I WOULD SUGGEST YOU CHANGE pers[].sName TO pers[].pName TO REMIND YOU THAT
->IT IS A POINTER AND NOT AN ARRAY OF CHARS.
->1)  WHEN YOU READ THE FILE INTO MEM, OR SHORTLY AFTER, GO THROUGH MEM[]
->    AND CHANGE ALL THE LF INTO NULLS.
->    E.G FOR (x = 0; x < size; x++) IF (mem[x] == 10) mem[x]=0;
->2)  Throw away sTemp
->3)  Change your UNTIL statement TO read
->        UNTIL (mem[memp2]=0) OR (memp2>=size)
->4)  SET your pers[pointer].sName := mem+memp1


    IF (phng:=CreateContext({phnglist}))=NIL THEN Raise(ER_CONTEXT)
    IF (phng:=phngN:=CreateGadgetA(STRING_KIND,phng,[20,10,170,15,'Name',topaz,1,2,visual,1]:newgadget,
        [GTST_STRING,'',
         GTST_MAXCHARS,20,
         GA_RELVERIFY,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=phngH:=CreateGadgetA(STRING_KIND,phng,[20,25,170,15,'Handle',topaz,2,2,visual,1]:newgadget,
        [GTST_STRING,'',
         GTST_MAXCHARS,20,
         GA_RELVERIFY,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=phngG:=CreateGadgetA(STRING_KIND,phng,[20,40,170,15,'Group',topaz,3,2,visual,1]:newgadget,
        [GTST_STRING,'',
         GTST_MAXCHARS,20,
         GA_RELVERIFY,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=phng0:=CreateGadgetA(STRING_KIND,phng,[20,55,260,15,'Address',topaz,4,2,visual,1]:newgadget,
        [GTST_STRING,'',
         GTST_MAXCHARS,30,
         GA_RELVERIFY,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=phng1:=CreateGadgetA(STRING_KIND,phng,[20,70,260,15,'',topaz,5,2,visual,1]:newgadget,
        [GTST_STRING,'',
         GTST_MAXCHARS,30,
         GA_RELVERIFY,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=phng2:=CreateGadgetA(STRING_KIND,phng,[20,85,260,15,'',topaz,6,2,visual,1]:newgadget,
        [GTST_STRING,'',
         GTST_MAXCHARS,30,
         GA_RELVERIFY,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=phng3:=CreateGadgetA(STRING_KIND,phng,[20,100,260,15,'',topaz,7,2,visual,1]:newgadget,
        [GTST_STRING,'',
         GTST_MAXCHARS,30,
         GA_RELVERIFY,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=phngP:=CreateGadgetA(STRING_KIND,phng,[20,115,260,15,'Post Code',topaz,8,2,visual,1]:newgadget,
        [GTST_STRING,'',
         GTST_MAXCHARS,10,
         GA_RELVERIFY,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=phngT:=CreateGadgetA(STRING_KIND,phng,[20,130,260,15,'Telephone',topaz,13,2,visual,1]:newgadget,
        [GTST_STRING,'',
         GTST_MAXCHARS,80,
         GA_RELVERIFY,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=phngE:=CreateGadgetA(STRING_KIND,phng,[20,145,260,15,'EMail',topaz,12,2,visual,1]:newgadget,
        [GTST_STRING,'',
         GTST_MAXCHARS,80,
         GA_RELVERIFY,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=phngC:=CreateGadgetA(STRING_KIND,phng,[20,160,260,15,'Comment',topaz,9,2,visual,1]:newgadget,
        [GTST_STRING,'',
         GTST_MAXCHARS,80,
         GA_RELVERIFY,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=CreateGadgetA(BUTTON_KIND,phng,[250,180,45,15,'Fin!',topaz,10,16,visual,1]:newgadget,
        [NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=CreateGadgetA(BUTTON_KIND,phng,[155,180,45,15,'«',topaz,11,16,visual,1]:newgadget,
        [NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=CreateGadgetA(BUTTON_KIND,phng,[200,180,45,15,'»',topaz,12,16,visual,1]:newgadget,
        [NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=CreateGadgetA(BUTTON_KIND,phng,[55,180,45,15,'New',topaz,13,16,visual,1]:newgadget,
        [NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=CreateGadgetA(BUTTON_KIND,phng,[100,180,45,15,'Kill',topaz,14,16,visual,1]:newgadget,
        [NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phnwnd:=OpenWindowTagList(NIL,
        [WA_LEFT,           0,
         WA_TOP,            11,
         WA_WIDTH,          400,
         WA_HEIGHT,         215,
         WA_IDCMP,          $24C077E,
         WA_FLAGS,          WFLG_ACTIVATE OR
                            WFLG_DRAGBAR OR
                            WFLG_GIMMEZEROZERO OR
                            WFLG_DEPTHGADGET OR
                            WFLG_NEWLOOKMENUS,
         WA_CUSTOMSCREEN,   scr,
         WA_AUTOADJUST,     1,
         WA_GADGETS,        phnglist,
         WA_ACTIVATE,       TRUE,
         WA_RMBTRAP,        TRUE,
         WA_SCREENTITLE,    'GOB (c)1996 Maffia of Nerve Axis',
         WA_TITLE,          'GOB PhoneBook.',
         NIL]))=NIL THEN Raise(ER_WINDOW)
    DrawBevelBoxA(phnwnd.rport,3,3,390,200,[GT_VISUALINFO,visual,
                                            GTBB_RECESSED,TRUE,
                                            GTBB_FRAMETYPE,BBFT_RIDGE,0])
    BltBitMapRastPort(bmap,384,0,phnwnd.rport,270,14,64,32,$c0)
    IF (lock:=Lock('gob.peeps',ACCESS_READ))=NIL
        RtEZRequestA('Couldnt Lock Datafile.','_oK',0,0,[RT_UNDERSCORE,"_",RTEZ_REQTITLE,'WiN GUI fILE cHOICE eRROR'])
    ELSE
        Examine(lock,info)
        size:=info.size
        UnLock(lock)
        IF (mem:=AllocVec(size,MEMF_PUBLIC))=NIL
           RtEZRequestA('Coldnt allocate enough memory.','_oK',0,0,[RT_UNDERSCORE,"_",RTEZ_REQTITLE,'WiN GUI mEMORY eRROR'])
        ELSE
           IF (handle:=Open('gob.peeps',MODE_OLDFILE))=NIL
              RtEZRequestA('Couldnt open selected file.','_oK',0,0,[RT_UNDERSCORE,"_",RTEZ_REQTITLE,'WiN GUI fILE cHOICE eRROR'])
              FreeVec(mem)
           ELSE
              IF (read:=Read(handle,mem,size))=NIL
                 RtEZRequestA('Couldnt read datafile.','_oK',0,0,[RT_UNDERSCORE,"_",RTEZ_REQTITLE,'WiN GUI fILE cHOICE eRROR'])
                 FreeVec(mem)
              ENDIF
           ENDIF
        ENDIF
    ENDIF
    IF handle THEN Close(handle)
    aRecord[0]:=mem[0]
    aRecord[1]:=mem[1]
    aRecord[2]:=mem[2]
    aRecord[3]:=mem[3]
    aRecord[0]:=aRecord[0]-48
    aRecord[1]:=aRecord[1]-48
    aRecord[2]:=aRecord[2]-48
    aRecord[3]:=aRecord[3]-48
    aRecord[4]:=((aRecord[0]*1000)+(aRecord[1]*100)+(aRecord[2]*10)+(aRecord[3]))
    memp2:=4       ->
    IF bDebugMode THEN WriteF('Reading \d Records\n',aRecord[4])
    FOR ppointer:=1 TO aRecord[4]
->Get name
        memp1:=(memp2+1)  -> SET first mempointer TO first letter of sName
        memp2:=memp1      -> SET second TO same point
        REPEAT            -> Find RETURN code - A4000 probs?
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0     -> SET NULL terminator in mem
        StringF(aPers[ppointer].aName,'\s',mem+memp1)
        Gt_SetGadgetAttrsA(phngN,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aName,NIL])
->Get Handle
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aHandle,'\s',mem+memp1)
        Gt_SetGadgetAttrsA(phngH,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aHandle,NIL])
->Get Group
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aGroup,'\s',mem+memp1)
        Gt_SetGadgetAttrsA(phngG,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aGroup,NIL])
->Get Address 0
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aAddr0,'\s',mem+memp1)
        Gt_SetGadgetAttrsA(phng0,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aAddr0,NIL])
->Get Address 1
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aAddr1,'\s',mem+memp1)
        Gt_SetGadgetAttrsA(phng1,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aAddr1,NIL])
->Get Address 2
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aAddr2,'\s',mem+memp1)
        Gt_SetGadgetAttrsA(phng2,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aAddr2,NIL])
->Get Address 3
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aAddr3,'\s',mem+memp1)
        Gt_SetGadgetAttrsA(phng3,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aAddr3,NIL])
->Get PCode
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aPCode,'\s',mem+memp1)
        Gt_SetGadgetAttrsA(phngP,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aPCode,NIL])
->Get Comment
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aCom,'\s',mem+memp1)
        Gt_SetGadgetAttrsA(phngC,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aCom,NIL])
->Done 1 Person.
    ENDFOR
    FreeVec(mem)
    ppointer--
    REPEAT
        wait4message(phnwnd)
        SELECT infos
               CASE 1
                   StringF(aPers[ppointer].aName,'\s',lString)
                   IF bDebugMode THEN WriteF('Name:\s\n',aPers[ppointer].aName)
               CASE 2
                   StringF(aPers[ppointer].aHandle,'\s',lString)
                   IF bDebugMode THEN WriteF('Name:\s\n',aPers[ppointer].aHandle)
               CASE 3
                   StringF(aPers[ppointer].aGroup,'\s',lString)
                   IF bDebugMode THEN WriteF('Name:\s\n',aPers[ppointer].aGroup)
               CASE 4
                   StringF(aPers[ppointer].aAddr0,'\s',lString)
                   IF bDebugMode THEN WriteF('Name:\s\n',aPers[ppointer].aAddr0)
               CASE 5
                   StringF(aPers[ppointer].aAddr1,'\s',lString)
                   IF bDebugMode THEN WriteF('Name:\s\n',aPers[ppointer].aAddr1)
               CASE 6
                   StringF(aPers[ppointer].aAddr2,'\s',lString)
                   IF bDebugMode THEN WriteF('Name:\s\n',aPers[ppointer].aAddr2)
               CASE 7
                   StringF(aPers[ppointer].aAddr3,'\s',lString)
                   IF bDebugMode THEN WriteF('Name:\s\n',aPers[ppointer].aAddr3)
               CASE 8
                   StringF(aPers[ppointer].aPCode,'\s',lString)
                   IF bDebugMode THEN WriteF('Name:\s\n',aPers[ppointer].aPCode)
               CASE 9
                   StringF(aPers[ppointer].aCom,'\s',lString)
                   IF bDebugMode THEN WriteF('Name:\s\n',aPers[ppointer].aCom)
               CASE 11
                   ppointer--
                   IF ppointer<1 THEN ppointer:=1
                   IF bDebugMode
                      WriteF('\s\n',aPers[ppointer].aName)
                      WriteF('\s\n',aPers[ppointer].aHandle)
                      WriteF('\s\n',aPers[ppointer].aGroup)
                      WriteF('\s\n',aPers[ppointer].aAddr0)
                      WriteF('\s\n',aPers[ppointer].aAddr1)
                      WriteF('\s\n',aPers[ppointer].aAddr2)
                      WriteF('\s\n',aPers[ppointer].aAddr3)
                      WriteF('\s\n',aPers[ppointer].aPCode)
                      WriteF('\s\n',aPers[ppointer].aCom)
                   ENDIF

                   Gt_SetGadgetAttrsA(phngN,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aName,NIL])
                   Gt_SetGadgetAttrsA(phngH,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aHandle,NIL])
                   Gt_SetGadgetAttrsA(phngG,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aGroup,NIL])
                   Gt_SetGadgetAttrsA(phng0,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aAddr0,NIL])
                   Gt_SetGadgetAttrsA(phng1,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aAddr1,NIL])
                   Gt_SetGadgetAttrsA(phng2,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aAddr2,NIL])
                   Gt_SetGadgetAttrsA(phng3,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aAddr3,NIL])
                   Gt_SetGadgetAttrsA(phngP,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aPCode,NIL])
                   Gt_SetGadgetAttrsA(phngC,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aCom,NIL])
               CASE 12
                   ppointer++
                   IF ppointer>aRecord[4] THEN ppointer:=aRecord[4]
                   IF bDebugMode
                      WriteF('\s\n',aPers[ppointer].aName)
                      WriteF('\s\n',aPers[ppointer].aHandle)
                      WriteF('\s\n',aPers[ppointer].aGroup)
                      WriteF('\s\n',aPers[ppointer].aAddr0)
                      WriteF('\s\n',aPers[ppointer].aAddr1)
                      WriteF('\s\n',aPers[ppointer].aAddr2)
                      WriteF('\s\n',aPers[ppointer].aAddr3)
                      WriteF('\s\n',aPers[ppointer].aPCode)
                      WriteF('\s\n',aPers[ppointer].aCom)
                   ENDIF
                   Gt_SetGadgetAttrsA(phngN,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aName,NIL])
                   Gt_SetGadgetAttrsA(phngH,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aGroup,NIL])
                   Gt_SetGadgetAttrsA(phngG,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aHandle,NIL])
                   Gt_SetGadgetAttrsA(phng0,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aAddr0,NIL])
                   Gt_SetGadgetAttrsA(phng1,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aAddr1,NIL])
                   Gt_SetGadgetAttrsA(phng2,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aAddr2,NIL])
                   Gt_SetGadgetAttrsA(phng3,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aAddr3,NIL])
                   Gt_SetGadgetAttrsA(phngP,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aPCode,NIL])
                   Gt_SetGadgetAttrsA(phngC,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aCom,NIL])
               CASE 13
                   aRecord[4]++
                   ppointer:=aRecord[4]
                   IF bDebugMode
                      WriteF('\s\n',aPers[ppointer].aName)
                      WriteF('\s\n',aPers[ppointer].aHandle)
                      WriteF('\s\n',aPers[ppointer].aGroup)
                      WriteF('\s\n',aPers[ppointer].aAddr0)
                      WriteF('\s\n',aPers[ppointer].aAddr1)
                      WriteF('\s\n',aPers[ppointer].aAddr2)
                      WriteF('\s\n',aPers[ppointer].aAddr3)
                      WriteF('\s\n',aPers[ppointer].aPCode)
                      WriteF('\s\n',aPers[ppointer].aCom)
                   ENDIF
                   Gt_SetGadgetAttrsA(phngN,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aName,NIL])
                   Gt_SetGadgetAttrsA(phngH,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aGroup,NIL])
                   Gt_SetGadgetAttrsA(phngG,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aHandle,NIL])
                   Gt_SetGadgetAttrsA(phng0,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aAddr0,NIL])
                   Gt_SetGadgetAttrsA(phng1,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aAddr1,NIL])
                   Gt_SetGadgetAttrsA(phng2,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aAddr2,NIL])
                   Gt_SetGadgetAttrsA(phng3,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aAddr3,NIL])
                   Gt_SetGadgetAttrsA(phngP,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aPCode,NIL])
                   Gt_SetGadgetAttrsA(phngC,phnwnd,NIL,[GTST_STRING,aPers[ppointer].aCom,NIL])
        ENDSELECT
    UNTIL (infos=10)
    IF phnwnd THEN CloseWindow(phnwnd)
    IF phnglist THEN FreeGadgets(phnglist)
    infos:=0    -> Reinitialize the gadget variable
/*
    Fix add new item
    change name TO relative 1
    add fields FOR email address & telephone number
    cry
    DO save data option
    okay?
*/

ENDPROC
->FEND
->FOLD PROC WAIT4MESSAGE
/******************************[ PROC wait4message ]*************************/

PROC wait4message(winda:PTR TO window)
  DEF g:PTR TO gadget,
      gstr:PTR TO stringinfo

    type:=0
    key:=FALSE
    gadtool:=FALSE
    lString:=0
   REPEAT
    IF mes:=Gt_GetIMsg(winda.userport)
      type:=mes.class
      IF type=IDCMP_MENUPICK
        infos:=mes.code
      ELSEIF type=IDCMP_RAWKEY
        infos:=mes.code
        key:=TRUE
      ELSEIF type=IDCMP_VANILLAKEY
        infos:=mes.code
      ELSEIF (type=IDCMP_GADGETDOWN)
        g:=mes.iaddress
        infos:=g.gadgetid
        gadtool:=TRUE
      ELSEIF (type=IDCMP_GADGETUP)
        g:=mes.iaddress
        infos:=g.gadgetid
        gstr:=g.specialinfo
        gadtool:=TRUE
        lString:=gstr.buffer
      ELSEIF type=IDCMP_REFRESHWINDOW
        Gt_BeginRefresh(winda)
        Gt_EndRefresh(winda,TRUE)
        type:=0
      ELSEIF type<>IDCMP_CLOSEWINDOW
        type:=0
      ENDIF
      Gt_ReplyIMsg(mes)
    ELSE
      Wait(-1)
    ENDIF
   UNTIL type<>0
ENDPROC
->FEND

->FOLD INCLUDES
/***********************[ Includes ]*****************************************/
helptxt:    INCBIN 'help.txt'
blank:      INCBIN 'blank.txt'
/***************************************************************************/
->FEND

->FOLD VERSION
CHAR '$VER: GOB 1.01 (07.02.96)'
->FEND
