;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DHMI_SSV_CS    
;* 
;* PURPOSE:
;*      THIS PROGRAM DISPLAYS A WIDGET ALLOWING SPECIFICATION OF THE REQUIRED PARAMETERS 
;*      TO LAUNCH THE SSV CLOUD SCREENING
;*
;* CALLING SEQUENCE:
;*      DHMI_SSV_CS
;*
;* INPUTS:
;*      NONE
;*
;* KEYWORDS:
;*      GROUP_LEADER - THE ID OF ANOTHER WIDGET TO BE USED AS THE GROUP LEADER
;*      VERBOSE      - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      NONE
;*
;* COMMON BLOCKS:
;*      DHMI_DATABASE - CONTAINS THE DATABASE DATA FOR THE DIMITRI HMI
;*
;* MODIFICATION HISTORY:
;*      01 NOV 2013 - C MAZERAN - DIMITRI-2 V1.0
;*
;* VALIDATION HISTORY:
;*      01 NOV 2013 - C MAZERAN - LINUX 64-BIT IDL 8.2 NOMINAL COMPILATION AND OPERATION       
;*
;**************************************************************************************
;**************************************************************************************

PRO DHMI_SSV_CS_START,EVENT

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_SSVCS_INFO, /NO_COPY

;---------------------------
; RETRIEVE ALL PARAMETERS

  IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS->START: RETRIEVING PARAMETERS FROM WIDGET FIELDS' 
  DHMI_SSVCS_INFO.REGION->GETPROPERTY,  VALUE=REGION
  DHMI_SSVCS_INFO.SENSOR->GETPROPERTY,  VALUE=SENSOR
  DHMI_SSVCS_INFO.PROC->GETPROPERTY,    VALUE=PROC
  DHMI_SSVCS_INFO.STARTD->GETPROPERTY,  VALUE=STARTD
  DHMI_SSVCS_INFO.STOPD->GETPROPERTY,   VALUE=STOPD
  DHMI_SSVCS_INFO.OFOLDER->GETPROPERTY, VALUE=OFOLDER
  DHMI_SSVCS_INFO.RIP->GETPROPERTY,     VALUE=ROIPERCENT
  SSV_BAND = DHMI_SSVCS_INFO.BAND
  DHMI_SSVCS_INFO.WAV->GETPROPERTY,  VALUE=SSV_WAV
  IF DHMI_SSVCS_INFO.CURRENT_BUTTON_SKIP EQ DHMI_SSVCS_INFO.DHMI_SSVCS_TLB_SKIP1 THEN SKIP = 1 ELSE SKIP = 0

;---------------------------
; CHECK USER VALUES

  IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS->START: CHECKING USER PARAMETERS'
  NUM='[0123456789]'
  PATTERN=''
  FOR I=0, 7 DO PATTERN=PATTERN+NUM
  IF ( (NOT STRMATCH(STARTD,PATTERN)) OR (NOT STRMATCH(STOPD,PATTERN)) ) THEN BEGIN
    MSG = ['INPUT ERROR']
    MSG = [MSG, 'BAD START AND/OR STOP DATE']
    TEMP = DIALOG_MESSAGE(MSG,/INFORMATION,/CENTER)
    GOTO, SSV_ERR
  ENDIF

;---------------------------
; FORMAT START AND STOP DATES

  DATES = [STARTD,STOPD]
  DEC_DATES = FLTARR(2)
  FOR I=0, 1 DO BEGIN
     YEAR  = FLOAT(STRMID(DATES[I],0,4))
     MONTH = FLOAT(STRMID(DATES[I],4,2))
     DAY   = FLOAT(STRMID(DATES[I],6,2))
     DOY   = JULDAY(MONTH,DAY,YEAR)-JULDAY(1,0,YEAR)
     IF YEAR MOD 4 EQ 0 THEN DIY = 366.0 ELSE DIY = 365.0
     DEC_DATES[I]=YEAR+DOY/DIY
  ENDFOR
  DEC_DATES[1]+=23./(DIY*24.)+59./(DIY*60.*24.)+59./(DIY*60.*60.*24.)

;---------------------------
; SORT OUT OUTPUT FOLDER NAME
 
  IF OFOLDER EQ 'AUTO' THEN BEGIN
  IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS->START: CREATING OUTPUTFOLDER NAME'
    DATE        = SYSTIME(/UTC)
    MNTHS       = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC']
    RES         = WHERE(MNTHS EQ STRUPCASE(STRMID(DATE,4,3)))+1
    IF RES LE 9 THEN RES = '0'+STRTRIM(STRING(RES),2) ELSE RES = STRTRIM(STRING(RES),2)
    DD = FIX(STRMID(DATE,8,2)) LE 9 ?  '0'+STRMID(DATE,9,1):STRMID(DATE,8,2)
    DATE        = STRMID(DATE,20,4)+RES+DD
    OFOLDER  = DHMI_SSVCS_INFO.MAIN_OUTPUT+REGION+'_'+DATE+'_SSV_CS_'+SENSOR+'_'+PROC
  ENDIF ELSE OFOLDER = DHMI_SSVCS_INFO.MAIN_OUTPUT+STRJOIN(STRSPLIT(OFOLDER,' ',/EXTRACT),'_')

