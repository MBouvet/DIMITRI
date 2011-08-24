;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DIMITRI_V2 
;* 
;* PURPOSE:
;*      THESE ROUTINES GENERATE THE MAIN DIMITRI HMI WIDGET WHICH ALLOWS INTERFACE 
;*      TO A NUMBER OF THE DIMITRI FUNCTIONS
;* 
;* CALLING SEQUENCE:
;*      DIMITRI_V2     
;* 
;* INPUTS:
;*      NONE     
;*
;* KEYWORDS:
;*      VERBOSE  - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      NONE
;*
;* COMMON BLOCKS:
;*      DHMI_DATABASE - CONTAINS THE DATABASE DATA FOR THE DIMITRI HMI
;*
;* MODIFICATION HISTORY:
;*        31 MAR 2011 - C KENT    - DIMITRI-2 V1.0
;*        17 MAY 2011 - C KENT    - ADDED PROCESS 2
;*        20 JUN 2011 - C KENT    - ADDED LINUX ACROBAT READER FOR SUM
;*        06 JUL 2011 - C KENT    - ADDED DATABASE COMMON BLOCK TO DIMITRI HMI
;*
;* VALIDATION HISTORY:
;*        14 APR 2011 - C KENT    - WINDOWS 32-BIT IDL 7.1 AND LINUX 64-BIT IDL 8.0 NOMINAL
;*                                  COMPILATION AND OPERATION        
;*
;**************************************************************************************
;**************************************************************************************

PRO DHMI_OBJECT_EVENT,EVENT

;---------------------------
; CATCH WIDGET RESIZE AND DO NOTHING

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.TOP,  SET_UVALUE=DHMI_INFO, /NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_BUTTON_EVENT,EVENT

;---------------------------
; RETRIEVE WIDGET INFORMATION

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,   GET_UVALUE=ACTION

;---------------------------
; CALL FUNCTIONALITY DPEENDING ON ACTION REQUEST

  IF DHMI_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_HMI->EVENT: STARTING FUNCTION FOR ACTION - ',ACTION 
  CASE ACTION OF
    'INGEST'          : DHMI_INGEST,              GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'NEW_SITE'        : DIMITRI_NEW_SITE_WD,      GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'DOWNLOAD'        : DIMITRI_DOWNLOAD_WD,      GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'CLOUD_SCREENING' : DHMI_CS_SETUP,            GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'PROCESS 1'       : DHMI_PROCESS_1,           GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'PROCESS 2'       : DHMI_PROCESS_2,           GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'VISU'            : DHMI_VISU,                GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'DATABASE_STATS'  : DIMITRI_DATABASE_STATS_WD,GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'RSR'             : DHMI_RSR,                 GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'OPTIONS'         : DHMI_CONFIGURATION,       GROUP_LEADER=EVENT.TOP,VERBOSE=DHMI_INFO.IVERBOSE
    'HELP'            : BEGIN
                          CASE STRUPCASE(!VERSION.OS_FAMILY) OF 
                            'WINDOWS':  SPAWN,DHMI_INFO.SUM,/HIDE,/NOWAIT
                            'UNIX':     SPAWN,STRING('acroread '+DHMI_INFO.SUM)
                          ENDCASE  
                        END
    'ABOUT'           : BEGIN
                          MSG   = [	'DIMITRI Version 2.0','Release Date: 21/07/2011'              ,$
                                    'IDL 7.0 Or Higher required','___________________',''             ,$
                                    'Email: ','=> Dimitri@argans.co.uk'                  ,$
                                    'Authors:','=> Marc Bouvet (ESA-ESTEC)','=> Chris Kent (ARGANS Ltd)']
	                        ABOUT = DIALOG_MESSAGE(MSG,/INFORMATION,TITLE = 'DIMITRI V2.0: ABOUT',/CENTER)
                        END
  ENDCASE

  WIDGET_CONTROL, EVENT.TOP,  SET_UVALUE=DHMI_INFO, /NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO DHMI_EXIT_EVENT,EVENT

;---------------------------
; DESTROY THE WIDGET

  WIDGET_CONTROL, EVENT.TOP,  GET_UVALUE=DHMI_INFO, /NO_COPY
  IF DHMI_INFO.IVERBOSE EQ 1 THEN PRINT,'DIMITRI_HMI->EXIT: DESTROYING THE WIDGET'
  WIDGET_CONTROL,EVENT.TOP,/DESTROY

END

;**************************************************************************************
;**************************************************************************************

PRO DIMITRI_V2,VERBOSE=VERBOSE

COMMON DHMI_DATABASE,DHMI_DB_DATA

  IF KEYWORD_SET(VERBOSE) THEN BEGIN
  IVERBOSE = 1 
  PRINT, 'DIMITRI_HMI: STARTING HMI GENERATION SCRIPT'
  ENDIF ELSE IVERBOSE=0
  SUM  = GET_DIMITRI_LOCATION('SUM')

;---------------------------
; SET THE WINDOW PROPERTIES

  MACHINE_WINDOW = !D.NAME
  CASE STRUPCASE(!VERSION.OS_FAMILY) OF 
    'WINDOWS':  SET_PLOT,'WIN'
    'UNIX':     SET_PLOT,'X'
  ENDCASE

