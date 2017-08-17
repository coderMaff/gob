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
        'graphics/text'
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
    iLink:PTR TO INT                       -> Linked LIST node (DONT WORK!)
ENDOBJECT

->FEND
->FOLD GLOBAL DEFS
/********************************[ Global DEFS ]*****************************/

DEF phnwnd:PTR TO window,       -> PhoneBook Window
    scr:PTR TO screen,          -> Public screen
    visual = 0,                 -> Visual Information
    g:PTR TO gadget,            -> Gadgets
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
    bDebugMode = FALSE,         -> DebugMode ?
    phnglist,                   -> gadgets LIST
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
    gSG:PTR TO gadget,          -> Status Gadget
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
    aRecord[5]:ARRAY OF INT,    -> How many records?
    temp,
    aLink[100]:ARRAY OF INT     -> External Links  ;)

->FEND

->FOLD PROC MAIN
/*******************************[ PROC Main ]********************************/

PROC main() HANDLE

DEF  sTemp[40]:STRING,
     n

    IF StrCmp(arg,'-D') THEN bDebugMode:=TRUE
    setup()
    initlinks()
    loaddata()
    ppointer:=1
    dispperson(ppointer)
    StringF(sTemp,'\d of \d',ppointer,aRecord[4])
    showstatus(sTemp)      
    REPEAT
        wait4message(phnwnd)
        SELECT infos
               CASE 1
                   StringF(aPers[ppointer].aName,'\s',lString)
                   IF bDebugMode THEN WriteF('Name..:\s\n',aPers[ppointer].aName)
               CASE 2
                   StringF(aPers[ppointer].aHandle,'\s',lString)
                   IF bDebugMode THEN WriteF('Handle:\s\n',aPers[ppointer].aHandle)
               CASE 3
                   StringF(aPers[ppointer].aGroup,'\s',lString)
                   IF bDebugMode THEN WriteF('Group.:\s\n',aPers[ppointer].aGroup)
               CASE 4
                   StringF(aPers[ppointer].aAddr0,'\s',lString)
                   IF bDebugMode THEN WriteF('Addr0.:\s\n',aPers[ppointer].aAddr0)
               CASE 5
                   StringF(aPers[ppointer].aAddr1,'\s',lString)
                   IF bDebugMode THEN WriteF('Addr1.:\s\n',aPers[ppointer].aAddr1)
               CASE 6
                   StringF(aPers[ppointer].aAddr2,'\s',lString)
                   IF bDebugMode THEN WriteF('Addr2.:\s\n',aPers[ppointer].aAddr2)
               CASE 7
                   StringF(aPers[ppointer].aAddr3,'\s',lString)
                   IF bDebugMode THEN WriteF('Addr3.:\s\n',aPers[ppointer].aAddr3)
               CASE 8
                   StringF(aPers[ppointer].aPCode,'\s',lString)
                   IF bDebugMode THEN WriteF('PCode.:\s\n',aPers[ppointer].aPCode)
               CASE 9
                   StringF(aPers[ppointer].aTelNo,'\s',lString)
                   IF bDebugMode THEN WriteF('TelNo.:\s\n',aPers[ppointer].aTelNo)
               CASE 10
                   StringF(aPers[ppointer].aEMail,'\s',lString)
                   IF bDebugMode THEN WriteF('EMail.:\s\n',aPers[ppointer].aEMail)
               CASE 11
                   StringF(aPers[ppointer].aCom,'\s',lString)
                   IF bDebugMode THEN WriteF('Commen:\s\n',aPers[ppointer].aCom)
               CASE 13
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
                   dispperson(ppointer)
                   StringF(sTemp,'\d of \d',ppointer,aRecord[4])
                   showstatus(sTemp)
               CASE 14
                   IF (aLink[ppointer] <> -1) THEN  ppointer:=aLink[ppointer]
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
                   dispperson(ppointer)
                   StringF(sTemp,'\d of \d',ppointer,aRecord[4])
                   showstatus(sTemp) 
               CASE 15
                   temp:=aRecord[4]
                   temp++
                   aRecord[4]:=temp
                   ppointer:=aRecord[4]
                   aLink[(ppointer-1)]:=ppointer
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
                   dispperson(ppointer)
                   StringF(sTemp,'New \d of \d',ppointer,aRecord[4])
                   showstatus(sTemp)  
               CASE 16
                   IF RtEZRequestA('Sure you wanna delete this entry?','_Yup|_Nah',0,0,[RT_UNDERSCORE,"_",
                                                                                        RT_TEXTATTR,topaz,
                                                                                        RT_WINDOW,phnwnd])
                      killentry()
                   ENDIF
               CASE 18
                    RtEZRequestA('What help could you possibly need?\n'+
                                 'its too simple as it is, just fill\n'+
                                 'in the fields  AND  THEN the progy\n'+
                                 'will save on exit. Kill Deletes ya\n'+
                                 'current Entry - Simple eh?','_Yup|Yeah|Um|Er|No',0,0,[RT_UNDERSCORE,"_",
                                                       RT_TEXTATTR,topaz,
                                                       RT_WINDOW,phnwnd])
               CASE 19
                    RtEZRequestA('» GOB by Maffia^NVX ! 96 ! «\n\n'+
                                 'ßeta Test v1.o1 - Internal Group Only\n\n'+
                                 'Oneday i`ll finish one prog before i\n'+
                                 'go AND start on the next... hehehehe\n'+
                                 ' -Post bug reports TO TOT OR 13th!- ','_oh!',0,0,[RT_UNDERSCORE,"_",
                                                       RT_TEXTATTR,topaz,
                                                       RT_WINDOW,phnwnd])
               CASE 20
                   FOR n:=1 TO 50
                       IF bDebugMode THEN WriteF('\d]Link:\d\n',n,aLink[n])
                   ENDFOR
        ENDSELECT
    UNTIL (infos=12)
    savedata()
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
->FOLD PROC KILLENTRY
PROC killentry()
     temp:=aRecord[4]
     temp--
     aRecord[4]:=temp
     aLink[(ppointer-1)]:=aLink[(ppointer)]
     aLink[(ppointer)]:=-1
     StringF(aPers[ppointer].aName,'\s','DELETED ENTRY')
     StringF(aPers[ppointer].aHandle,'\s','DELETED ENTRY')
     StringF(aPers[ppointer].aGroup,'\s','DELETED ENTRY')
     StringF(aPers[ppointer].aAddr0,'\s','DELETED ENTRY')
     StringF(aPers[ppointer].aAddr1,'\s','DELETED ENTRY')
     StringF(aPers[ppointer].aAddr2,'\s','DELETED ENTRY')
     StringF(aPers[ppointer].aAddr3,'\s','DELETED ENTRY')
     StringF(aPers[ppointer].aPCode,'\s','DELETED ENTRY')
     StringF(aPers[ppointer].aEMail,'\s','DELETED ENTRY')
     StringF(aPers[ppointer].aCom,'\s','DELETED ENTRY')
     dispperson(ppointer)