;---------------------------
; CHECK OUTPUT FOLDER 

  IF FILE_TEST(OFOLDER,/DIRECTORY) EQ 1 THEN BEGIN
    MSG = ['OUTPUT FOLDER ALREADY EXISTS','OVERWRITE DATA?']
    MSG = DIALOG_MESSAGE(MSG,/QUESTION,/CENTER)
    IF STRCMP(STRUPCASE(MSG),'NO') EQ 1 THEN BEGIN
      OFOLDER  = OFOLDER+'_1'
      I = 2
      SCHECK = 0
      WHILE SCHECK EQ 0 DO BEGIN
        
        OFOLDER = STRSPLIT(OFOLDER,'_',/EXTRACT)
        OFOLDER[N_ELEMENTS(OFOLDER)-1] = STRTRIM(STRING(I),2)
        OFOLDER = STRJOIN(OFOLDER,'_')
        
        IF FILE_TEST(OFOLDER,/DIRECTORY) EQ 0 THEN SCHECK = 1
        I++
      ENDWHILE
    ENDIF
  ENDIF

;--------------------------
; GET SCREEN DIMENSIONS FOR 
; CENTERING INFO WIDGET

  DIMS  = GET_SCREEN_SIZE()
  XSIZE = 200
  YSIZE = 60
  XLOC  = (DIMS[0]/2)-(XSIZE/2)
  YLOC  = (DIMS[1]/2)-(YSIZE/2)

  IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS->START: CREATING AN INFO WIDGET'
  INFO_WD = WIDGET_BASE(COLUMN=1, XSIZE=XSIZE, YSIZE=YSIZE, TITLE='Please Wait...',XOFFSET=XLOC,YOFFSET=YLOC)
  LBLTXT  = WIDGET_LABEL(INFO_WD,VALUE=' ')
  LBLTXT  = WIDGET_LABEL(INFO_WD,VALUE='Please wait,')
  LBLTXT  = WIDGET_LABEL(INFO_WD,VALUE='Processing...')
  WIDGET_CONTROL, INFO_WD, /REALIZE
  WIDGET_CONTROL, /HOURGLASS

;--------------------------
; SSV CLOUD SCREENING

  IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS->START: RUNNING SSV CLOUD SCREENING'  

  RES = SSV_CLOUD_SCREENING(OFOLDER,REGION,SENSOR,PROC,ROIPERCENT,DEC_DATES[0],DEC_DATES[1],SSV_BAND,$
                            SKIP=SKIP, VERBOSE=DHMI_SSVCS_INFO.IVERBOSE)
 
  IF RES NE 1 THEN BEGIN
   MSG = ['DIMITRI SSV_CS:','ERROR DURING SSV CLOUD SCREENING']
   TMP = DIALOG_MESSAGE(MSG,/INFORMATION,/CENTER)
   GOTO, SSV_ERR
  ENDIF

;--------------------------
; DESTROY INFO WIDGET AND RETURN 
; TO SSV_CS WIDGET

  SSV_ERR:
  IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS->START: DESTROYING INFO WIDGET AND RETURNING'
  IF N_ELEMENTS(INFO_WD) GT 0 THEN WIDGET_CONTROL,INFO_WD,/DESTROY
  NO_SELECTION:
  WIDGET_CONTROL, EVENT.TOP, SET_UVALUE=DHMI_SSVCS_INFO, /NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_SSV_CS_EXIT,EVENT

;--------------------------
; RETRIEVE WIDGET INFORMATION

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_SSVCS_INFO, /NO_COPY
  IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS->EXIT: DESTROYING OBJECTS'

;--------------------------
; DESTROY OBJECTS

  OBJ_DESTROY,DHMI_SSVCS_INFO.OFOLDER
  OBJ_DESTROY,DHMI_SSVCS_INFO.REGION
  OBJ_DESTROY,DHMI_SSVCS_INFO.SENSOR
  OBJ_DESTROY,DHMI_SSVCS_INFO.PROC
  OBJ_DESTROY,DHMI_SSVCS_INFO.STARTD
  OBJ_DESTROY,DHMI_SSVCS_INFO.STOPD
  OBJ_DESTROY,DHMI_SSVCS_INFO.RIP
  OBJ_DESTROY,DHMI_SSVCS_INFO.WAV

;--------------------------
; DESTROY THE WIDGET

  IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS->EXIT: DESTROYING SSV CS WIDGET'
  WIDGET_CONTROL,EVENT.TOP,/DESTROY

END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_SSV_CS_SKIP,EVENT

COMMON DHMI_DATABASE

;--------------------------
; GET EVENT AND WIDGET INFO

  WIDGET_CONTROL, EVENT.TOP, GET_UVALUE=DHMI_SSVCS_INFO, /NO_COPY

;---------------------
; UPDATE CURRENT_BUTTON WITH SELECTION

  IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS->SKIP: UPDATING CURRENT BUTTON SELECTION'
  DHMI_SSVCS_INFO.CURRENT_BUTTON_SKIP = EVENT.ID
  WIDGET_CONTROL, EVENT.TOP, SET_UVALUE=DHMI_SSVCS_INFO, /NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_SSV_CS_SETUP_CHANGE,EVENT

COMMON DHMI_DATABASE
  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_SSVCS_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,   GET_UVALUE=ACTION

;--------------------------
; GET THE ACTION TYPE

  ACTION_TYPE = STRMID(ACTION,0,1)

