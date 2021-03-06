;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      SAVE_DIMITRI_DATABASE       
;* 
;* PURPOSE:
;*      SAVES DATA TO THE DIMITRI DATABASE FILE
;* 
;* CALLING SEQUENCE:
;*      RES = SAVE_DIMITRI_DATABASE(DB_DATA)      
;* 
;* INPUTS:
;*      DB_DATA = A DATABASE STRUCTURE TAKEN FROM GET_DIMITRI_TEMPLATE
;*
;* KEYWORDS:
;*      VERBOSE  - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      STATUS   - 1: NOMINAL, (-1) OR 0: ERROR
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      14 MAR 2011 - C KENT   - DIMITRI-2 V1.0
;*      21 MAR 2011 - C KENT   - MODIFIED FILE DEFINITION TO USE GET_DIMITRI_LOCATION
;*      06 JUL 2011 - C KENT   - ADDED INFO WIDGET WARNING USERS OF SAVING PROCESS
;*      30 AUG 2011 - C KENT   - MODIFIED DATABASE SAVING SECTION FOR OPTIMISED PERFORMANCE
;*      08 MAR 2012 - C KENT   - UPDATED BACKUP FILENAME, ADDED ROI_COVER
;*
;* VALIDATION HISTORY:
;*      12 APR 2011 - C KENT   - LINUX 64-BIT IDL 8.0 & WINDOWS 32-BIT IDL 7.1: NOMINAL 
;*                               COMPILATION AND OPERATION
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION SAVE_DIMITRI_DATABASE,DB_DATA,VERBOSE=VERBOSE

;----------------------------------------
; INFORM THE USER THAT IT MAY TAKE AWHILE

  DIMS  = GET_SCREEN_SIZE()
  XSIZE = 200
  YSIZE = 60
  XLOC  = (DIMS[0]/2)-(XSIZE/2)
  YLOC  = (DIMS[1]/2)-(YSIZE/2)

  INFO_WD = WIDGET_BASE(COLUMN=1, XSIZE=XSIZE, YSIZE=YSIZE, TITLE='Please Wait...',XOFFSET=XLOC,YOFFSET=YLOC)
  LBLTXT  = WIDGET_LABEL(INFO_WD,VALUE=' ')
  LBLTXT  = WIDGET_LABEL(INFO_WD,VALUE='Please wait,')
  LBLTXT  = WIDGET_LABEL(INFO_WD,VALUE='Saving Database data...')
  WIDGET_CONTROL, INFO_WD, /REALIZE
  WIDGET_CONTROL, /HOURGLASS

;----------------------------------------
; GET DATABASE PARAMETERS

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'DIMITRI DATABASE SAVE: RETRIEVING FORMAT,HEADER AND TEMPLATE'
  DB_ITER   = N_ELEMENTS(DB_DATA.(0))
  DB_FORMAT = GET_DIMITRI_TEMPLATE(1,/FORMAT,VERBOSE=VERBOSE)
  DB_HEADER = GET_DIMITRI_TEMPLATE(1,/HDR,VERBOSE=VERBOSE)
  DB_TEMPLATE = GET_DIMITRI_TEMPLATE(1,/TEMPLATE,VERBOSE=VERBOSE)

;----------------------
; IDENTIFIY CURRENT DIRECTORY 
; AND DATABASE FOLDER

  DL          = GET_DIMITRI_LOCATION('DL')
  DB_BACKUP   = GET_DIMITRI_LOCATION('DB_BACKUP')
  DIMITRI_DB  = GET_DIMITRI_LOCATION('DATABASE')
  RES         = SYSTIME(/UTC)
  DY          = FIX(STRMID(RES,8,2)) LT 10 ? '0'+STRMID(RES,8,2) : STRMID(RES,8,2)
  BKUP_DB     = DB_BACKUP+DL+DY+'_'+STRUPCASE(STRMID(RES,4,3))+'_'+STRMID(RES,20,4)+'_DIMITRI_DATABASE.CSV'