ENDPROC
->FEND
->FOLD PROC INITLINKS
PROC initlinks()
DEF n
    temp:=-1
    FOR n:=1 TO 99
        aLink[n]:=temp
        IF bDebugMode THEN WriteF('Link\d = \d\n',n,aLink[n])
    ENDFOR
ENDPROC
->FEND
->FOLD PROC LOADDATA
PROC loaddata()
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
->SET Link
        IF ppointer<>aRecord[4] THEN aLink[ppointer]:=(ppointer+1)
        IF bDebugMode THEN WriteF('Link:\d = \d\n',ppointer,aLink[ppointer])
->Get name
        memp1:=(memp2+1)  -> SET first mempointer TO first letter of sName
        memp2:=memp1      -> SET second TO same point
        REPEAT            -> Find RETURN code - A4000 probs?
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0     -> SET NULL terminator in mem
        StringF(aPers[ppointer].aName,'\s',mem+memp1)
->Get Handle
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aHandle,'\s',mem+memp1)
->Get Group
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aGroup,'\s',mem+memp1)
->Get Address 0
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aAddr0,'\s',mem+memp1)
->Get Address 1
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aAddr1,'\s',mem+memp1)
->Get Address 2
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aAddr2,'\s',mem+memp1)
->Get Address 3
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aAddr3,'\s',mem+memp1)
->Get PCode
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aPCode,'\s',mem+memp1)
->Get Telephone
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aTelNo,'\s',mem+memp1)
->Get EMail
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aEMail,'\s',mem+memp1)
->Get Comment
        memp1:=(memp2+1) -> Skip RETURN code AND SET pointer 1 again
        memp2:=memp1     -> SET pointer 2
        REPEAT
           memp2++
        UNTIL (mem[memp2]=10) OR (memp2>=size)
        mem[memp2]:=0
        StringF(aPers[ppointer].aCom,'\s',mem+memp1)
->Done 1 Person.
    ENDFOR
    FreeVec(mem)
    ppointer:=1