;--------------------------
; UPDATE SENSOR VALUE

  IF ACTION_TYPE EQ 'V' THEN BEGIN
    IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS_SETUP->CHANGE: UPDATING THE SITE FIELD AND INDEX'
    CASE ACTION OF
      'VSITE<':DHMI_SSVCS_INFO.ISITE = DHMI_SSVCS_INFO.ISITE-1
      'VSITE>':DHMI_SSVCS_INFO.ISITE = DHMI_SSVCS_INFO.ISITE+1
    ENDCASE
    IF DHMI_SSVCS_INFO.ISITE LT 0 THEN DHMI_SSVCS_INFO.ISITE = DHMI_SSVCS_INFO.NASITE-1
    IF DHMI_SSVCS_INFO.ISITE EQ DHMI_SSVCS_INFO.NASITE THEN DHMI_SSVCS_INFO.ISITE = 0

    DHMI_SSVCS_INFO.REGION->SETPROPERTY, VALUE=DHMI_SSVCS_INFO.ASITE[DHMI_SSVCS_INFO.ISITE]

;--------------------------
; GET AVAILABLE SENSORS WITHIN REGION

    IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS_SETUP->CHANGE: UPDATING THE SENSOR FIELD AND INDEX'
    CSITE=DHMI_SSVCS_INFO.ASITE[DHMI_SSVCS_INFO.ISITE]

    TEMP = DHMI_DB_DATA.SENSOR[WHERE(STRMATCH(DHMI_DB_DATA.REGION,CSITE))]
    TEMP = TEMP[UNIQ(TEMP,SORT(TEMP))]
    DHMI_SSVCS_INFO.ASENS[0:N_ELEMENTS(TEMP)-1] = TEMP
    DHMI_SSVCS_INFO.NASENS = N_ELEMENTS(TEMP)
    DHMI_SSVCS_INFO.ISENS  = 0
    DHMI_SSVCS_INFO.SENSOR->SETPROPERTY, VALUE=DHMI_SSVCS_INFO.ASENS[DHMI_SSVCS_INFO.ISENS]

    GOTO,UPDATE_PROC

  ENDIF

;--------------------------
; UPDATE SENSOR VALUE

  IF ACTION_TYPE EQ 'S' THEN BEGIN
    IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS_SETUP->CHANGE: UPDATING THE SENSOR FIELD AND INDEX'
    CASE ACTION OF
      'SENS<':DHMI_SSVCS_INFO.ISENS = DHMI_SSVCS_INFO.ISENS-1
      'SENS>':DHMI_SSVCS_INFO.ISENS = DHMI_SSVCS_INFO.ISENS+1
    ENDCASE
    IF DHMI_SSVCS_INFO.ISENS LT 0 THEN DHMI_SSVCS_INFO.ISENS = DHMI_SSVCS_INFO.NASENS-1
    IF DHMI_SSVCS_INFO.ISENS EQ DHMI_SSVCS_INFO.NASENS THEN DHMI_SSVCS_INFO.ISENS = 0

    DHMI_SSVCS_INFO.SENSOR->SETPROPERTY, VALUE=DHMI_SSVCS_INFO.ASENS[DHMI_SSVCS_INFO.ISENS]

;--------------------------
; GET AVAILABLE PROC_VERS 
; FOR SITE AND SENSOR

    UPDATE_PROC:
    IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS_SETUP->CHANGE: UPDATING THE PROCESSING VERSION FIELD AND INDEX'
    CSITE = DHMI_SSVCS_INFO.ASITE[DHMI_SSVCS_INFO.ISITE]
    CSENS = DHMI_SSVCS_INFO.ASENS[DHMI_SSVCS_INFO.ISENS]

    TEMP = DHMI_DB_DATA.PROCESSING_VERSION[WHERE($
                                                 STRMATCH(DHMI_DB_DATA.REGION,CSITE) AND $
                                                 STRMATCH(DHMI_DB_DATA.SENSOR,CSENS))]
    TEMP = TEMP[UNIQ(TEMP,SORT(TEMP))]
    DHMI_SSVCS_INFO.APROC[0:N_ELEMENTS(TEMP)-1] = TEMP
    DHMI_SSVCS_INFO.NAPROC = N_ELEMENTS(TEMP)
    DHMI_SSVCS_INFO.IPROC  = 0
    DHMI_SSVCS_INFO.PROC->SETPROPERTY, VALUE=DHMI_SSVCS_INFO.APROC[DHMI_SSVCS_INFO.IPROC]

;--------------------------
; GET AVAILABLE BAND AND WAVREF

    IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS_SETUP->CHANGE: UPDATING THE BAND FIELD AND INDEX'
    CSENS = DHMI_SSVCS_INFO.ASENS[DHMI_SSVCS_INFO.ISENS]

    NBAND = (SENSOR_BAND_INFO(CSENS))[0]
    IBAND =0 
    FOR BB=0, NBAND -1 DO DHMI_SSVCS_INFO.AWAV[BB]= FLOAT(GET_SENSOR_BAND_NAME(CSENS,BB))
    DHMI_SSVCS_INFO.NBAND = NBAND 
    DHMI_SSVCS_INFO.IBAND = IBAND
    DHMI_SSVCS_INFO.BAND=DHMI_SSVCS_INFO.ABAND[DHMI_SSVCS_INFO.IBAND]
    DHMI_SSVCS_INFO.WAV->SETPROPERTY, VALUE=DHMI_SSVCS_INFO.AWAV[DHMI_SSVCS_INFO.IBAND]

    GOTO,UPDATE_DATE

  ENDIF