;----------------------
; CREATE BACKUP FOLDER IF 
; IT DOESN'T EXIST
  
  RES = FILE_INFO(DB_BACKUP)
  IF RES.DIRECTORY EQ 0 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI DATABASE SAVE: CREATING BACKUP FOLDER'
    FILE_MKDIR,DB_BACKUP
  ENDIF

;----------------------
; SAVE THE ORIGINAL DATABASE INTO 
; BACKUP FOLDER, DELETE IT 
; AND CREATE A NEW VERSION
    
  FILE_COPY,DIMITRI_DB,BKUP_DB,/OVERWRITE
  FILE_DELETE,DIMITRI_DB
  OPENW,DB_LUN,DIMITRI_DB,/GET_LUN
  PRINTF,DB_LUN,DB_HEADER

;---------------------------------------
; OPEN THE DATABASE AND APPEND DATA

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'DIMITRI DATABASE SAVE: PRINTING DATA'  
;  DBI = TRANSPOSE([                                                                                                 $
;                    [STRING(DB_DATA.(0))],  [STRING(DB_DATA.(1))],  [STRING(DB_DATA.(2))],  [STRING(DB_DATA.(3))]   ,$
;                    [STRING(DB_DATA.(4))],  [STRING(DB_DATA.(5))],  [STRING(DB_DATA.(6))],  [STRING(DB_DATA.(7))]   ,$
;                    [STRING(DB_DATA.(8))],  [STRING(DB_DATA.(9))],  [STRING(DB_DATA.(10))], [STRING(DB_DATA.(11))]  ,$
;                    [STRING(DB_DATA.(12))], [STRING(DB_DATA.(13))], [STRING(DB_DATA.(14))], [STRING(DB_DATA.(15))]  ,$
;                    [STRING(DB_DATA.(16))], [STRING(DB_DATA.(17))], [STRING(DB_DATA.(18))], [STRING(DB_DATA.(19))]  ,$
;                    [STRING(DB_DATA.(20))], [STRING(DB_DATA.(21))], [STRING(DB_DATA.(22))], [STRING(DB_DATA.(23))]   $                      
;                  ]) 
;  PRINTF,DB_LUN,DBI,FORMAT='(23(A,1H;),A)'
  FOR DBI = 0L,DB_ITER-1 DO BEGIN
    PRINTF,DB_LUN,FORMAT=DB_FORMAT,$
      DB_DATA.DIMITRI_DATE[DBI],$
      DB_DATA.REGION[DBI],$
      DB_DATA.SENSOR[DBI],$
      DB_DATA.PROCESSING_VERSION[DBI],$
      DB_DATA.YEAR[DBI],$
      DB_DATA.MONTH[DBI],$
      DB_DATA.DAY[DBI],$
      DB_DATA.DOY[DBI],$
      DB_DATA.DECIMAL_YEAR[DBI],$
      DB_DATA.FILENAME[DBI],$
      DB_DATA.ROI_COVER[DBI],$
      DB_DATA.NUM_ROI_PX[DBI],$
      DB_DATA.AUTO_CS[DBI],$
      DB_DATA.MANUAL_CS[DBI],$
      DB_DATA.AUX_DATA_1[DBI],$
      DB_DATA.AUX_DATA_2[DBI],$
      DB_DATA.AUX_DATA_3[DBI],$
      DB_DATA.AUX_DATA_4[DBI],$
      DB_DATA.AUX_DATA_5[DBI],$
      DB_DATA.AUX_DATA_6[DBI],$
      DB_DATA.AUX_DATA_7[DBI],$
      DB_DATA.AUX_DATA_8[DBI],$
      DB_DATA.AUX_DATA_9[DBI],$
      DB_DATA.AUX_DATA_10[DBI]
  ENDFOR

;----------------------
; CLOSE THE DATABASE FILE AND RETURN NOMINAL STATUS

  FREE_LUN,DB_LUN
  WIDGET_CONTROL,INFO_WD,/DESTROY
  RETURN,1

END