;---------------------------
; LOAD PNG IMAGES

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: LOADING PNG IMAGES'
  TITLE     = GET_DIMITRI_LOCATION('TITLE_PNG')      
  INGEST    = GET_DIMITRI_LOCATION('INGEST_PNG')      
  PROCESS   = GET_DIMITRI_LOCATION('PROCESS_PNG')      
  VISUALISE = GET_DIMITRI_LOCATION('VISU_PNG')      

  READ_PNG,TITLE,TITLE_IMAGE
  READ_PNG,INGEST,INGEST_IMAGE
  READ_PNG,PROCESS,PROCESS_IMAGE
  READ_PNG,VISUALISE,VISUALISE_IMAGE
  DIMS = SIZE(TITLE_IMAGE)

;--------------------------
; LOAD THE DATABASE INTO A COMMON BLOCK

  DB_FILE = GET_DIMITRI_LOCATION('DATABASE')
  DB_TEMPLATE = GET_DIMITRI_TEMPLATE(1,/TEMPLATE)
  DHMI_DB_DATA = READ_ASCII(DB_FILE,TEMPLATE=DB_TEMPLATE)

;---------------------------
; DEFINE WIDGET PARAMETERS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: DEFINING WIDGET PARAMETERS'  
  MAIN_BTN_SIZE = 120
  SMLL_BTN_SIZE = 80

  SCR_DIMS = GET_SCREEN_SIZE()
  XSIZE = DIMS[2]+10
  YSIZE = 220
  XLOC  = (SCR_DIMS[0]/2)-(XSIZE/2)
  YLOC  = (YSIZE/2)
  
  BTEVENT = 'DHMI_BUTTON_EVENT'
  EXEVENT = 'DHMI_EXIT_EVENT'

;---------------------------
; DEFINE MAIN WIDGET BASE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: DEFINING MAIN HMI WIDGET'
  DTLB = WIDGET_BASE(XSIZE=XSIZE,YSIZE=YSIZE,XOFFSET=XLOC,YOFFSET=YLOC,TITLE='DIMITRI V2.0',COLUMN=1)

;---------------------------
; ADD DRAW_WIDGET FOR MAIN TITLE IMAGE

  DTLB_IMG = WIDGET_DRAW(DTLB,XSIZE=DIMS[2],YSIZE=DIMS[3]-3,SENSITIVE=0,RETAIN=2)
  DTLB_TOP = WIDGET_BASE(DTLB,COLUMN=7,/ALIGN_CENTER)

;---------------------------
; ADD INGEST IMAGE AND BUTTONS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: ADDING INGESTION OPTION BOX'
  DTLB_TOP_INGEST       = WIDGET_BASE(DTLB_TOP,COLUMN=1,FRAME=1)
  DTLB_TOP_INGEST_IMG_B = WIDGET_BASE(DTLB_TOP_INGEST)
  DTLB_TOP_INGEST_IMG   = WIDGET_DRAW(DTLB_TOP_INGEST_IMG_B,XSIZE=146,YSIZE=23,SENSITIVE=0,RETAIN=2)
  DTLB_TOP_INGEST_C     = WIDGET_BASE(DTLB_TOP_INGEST,COLUMN=1,/ALIGN_CENTER)
  DTLB_TOP_INGEST_BTN   = WIDGET_BUTTON(DTLB_TOP_INGEST_C,VALUE='Add L1b Data',UVALUE='INGEST',XSIZE=MAIN_BTN_SIZE,EVENT_PRO=BTEVENT)
  DTLB_TOP_INGEST_BTN   = WIDGET_BUTTON(DTLB_TOP_INGEST_C,VALUE='New Site',XSIZE=MAIN_BTN_SIZE,UVALUE='NEW_SITE',EVENT_PRO=BTEVENT)
  DTLB_TOP_INGEST_BTN   = WIDGET_BUTTON(DTLB_TOP_INGEST_C,VALUE='Data Download',XSIZE=MAIN_BTN_SIZE,UVALUE='DOWNLOAD',EVENT_PRO=BTEVENT)

  DTLB_TOP_BLK = WIDGET_BASE(DTLB_TOP,COLUMN=1)
  DTLB_TOP_BLK = WIDGET_BASE(DTLB_TOP,COLUMN=1)