;--------------------------
; UPDATE PROC VALUE

  IF ACTION_TYPE EQ 'P' THEN BEGIN
    IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS_SETUP->CHANGE: UPDATING THE PROCESSING VERSION FIELD AND INDEX'
    CASE ACTION OF
      'PROC<':DHMI_SSVCS_INFO.IPROC = DHMI_SSVCS_INFO.IPROC-1
      'PROC>':DHMI_SSVCS_INFO.IPROC = DHMI_SSVCS_INFO.IPROC+1
    ENDCASE
    IF DHMI_SSVCS_INFO.IPROC LT 0 THEN DHMI_SSVCS_INFO.IPROC = DHMI_SSVCS_INFO.NAPROC-1
    IF DHMI_SSVCS_INFO.IPROC EQ DHMI_SSVCS_INFO.NAPROC THEN DHMI_SSVCS_INFO.IPROC = 0

    DHMI_SSVCS_INFO.PROC->SETPROPERTY, VALUE=DHMI_SSVCS_INFO.APROC[DHMI_SSVCS_INFO.IPROC]

;--------------------------
; GET AVAILABLE YEARS FOR SITE,
; SENSOR AND PROC VERSION

    UPDATE_DATE:
    IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS_SETUP->CHANGE: UPDATING THE DATE FIELD AND INDEX'
    CSITE = DHMI_SSVCS_INFO.ASITE[DHMI_SSVCS_INFO.ISITE]
    CSENS = DHMI_SSVCS_INFO.ASENS[DHMI_SSVCS_INFO.ISENS]
    CPROC = DHMI_SSVCS_INFO.APROC[DHMI_SSVCS_INFO.IPROC]

    ;TEMP = STRTRIM(STRING(DHMI_DB_DATA.YEAR[WHERE($
    ;                                              STRMATCH(DHMI_DB_DATA.REGION,CSITE)       AND $
    ;                                              STRMATCH(DHMI_DB_DATA.SENSOR,CSENS)       AND $
    ;                                              STRMATCH(DHMI_DB_DATA.PROCESSING_VERSION,CPROC))]),2)
    ;TEMP = TEMP[UNIQ(TEMP,SORT(TEMP))]
    ;DHMI_SSVCS_INFO.AYEAR[0:N_ELEMENTS(TEMP)] = [TEMP,'ALL']
    ;DHMI_SSVCS_INFO.NAYEAR = N_ELEMENTS(TEMP)+1
    ;DHMI_SSVCS_INFO.IYEAR=0
    ;DHMI_SSVCS_INFO.YEAR->SETPROPERTY, VALUE=DHMI_SSVCS_INFO.AYEAR[DHMI_SSVCS_INFO.IYEAR]

    ID=WHERE(STRMATCH(DHMI_DB_DATA.REGION,CSITE) AND STRMATCH(DHMI_DB_DATA.SENSOR,CSENS) AND STRMATCH(DHMI_DB_DATA.PROCESSING_VERSION,CPROC), NID)
    YEAR_MIN  = DHMI_DB_DATA.YEAR[ID[0]]
    MONTH_MIN = DHMI_DB_DATA.MONTH[ID[0]]
    DAY_MIN   = DHMI_DB_DATA.DAY[ID[0]]
    YEAR_MAX  = DHMI_DB_DATA.YEAR[ID[NID-1]]
    MONTH_MAX = DHMI_DB_DATA.MONTH[ID[NID-1]]
    DAY_MAX   = DHMI_DB_DATA.DAY[ID[NID-1]]
    DHMI_SSVCS_INFO.STARTD->SETPROPERTY, VALUE=STRTRIM(YEAR_MIN,2)+STRING(MONTH_MIN,FORMAT='(I02)')+STRING(DAY_MIN,FORMAT='(I02)')
    DHMI_SSVCS_INFO.STOPD->SETPROPERTY,  VALUE=STRTRIM(YEAR_MAX,2)+STRING(MONTH_MAX,FORMAT='(I02)')+STRING(DAY_MAX,FORMAT='(I02)')

  ENDIF

;--------------------------
; UPDATE YEAR VALUE

;  IF ACTION_TYPE EQ 'Y' THEN BEGIN
;    IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS_SETUP->CHANGE: UPDATING THE YEAR FIELD AND INDEX'
;    CASE ACTION OF
;      'YEAR<':DHMI_SSVCS_INFO.IYEAR = DHMI_SSVCS_INFO.IYEAR-1
;      'YEAR>':DHMI_SSVCS_INFO.IYEAR = DHMI_SSVCS_INFO.IYEAR+1
;    ENDCASE
;    IF DHMI_SSVCS_INFO.IYEAR LT 0 THEN DHMI_SSVCS_INFO.IYEAR = DHMI_SSVCS_INFO.NAYEAR-1
;    IF DHMI_SSVCS_INFO.IYEAR EQ DHMI_SSVCS_INFO.NAYEAR THEN DHMI_SSVCS_INFO.IYEAR = 0

;    DHMI_SSVCS_INFO.YEAR->SETPROPERTY, VALUE=DHMI_SSVCS_INFO.AYEAR[DHMI_SSVCS_INFO.IYEAR]
;  ENDIF

;--------------------------
; UPDATE BAND AND WAVREF VALUE

  IF ACTION_TYPE EQ 'B' THEN BEGIN
    IF DHMI_SSVCS_INFO.IVERBOSE EQ 1 THEN PRINT,'DHMI_SSV_CS_SETUP->CHANGE: UPDATING BAND FIELD AND INDEX'
    CASE ACTION OF
      'BAND<':DHMI_SSVCS_INFO.IBAND = DHMI_SSVCS_INFO.IBAND-1
      'BAND>':DHMI_SSVCS_INFO.IBAND = DHMI_SSVCS_INFO.IBAND+1
    ENDCASE
    IF DHMI_SSVCS_INFO.IBAND LT 0 THEN DHMI_SSVCS_INFO.IBAND = DHMI_SSVCS_INFO.NBAND-1
    IF DHMI_SSVCS_INFO.IBAND EQ DHMI_SSVCS_INFO.NBAND THEN DHMI_SSVCS_INFO.IBAND = 0

    DHMI_SSVCS_INFO.BAND=DHMI_SSVCS_INFO.ABAND[DHMI_SSVCS_INFO.IBAND]
    DHMI_SSVCS_INFO.WAV->SETPROPERTY, VALUE=DHMI_SSVCS_INFO.AWAV[DHMI_SSVCS_INFO.IBAND]
  ENDIF

 