ENDPROC
->FEND
->FOLD PROC DISPPERSON
PROC dispperson(person)
     Gt_SetGadgetAttrsA(phngN,phnwnd,NIL,[GTST_STRING,aPers[person].aName,NIL])
     Gt_SetGadgetAttrsA(phngH,phnwnd,NIL,[GTST_STRING,aPers[person].aHandle,NIL])
     Gt_SetGadgetAttrsA(phngG,phnwnd,NIL,[GTST_STRING,aPers[person].aGroup,NIL])
     Gt_SetGadgetAttrsA(phng0,phnwnd,NIL,[GTST_STRING,aPers[person].aAddr0,NIL])
     Gt_SetGadgetAttrsA(phng1,phnwnd,NIL,[GTST_STRING,aPers[person].aAddr1,NIL])
     Gt_SetGadgetAttrsA(phng2,phnwnd,NIL,[GTST_STRING,aPers[person].aAddr2,NIL])
     Gt_SetGadgetAttrsA(phng3,phnwnd,NIL,[GTST_STRING,aPers[person].aAddr3,NIL])
     Gt_SetGadgetAttrsA(phngP,phnwnd,NIL,[GTST_STRING,aPers[person].aPCode,NIL])
     Gt_SetGadgetAttrsA(phngT,phnwnd,NIL,[GTST_STRING,aPers[person].aTelNo,NIL])
     Gt_SetGadgetAttrsA(phngE,phnwnd,NIL,[GTST_STRING,aPers[person].aEMail,NIL])
     Gt_SetGadgetAttrsA(phngC,phnwnd,NIL,[GTST_STRING,aPers[person].aCom,NIL])
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
    IF (phng:=phngT:=CreateGadgetA(STRING_KIND,phng,[20,130,260,15,'Telephone',topaz,9,2,visual,1]:newgadget,
        [GTST_STRING,'',
         GTST_MAXCHARS,20,
         GA_RELVERIFY,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=phngE:=CreateGadgetA(STRING_KIND,phng,[20,145,260,15,'EMail',topaz,10,2,visual,1]:newgadget,
        [GTST_STRING,'',
         GTST_MAXCHARS,20,
         GA_RELVERIFY,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=phngC:=CreateGadgetA(STRING_KIND,phng,[20,160,260,15,'Comment',topaz,11,2,visual,1]:newgadget,
        [GTST_STRING,'',
         GTST_MAXCHARS,80,
         GA_RELVERIFY,TRUE,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=CreateGadgetA(BUTTON_KIND,phng,[210,180,45,15,'Fin!',topaz,12,16,visual,1]:newgadget,
        [NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=CreateGadgetA(BUTTON_KIND,phng,[115,180,45,15,'«',topaz,13,16,visual,1]:newgadget,
        [NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=CreateGadgetA(BUTTON_KIND,phng,[160,180,45,15,'»',topaz,14,16,visual,1]:newgadget,
        [NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=CreateGadgetA(BUTTON_KIND,phng,[15,180,45,15,'New',topaz,15,16,visual,1]:newgadget,
        [NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=CreateGadgetA(BUTTON_KIND,phng,[60,180,45,15,'Kill',topaz,16,16,visual,1]:newgadget,
        [NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=gSG:=CreateGadgetA(TEXT_KIND,phng,[260,180,120,15,'',topaz,17,16,visual,1]:newgadget,
        [GTTX_TEXT,'GOB - NerveAxis 96',
         GTTX_BORDER,1,
         GTTX_JUSTIFICATION,GTJ_CENTER,NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=CreateGadgetA(BUTTON_KIND,phng,[350,15,30,15,'H',topaz,18,16,visual,1]:newgadget,
        [NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=CreateGadgetA(BUTTON_KIND,phng,[350,35,30,15,'A',topaz,19,16,visual,1]:newgadget,
        [NIL]))=NIL THEN Raise(ER_GADGET)
    IF (phng:=CreateGadgetA(BUTTON_KIND,phng,[290,20,30,15,'?',topaz,20,16,visual,1]:newgadget,
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
ENDPROC
->FEND
->FOLD PROC CLOSEDOWN
/*******************************[ PROC Closedown ]***************************/

PROC closedown()
    IF bmap THEN ilbm_FreeBitMap(bmap)
    IF topaz THEN StripFont(topaz)
    IF gadtoolsbase THEN CloseLibrary(gadtoolsbase)
    IF scr THEN UnlockPubScreen(NIL,scr)
    IF phnwnd THEN CloseWindow(phnwnd)
    IF visual THEN FreeVisualInfo(visual)
    IF phnglist THEN FreeGadgets(phnglist)
ENDPROC
->FEND
->FOLD PROC SPLAT
/******************************[ PROC splat ]********************************/

PROC splat(ico,accross)

DEF k
    k:=(ico*64)
    accross:=(accross*64)+6
    BltBitMapRastPort(bmap,k,0,phnwnd.rport,accross,5,64,32,$c0)
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
->FOLD PROC SAVEDATA
PROC savedata()

DEF prefile,               -> file on disk
    iLoopCounter = 0,
    number[4]:STRING

    IF (prefile:=Open('gob.peeps',MODE_NEWFILE))
        StringF(number,'\z\d[4]',aRecord[4])
        Write(prefile,number,StrLen(number))   -> Should always have a length of four
        iLoopCounter:=1
        REPEAT
            IF bDebugMode THEN WriteF('[\d]LoopCounter - [\d]Link \n',iLoopCounter,aLink[iLoopCounter])
            Write(prefile,'\n',1)
            IF StrCmp('',aPers[iLoopCounter].aName)
                Write(prefile,'   ',3)
            ELSE
                Write(prefile,aPers[iLoopCounter].aName,StrLen(aPers[iLoopCounter].aName))
            ENDIF
            Write(prefile,'\n',1)
            IF StrCmp('',aPers[iLoopCounter].aHandle)
                Write(prefile,'   ',3)
            ELSE
                Write(prefile,aPers[iLoopCounter].aHandle,StrLen(aPers[iLoopCounter].aHandle))
            ENDIF
            Write(prefile,'\n',1)
            IF StrCmp('',aPers[iLoopCounter].aGroup)
                Write(prefile,'   ',3)
            ELSE
                Write(prefile,aPers[iLoopCounter].aGroup,StrLen(aPers[iLoopCounter].aGroup))
            ENDIF
            Write(prefile,'\n',1)
            IF StrCmp('',aPers[iLoopCounter].aAddr0)
                Write(prefile,'   ',3)
            ELSE
                Write(prefile,aPers[iLoopCounter].aAddr0,StrLen(aPers[iLoopCounter].aAddr0))
            ENDIF
            Write(prefile,'\n',1)
            IF StrCmp('',aPers[iLoopCounter].aAddr1)
                Write(prefile,'   ',3)
            ELSE
                Write(prefile,aPers[iLoopCounter].aAddr1,StrLen(aPers[iLoopCounter].aAddr1))
            ENDIF
            Write(prefile,'\n',1)
            IF StrCmp('',aPers[iLoopCounter].aAddr2)
                Write(prefile,'   ',3)
            ELSE
                Write(prefile,aPers[iLoopCounter].aAddr2,StrLen(aPers[iLoopCounter].aAddr2))
            ENDIF
            Write(prefile,'\n',1)
            IF StrCmp('',aPers[iLoopCounter].aAddr3)
               Write(prefile,'   ',3)
            ELSE
               Write(prefile,aPers[iLoopCounter].aAddr3,StrLen(aPers[iLoopCounter].aAddr3))
            ENDIF
            Write(prefile,'\n',1)
            IF StrCmp('',aPers[iLoopCounter].aPCode)
               Write(prefile,'   ',3)
            ELSE
               Write(prefile,aPers[iLoopCounter].aPCode,StrLen(aPers[iLoopCounter].aPCode))
            ENDIF
            Write(prefile,'\n',1)
            IF StrCmp('',aPers[iLoopCounter].aTelNo)
                Write(prefile,'   ',3)
            ELSE
                Write(prefile,aPers[iLoopCounter].aTelNo,StrLen(aPers[iLoopCounter].aTelNo))
            ENDIF
            Write(prefile,'\n',1)
            IF StrCmp('',aPers[iLoopCounter].aEMail)
                Write(prefile,'   ',3)
            ELSE
                Write(prefile,aPers[iLoopCounter].aEMail,StrLen(aPers[iLoopCounter].aEMail))
            ENDIF
            Write(prefile,'\n',1)
            IF StrCmp('',aPers[iLoopCounter].aCom)
                Write(prefile,'   ',3)
            ELSE
                Write(prefile,aPers[iLoopCounter].aCom,StrLen(aPers[iLoopCounter].aCom))
            ENDIF
            iLoopCounter:=aLink[iLoopCounter]
        UNTIL (iLoopCounter=-1) OR (iLoopCounter>99)
        Close(prefile)
        IF bDebugMode THEN WriteF('Written \d of \d  Records in \d Loops',ppointer,aRecord[4],iLoopCounter)
    ELSE
        Raise(ER_FILE)
    ENDIF      

ENDPROC
->FEND
->FOLD PROC SHOWSTATUS
PROC showstatus(text)
        Gt_SetGadgetAttrsA(gSG,phnwnd,NIL,[GTTX_TEXT,text,NIL])
ENDPROC
->FEND

->FOLD VERSION
CHAR '$VER: GOBPHONE 1.01 (11.02.96)'
->FEND

->FOLD NOTES

-> How DO i convert a STRING TO a LONG

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

-> iLink (item LL) becomes corruptlinks change TO 12 14 12. Weird!

->FEND