;---------------------------
; ADD PROCESS IMAGE AND BUTTONS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: ADDING PROCESS OPTION BOX'
  DTLB_TOP_PROC         = WIDGET_BASE(DTLB_TOP,COLUMN=1,FRAME=1)
  DTLB_TOP_PROC_B       = WIDGET_BASE(DTLB_TOP_PROC)
  DTLB_TOP_PROCESS_IMG  = WIDGET_DRAW(DTLB_TOP_PROC_B,XSIZE=146,YSIZE=23,SENSITIVE=0,RETAIN=2)
  DTLB_TOP_PROC_C       = WIDGET_BASE(DTLB_TOP_PROC,COLUMN=1,/ALIGN_CENTER)
  DTLB_TOP_PROC_BTN     = WIDGET_BUTTON(DTLB_TOP_PROC_C,VALUE='Cloud Screening',UVALUE='CLOUD_SCREENING',XSIZE=MAIN_BTN_SIZE,EVENT_PRO=BTEVENT)
  DTLB_TOP_PROC_BTN     = WIDGET_BUTTON(DTLB_TOP_PROC_C,VALUE='Sensor Recal.',UVALUE='PROCESS 1',XSIZE=MAIN_BTN_SIZE,EVENT_PRO=BTEVENT)
  DTLB_TOP_PROC_BTN     = WIDGET_BUTTON(DTLB_TOP_PROC_C,VALUE='VGT Simulation',UVALUE='PROCESS 2',XSIZE=MAIN_BTN_SIZE,EVENT_PRO=BTEVENT)


  DTLB_TOP_BLK = WIDGET_BASE(DTLB_TOP,COLUMN=1)
  DTLB_TOP_BLK = WIDGET_BASE(DTLB_TOP,COLUMN=1)

;---------------------------
; ADD VISU IMAGE AND BUTTONS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: ADDING VISUALISTION OPTION BOX'
  DTLB_TOP_VISU           = WIDGET_BASE(DTLB_TOP,COLUMN=1,FRAME=1)
  DTLB_TOP_VISU_B         = WIDGET_BASE(DTLB_TOP_VISU)
  DTLB_TOP_VISUALISE_IMG  = WIDGET_DRAW(DTLB_TOP_VISU_B,XSIZE=146,YSIZE=23,SENSITIVE=0,RETAIN=2)
  DTLB_TOP_VISU_C         = WIDGET_BASE(DTLB_TOP_VISU,COLUMN=1,/ALIGN_CENTER)
  DTLB_TOP_VISU_BTN       = WIDGET_BUTTON(DTLB_TOP_VISU_C,VALUE='View Outputs',XSIZE=MAIN_BTN_SIZE,UVALUE='VISU',EVENT_PRO=BTEVENT)
  DTLB_TOP_VISU_BTN       = WIDGET_BUTTON(DTLB_TOP_VISU_C,VALUE='RSR Data',XSIZE=MAIN_BTN_SIZE,UVALUE='RSR',EVENT_PRO=BTEVENT)
  DTLB_TOP_VISU_BTN       = WIDGET_BUTTON(DTLB_TOP_VISU_C,VALUE='Database Stats',XSIZE=MAIN_BTN_SIZE,UVALUE='DATABASE_STATS',EVENT_PRO=BTEVENT)

;---------------------------
; ADD OPTION BUTTONS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: ADDING USER OPTION BOX'
  DTLB_BTM      = WIDGET_BASE(DTLB,ROW=1,FRAME=1,/ALIGN_CENTER)
  DTLB_BTM_BTN  = WIDGET_BUTTON(DTLB_BTM,VALUE='Options',XSIZE=SMLL_BTN_SIZE,UVALUE='OPTIONS',EVENT_PRO=BTEVENT)
  DTLB_BTM_BTN  = WIDGET_BUTTON(DTLB_BTM,VALUE='Help',XSIZE=SMLL_BTN_SIZE,UVALUE='HELP',EVENT_PRO=BTEVENT)
  DTLB_BTM_BTN  = WIDGET_BUTTON(DTLB_BTM,VALUE='About',XSIZE=SMLL_BTN_SIZE,UVALUE='ABOUT',EVENT_PRO=BTEVENT)
  DTLB_BTM_BTN  = WIDGET_BUTTON(DTLB_BTM,VALUE='Exit',XSIZE=SMLL_BTN_SIZE,EVENT_PRO=EXEVENT)

;---------------------------
; REALISE THE WIDGET AND DISPLAY THE PNG IMAGES

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: REALISING THE WIDGET AND DISPLAYING PNG IMAGES'
  WIDGET_CONTROL, DTLB, /REALIZE
  WIDGET_CONTROL, DTLB_IMG, GET_VALUE=D1
  WSET, D1
  TV, TITLE_IMAGE, TRUE=1
   
  WIDGET_CONTROL, DTLB_TOP_INGEST_IMG, GET_VALUE=D2
  WSET, D2
  TV, INGEST_IMAGE, TRUE=1

  WIDGET_CONTROL, DTLB_TOP_PROCESS_IMG, GET_VALUE=D3
  WSET, D3
  TV, PROCESS_IMAGE, TRUE=1
  
  WIDGET_CONTROL, DTLB_TOP_VISUALISE_IMG, GET_VALUE=D4
  WSET, D4
  TV, VISUALISE_IMAGE, TRUE=1  
  
;---------------------------
; STORE WIDGET INFO IN STRUCTURE
  
  DHMI_INFO = {$
                IVERBOSE:IVERBOSE ,$  
                SUM:SUM           ,$
                GROUP_LEADER: DTLB $
              }

;---------------------------
; REGISTER WITH THE XMANAGER

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_HMI: REGISTERING WITH THE XMANAGER'  
  WIDGET_CONTROL, DTLB, SET_UVALUE=DHMI_INFO,/NO_COPY
  XMANAGER,'DHMI_OBJECT', DTLB

END