;--------------------------
; RETRUN TO THE WIDGET

  WIDGET_CONTROL, EVENT.TOP, SET_UVALUE=DHMI_SSVCS_INFO, /NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_SSV_CS,GROUP_LEADER=GROUP_LEADER,VERBOSE=VERBOSE

COMMON DHMI_DATABASE

;--------------------------
; FIND MAIN DIMITRI FOLDER AND DELIMITER

  IF KEYWORD_SET(VERBOSE) THEN BEGIN
    PRINT,'DHMI_SSV_CS: STARTING SSV CS HMI ROUTINE'
    IVERBOSE=1
  ENDIF ELSE IVERBOSE=0
  IF STRUPCASE(!VERSION.OS_FAMILY) EQ 'WINDOWS' THEN WIN_FLAG = 1 ELSE WIN_FLAG = 0
 
  DL          = GET_DIMITRI_LOCATION('DL')
  MAIN_OUTPUT = GET_DIMITRI_LOCATION('OUTPUT')

;--------------------------
; DEFINE BASE PARAMETERS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_SSV_CS: DEFINING BASE PARAMETERS'
  CFIG_DATA = GET_DIMITRI_CONFIGURATION() 

  BASE_ROI  = CFIG_DATA.(1)[8] 
  BB_MAX    = 22

  OPT_BTN   = 60
  SML_BTNX  = 30
  SML_BTNY  = 10 
  SML_DEC   = 2
  SML_FSC_X = 7

;--------------------------
; GET LIST OF ALL OUTPUT FOLDERS, 
; SITES, SENSORS AND PROCESSING VERSIONS

  ASITES = DHMI_DB_DATA.REGION[UNIQ(DHMI_DB_DATA.REGION,SORT(DHMI_DB_DATA.REGION))]
  USENSS = DHMI_DB_DATA.SENSOR[UNIQ(DHMI_DB_DATA.SENSOR,SORT(DHMI_DB_DATA.SENSOR))]
  UPROCV = DHMI_DB_DATA.PROCESSING_VERSION[UNIQ(DHMI_DB_DATA.PROCESSING_VERSION,$
                                       SORT(DHMI_DB_DATA.PROCESSING_VERSION))]
;  UYEARS = DHMI_DB_DATA.YEAR[UNIQ(DHMI_DB_DATA.YEAR,SORT(DHMI_DB_DATA.YEAR))]

;--------------------------  
; SELECT FIRST SITE AND GET 
; AVAILABLE SENSORS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_SSV_CS: RETRIEVING AVAILABLE SITES AND SENSORS'
  ASENS = MAKE_ARRAY(N_ELEMENTS(USENSS),/STRING,VALUE='')
  APROC = MAKE_ARRAY(N_ELEMENTS(UPROCV),/STRING,VALUE='')
;  AYEAR = MAKE_ARRAY(N_ELEMENTS(UYEARS)+1,/STRING,VALUE='')

  NASITE = N_ELEMENTS(ASITES)
  CSITE  = ASITES[0]
  TEMP   = DHMI_DB_DATA.SENSOR[WHERE(DHMI_DB_DATA.REGION EQ CSITE)]
  TEMP   = TEMP[UNIQ(TEMP,SORT(TEMP))]
  ASENS[0:N_ELEMENTS(TEMP)-1] = TEMP
  NASENS = N_ELEMENTS(TEMP)
  CSENS  = ASENS[0]

;--------------------------  
; GET AVAILABLE PROCESSING VERSIONS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_SSV_CS: RETRIEVING AVAILABLE PROCESSING VERSIONS'
  TEMP    = DHMI_DB_DATA.PROCESSING_VERSION[WHERE(DHMI_DB_DATA.REGION EQ CSITE AND $
                                                  DHMI_DB_DATA.SENSOR EQ CSENS)]
  TEMP    = TEMP[UNIQ(TEMP,SORT(TEMP))]
  APROC[0:N_ELEMENTS(TEMP)-1] = TEMP
  NAPROC  = N_ELEMENTS(TEMP)
  CPROC   = APROC[0]

;--------------------------  
; GET AVAILABLE DATES

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_SSV_CS: RETRIEVING AVAILABLE DATES'
;  TEMP    = STRTRIM(STRING(DHMI_DB_DATA.YEAR[WHERE(DHMI_DB_DATA.REGION EQ CSITE AND $
;                                              DHMI_DB_DATA.SENSOR EQ CSENS AND $
;                                              DHMI_DB_DATA.PROCESSING_VERSION EQ CPROC)]),2)
;  TEMP    = TEMP[UNIQ(TEMP,SORT(TEMP))]
;  AYEAR[0:N_ELEMENTS(TEMP)] = [TEMP,'ALL']
;  CYEAR   = AYEAR[0]
;  NAYEAR  = N_ELEMENTS(TEMP)+1

  ID=WHERE(STRMATCH(DHMI_DB_DATA.REGION,CSITE) AND STRMATCH(DHMI_DB_DATA.SENSOR,CSENS) AND STRMATCH(DHMI_DB_DATA.PROCESSING_VERSION,CPROC), NID)
  YEAR_MIN  = DHMI_DB_DATA.YEAR[ID[0]]
  MONTH_MIN = DHMI_DB_DATA.MONTH[ID[0]]
  DAY_MIN   = DHMI_DB_DATA.DAY[ID[0]]
  YEAR_MAX  = DHMI_DB_DATA.YEAR[ID[NID-1]]
  MONTH_MAX = DHMI_DB_DATA.MONTH[ID[NID-1]]
  DAY_MAX   = DHMI_DB_DATA.DAY[ID[NID-1]]
  STARTD    = STRTRIM(YEAR_MIN,2)+STRING(MONTH_MIN,FORMAT='(I02)')+STRING(DAY_MIN,FORMAT='(I02)')
  STOPD     = STRTRIM(YEAR_MAX,2)+STRING(MONTH_MAX,FORMAT='(I02)')+STRING(DAY_MAX,FORMAT='(I02)')

;--------------------------  
; GET AVAILABLE BAND

  ABAND = INDGEN(BB_MAX)
  AWAV  = FLTARR(BB_MAX)
  NBAND = (SENSOR_BAND_INFO(CSENS))[0]
  FOR BB=0, NBAND -1 DO AWAV[BB]= FLOAT(GET_SENSOR_BAND_NAME(CSENS,BB))
  IBAND = 0
  BAND  = ABAND[IBAND]
  WAV   = AWAV[IBAND]

  ;ABAND=INTARR(BBREF_MAX)
  ;AWAVREF=STRARR(BBREF_MAX)
  ;IF CSENS EQ 'MODISA' THEN TEMP_SENS = 'MODISA_O' ELSE TEMP_SENS = CSENS
  
  ;NBAND=0
  ;FOR BB = 1, BBAND_MAX DO BEGIN
  ;   BAND = GET_SENSOR_BAND_INDEX(TEMP_SENS,BB)
  ;   IF BAND LT 0 THEN CONTINUE ELSE BEGIN
  ;     ABAND[NBAND]    = BAND
  ;     AWAVREF[NBAND]  = GET_SENSOR_BAND_NAME(CSENS,BAND)
  ;     IF BB EQ BASE_BBAND THEN BEGIN
  ;       CWAVREF = AWAVREF[NBAND]
  ;       BAND = BAND
  ;     ENDIF
  ;     NBAND++
  ;   ENDELSE
  ;ENDFOR
  ;NBAND = NBAND

;--------------------------
; DEFINE THE MAIN WIDGET 

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_SSV_CS: RETRIEVING SCREEN DIMENSIONS FOR WIDGET'
  DIMS  = GET_SCREEN_SIZE()
  IF WIN_FLAG THEN XSIZE = 425 ELSE XSIZE = 490
  YSIZE = 800
  XLOC  = (DIMS[0]/2)-(XSIZE/2)
  YLOC  = (DIMS[1]/2)-(YSIZE/2)

  DHMI_SSVCS_TLB = WIDGET_BASE(COLUMN=1,TITLE='DIMITRI V2.0: SSV CLOUD SCREENING SETUP',XSIZE=XSIZE,$
                                  XOFFSET=XLOC,YOFFSET=YLOC)
;--------------------------
; DEFINE WIDGET TO HOLD OUTPUTFOLDER,
; REGION, SENSOR AND CONFIGURATION

  DHMI_SSVCS_TLB_1 = WIDGET_BASE(DHMI_SSVCS_TLB,ROW=6, FRAME=1)
  DHMI_SSVCS_TLB_1_LBL = WIDGET_LABEL(DHMI_SSVCS_TLB_1,VALUE='CASE STUDY:')
  DHMI_SSVCS_TLB_1_LBL = WIDGET_LABEL(DHMI_SSVCS_TLB_1,VALUE='')
  DHMI_SSVCS_TLB_1_LBL = WIDGET_LABEL(DHMI_SSVCS_TLB_1,VALUE='')

  IF WIN_FLAG THEN DHMI_SSVCS_TLB_1_OFID = FSC_FIELD(DHMI_SSVCS_TLB_1,VALUE='AUTO',TITLE='FOLDER    :',OBJECT=OFOLDER) $
              ELSE DHMI_SSVCS_TLB_1_OFID = FSC_FIELD(DHMI_SSVCS_TLB_1,VALUE='AUTO',TITLE='FOLDER    :',OBJECT=OFOLDER) 
  DHMI_BLK      = WIDGET_LABEL(DHMI_SSVCS_TLB_1,VALUE='')
  DHMI_BLK      = WIDGET_LABEL(DHMI_SSVCS_TLB_1,VALUE='')

  IF WIN_FLAG THEN DHMI_SSVCS_TLB_1_RID = FSC_FIELD(DHMI_SSVCS_TLB_1,VALUE=CSITE,TITLE  ='REGION    :',OBJECT=REGION) $
              ELSE DHMI_SSVCS_TLB_1_RID = FSC_FIELD(DHMI_SSVCS_TLB_1,VALUE=CSITE,TITLE  ='REGION    :',OBJECT=REGION)
  DHMI_BLK      = WIDGET_BUTTON(DHMI_SSVCS_TLB_1,VALUE='<',UVALUE='VSITE<',EVENT_PRO='DHMI_SSV_CS_SETUP_CHANGE')
  DHMI_BLK      = WIDGET_BUTTON(DHMI_SSVCS_TLB_1,VALUE='>',UVALUE='VSITE>',EVENT_PRO='DHMI_SSV_CS_SETUP_CHANGE')  
  
  IF WIN_FLAG THEN DHMI_SSVCS_TLB_1_SID = FSC_FIELD(DHMI_SSVCS_TLB_1,VALUE=CSENS,TITLE  ='SENSOR    :',OBJECT=SENSOR) $
              ELSE DHMI_SSVCS_TLB_1_SID = FSC_FIELD(DHMI_SSVCS_TLB_1,VALUE=CSENS,TITLE  ='SENSOR    :',OBJECT=SENSOR)
  DHMI_BLK      = WIDGET_BUTTON(DHMI_SSVCS_TLB_1,VALUE='<',UVALUE='SENS<',EVENT_PRO='DHMI_SSV_CS_SETUP_CHANGE')
  DHMI_BLK      = WIDGET_BUTTON(DHMI_SSVCS_TLB_1,VALUE='>',UVALUE='SENS>',EVENT_PRO='DHMI_SSV_CS_SETUP_CHANGE')  

  IF WIN_FLAG THEN DHMI_SSVCS_TLB_1_PID = FSC_FIELD(DHMI_SSVCS_TLB_1,VALUE=CPROC,TITLE  ='PROCESSING:',OBJECT=PROC) $
              ELSE DHMI_SSVCS_TLB_1_PID = FSC_FIELD(DHMI_SSVCS_TLB_1,VALUE=CPROC,TITLE  ='PROCESSING:',OBJECT=PROC)
  DHMI_BLK      = WIDGET_BUTTON(DHMI_SSVCS_TLB_1,VALUE='<',UVALUE='PROC<',EVENT_PRO='DHMI_SSV_CS_SETUP_CHANGE')
  DHMI_BLK      = WIDGET_BUTTON(DHMI_SSVCS_TLB_1,VALUE='>',UVALUE='PROC>',EVENT_PRO='DHMI_SSV_CS_SETUP_CHANGE')  

  ;IF WIN_FLAG THEN DHMI_SSVCS_TLB_1_YID = FSC_FIELD(DHMI_SSVCS_TLB_1,VALUE=CYEAR,TITLE  ='YEAR      :',OBJECT=YEAR) $
  ;            ELSE DHMI_SSVCS_TLB_1_YID = FSC_FIELD(DHMI_SSVCS_TLB_1,VALUE=CYEAR,TITLE  ='YEAR      :',OBJECT=YEAR)
  ;DHMI_BLK      = WIDGET_BUTTON(DHMI_SSVCS_TLB_1,VALUE='<',UVALUE='YEAR<',EVENT_PRO='DHMI_SSV_CS_SETUP_CHANGE')
  ;DHMI_BLK      = WIDGET_BUTTON(DHMI_SSVCS_TLB_1,VALUE='>',UVALUE='YEAR>',EVENT_PRO='DHMI_SSV_CS_SETUP_CHANGE')  

  IF WIN_FLAG THEN DHMI_SSVCS_TLB_1_START = FSC_FIELD(DHMI_SSVCS_TLB_1,VALUE=STARTD,TITLE ='START DATE:',OBJECT=STARTD,DECIMAL=SML_DEC,XSIZE=8) $  
              ELSE DHMI_SSVCS_TLB_1_START = FSC_FIELD(DHMI_SSVCS_TLB_1,VALUE=STARTD,TITLE ='START DATE:',OBJECT=STARTD,DECIMAL=SML_DEC,XSIZE=8)
  IF WIN_FLAG THEN DHMI_SSVCS_TLB_1_STOP = FSC_FIELD(DHMI_SSVCS_TLB_1,VALUE=STOPD,TITLE ='STOP DATE:',OBJECT=STOPD,DECIMAL=SML_DEC,XSIZE=8) $  
              ELSE DHMI_SSVCS_TLB_1_STOP = FSC_FIELD(DHMI_SSVCS_TLB_1,VALUE=STOPD,TITLE ='STOP DATE:',OBJECT=STOPD,DECIMAL=SML_DEC,XSIZE=8)

       
;--------------------------
; DEFINE WIDGET TO HOLD  
; CLOUD AND ROI PARAMETERS

  DHMI_SSVCS_TLB_2       = WIDGET_BASE(DHMI_SSVCS_TLB,ROW=2,FRAME=1)
  DHMI_SSVCS_TLB_2_LBL   = WIDGET_LABEL(DHMI_SSVCS_TLB_2,VALUE='COVERAGE CRITERIA:')
  DHMI_SSVCS_TLB_2_LBL   = WIDGET_LABEL(DHMI_SSVCS_TLB_2,VALUE='')
  IF WIN_FLAG THEN DHMI_SSVCS_TLB_2_RIPID = FSC_FIELD(DHMI_SSVCS_TLB_2,VALUE=BASE_ROI,TITLE ='REGION %   :',OBJECT=RIP,DECIMAL=SML_DEC,XSIZE=SML_FSC_X) $  
              ELSE DHMI_SSVCS_TLB_2_RIPID = FSC_FIELD(DHMI_SSVCS_TLB_2,VALUE=BASE_ROI,TITLE ='REGION %   :',OBJECT=RIP,DECIMAL=SML_DEC,XSIZE=SML_FSC_X)

;--------------------------
; DEFINE WIDGET TO HOLD  
; SSV CS OPTIONS

  DHMI_SSVCS_TLB_3       = WIDGET_BASE(DHMI_SSVCS_TLB,COLUMN=1,FRAME=1)
  DHMI_SSVCS_TLB_3_LBL   = WIDGET_LABEL(DHMI_SSVCS_TLB_3,VALUE='SSV CLOUD SCREENING OPTIONS:', /ALIGN_LEFT)

  DHMI_SSVCS_TLB_PID     = WIDGET_BASE(DHMI_SSVCS_TLB_3,ROW=1)
  DHMI_SSVCS_TLB_LBL     = WIDGET_LABEL(DHMI_SSVCS_TLB_PID,VALUE='SKIP THE TRAINING STAGE:')
  DHMI_SSVCS_TLB_SKIP    = WIDGET_BASE(DHMI_SSVCS_TLB_PID,ROW=1,/EXCLUSIVE)
  DHMI_SSVCS_TLB_SKIP1   = WIDGET_BUTTON(DHMI_SSVCS_TLB_SKIP,VALUE='YES',EVENT_PRO='DHMI_SSV_CS_SKIP')
  DHMI_SSVCS_TLB_SKIP2   = WIDGET_BUTTON(DHMI_SSVCS_TLB_SKIP,VALUE='NO',EVENT_PRO='DHMI_SSV_CS_SKIP')
  WIDGET_CONTROL, DHMI_SSVCS_TLB_SKIP1, SET_BUTTON=1
  CURRENT_BUTTON_SKIP = DHMI_SSVCS_TLB_SKIP1

  DHMI_SSVCS_TLB_B     = WIDGET_BASE(DHMI_SSVCS_TLB_3,ROW=1)
  IF WIN_FLAG THEN DHMI_SSVCS_TLB_3_BRID = FSC_FIELD(DHMI_SSVCS_TLB_B,VALUE=WAV,TITLE    ='BAND (NM):',OBJECT=WAV,XSIZE=SML_FSC_X) $
              ELSE DHMI_SSVCS_TLB_3_BRID = FSC_FIELD(DHMI_SSVCS_TLB_B,VALUE=WAV,TITLE    ='BAND (NM):',OBJECT=WAV,XSIZE=SML_FSC_X)
  DHMI_BLK      = WIDGET_BUTTON(DHMI_SSVCS_TLB_B,VALUE='<',UVALUE='BAND<',EVENT_PRO='DHMI_SSV_CS_SETUP_CHANGE')
  DHMI_BLK      = WIDGET_BUTTON(DHMI_SSVCS_TLB_B,VALUE='>',UVALUE='BAND>',EVENT_PRO='DHMI_SSV_CS_SETUP_CHANGE')  

;--------------------------
; DEFINE WIDGET TO HOLD START  
; AND EXIT BUTTONS
  
  DHMI_SSVCS_TLB_6       = WIDGET_BASE(DHMI_SSVCS_TLB,ROW=1,/ALIGN_RIGHT)
  DHMI_SSVCS_TLB_6_BTN   = WIDGET_BUTTON(DHMI_SSVCS_TLB_6,VALUE='Start',XSIZE=OPT_BTN,EVENT_PRO='DHMI_SSV_CS_START')
  DHMI_SSVCS_TLB_6_BTN   = WIDGET_BUTTON(DHMI_SSVCS_TLB_6,VALUE='Exit',XSIZE=OPT_BTN, EVENT_PRO='DHMI_SSV_CS_EXIT')

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_SSV_CS: COMPLETED DEFINING WIDGET'
  IF NOT KEYWORD_SET(GROUP_LEADER) THEN GROUP_LEADER = DHMI_SSVCS_TLB
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_SSV_CS: STORING WIDGET INFO INTO STRUCTURE'
  DHMI_SSVCS_INFO = {$
                  IVERBOSE              : IVERBOSE,$
                  GROUP_LEADER          : GROUP_LEADER,$
                  MAIN_OUTPUT           : MAIN_OUTPUT,$
                  OFOLDER               : OFOLDER,$
                  REGION                : REGION,$
                  ASITE                 : ASITES,$
                  NASITE                : NASITE,$
                  ISITE                 : 0,$
                  SENSOR                : SENSOR,$
                  ASENS                 : ASENS,$
                  NASENS                : NASENS,$
                  ISENS                 : 0,$
                  PROC                  : PROC,$
                  APROC                 : APROC,$
                  NAPROC                : NAPROC,$
                  IPROC                 : 0,$
                  ;YEAR                  : YEAR,$
                  ;AYEAR                 : AYEAR,$
                  ;NAYEAR                : NAYEAR,$
                  ;IYEAR                 : 0,$
                  STARTD                : STARTD,$
                  STOPD                 : STOPD,$
                  RIP                   : RIP,$
                  CURRENT_BUTTON_SKIP   : CURRENT_BUTTON_SKIP,$
                  DHMI_SSVCS_TLB_SKIP1  : DHMI_SSVCS_TLB_SKIP1,$
                  DHMI_SSVCS_TLB_SKIP2  : DHMI_SSVCS_TLB_SKIP2,$ 
                  BAND                  : BAND,$
                  ABAND                 : ABAND,$
                  NBAND                 : NBAND,$
                  IBAND                 : 0,$
                  WAV                   : WAV,$
                  AWAV                  : AWAV}
                  
;--------------------------
; REALISE THE WIDGET AND REGISTER WITH THE XMANAGER

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DHMI_SSV_CS: REALISING THE WIDGET AND REGISTERING WITH THE XMANAGER'
  WIDGET_CONTROL,DHMI_SSVCS_TLB,/REALIZE,SET_UVALUE=DHMI_SSVCS_INFO,/NO_COPY,GROUP_LEADER=GROUP_LEADER
  XMANAGER,'DHMI_SSV_CS',DHMI_SSVCS_TLB

END