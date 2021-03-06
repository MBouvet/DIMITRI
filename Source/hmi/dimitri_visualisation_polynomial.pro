;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DIMITRI_VISUALISATION_POLYNOMIAL     
;* 
;* PURPOSE:
;*      THIS PROGRAM AUTOMATICALLY SERACHES AND RETRIEVES THE POLYNOMIAL COEFICIENTS 
;*      OUTPUT BY DIMITRI GIVEN AN OUTPUT FOLDER AND REFERENCE SENSOR CONFIGURATION.
;* 
;* CALLING SEQUENCE:
;*      RES = DIMITRI_VISUALISATION_POLYNOMIAL(IC_FOLDER,IC_REGION,DIMITRI_WL,REF_SENSOR,$
;*                                       REF_PROC_VER,NEW_X_INFO,SENS_CONFIGS)      
;*
;* INPUTS:
;*      IC_FOLDER     - A STRING OF THE FULL PATH FOR THE DOUBLET_EXTRACTION OUTPUT FOLDER
;*      IC_REGION     - A STRING OF THE DIMITRI VALIDATION SITE REQUESTED
;*      DIMITRI_WL    - A STRING OF THE DIMITRI WAVELENGTH (E.G. '555')
;*      REF_SENSOR    - A STRING OF THE REFERENCE SENSOR UTILISED FOR PROCESSING
;*      REF_PROC_VER  - A STRING OF THE REFERENCE SENSOR'S PROCESSING VERSION 
;*      NEW_X_INFO    - A FLOAT ARRAY OF THE X DATA TO BE USED TO GENERATE THE POLYNOMIAL Y DATA
;*      SENS_CONFIGS  - A STRING ARRAY OF THE SENSOR CONFIGURATIONS RETURNED BY
;*                      DIMITRI_VISUALISATION_REFLECTANCE.pro
;*
;* KEYWORDS:
;*      VERBOSE - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      A STRUCTURE WITH THE FOLLOWING TAGS:
;*      ERROR             - THE ERROR STATUS CODE, 0 = NOMINAL, 1 OR -1 = ERROR
;*      DATA              - AN ARRAY CONTAINING ALL POLYNOMINAL DATA
;*      SENS_CONFIG_ABLE  - AN INTEGER ARRAY DESCRIBING IF DATA IS AVAILABLE FOR A
;*                          CERTAIN SENSOR CONFIGURATION
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      08 FEB 2011 - C KENT    - DIMITRI-2 V1.0
;*      08 JUL 2011 - C KENT    - MAJOR UPDATES, NOW READS OUTPUT INTERCAL SAV WHICH CONTAINS TIME, 
;*                                DIFFERENCE TO REFERENCE SENSOR AND POLYNOMIAL DIFFERENCE
;*      25 JUL 2011 - C KENT    - MINOR BUG FIX DURING POLYNOMIAL DATA RETRIEVAL
;*
;* VALIDATION HISTORY:
;*      08 FEB 2011 - C KENT    - WINDOWS 32-BIT MACHINE IDL 7.1/IDL 8.0: NOMINAL 
;*      14 APR 2011 - C KENT    - WINDOWS 32-BIT IDL 7.1 AND LINUX 64-BIT IDL 8.0 NOMINAL
;*                                COMPILATION AND OPERATION
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION DIMITRI_VISUALISATION_POLYNOMIAL,IC_FOLDER,IC_REGION,DIMITRI_WL,REF_SENSOR,$
                                          REF_PROC_VER,NEW_X_INFO,SENS_CONFIGS,VERBOSE=VERBOSE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_VISU_POLY: STARTING RETRIEVAL OF DIMITRI POLYNOMIAL DATA'
  
;--------------------------------  
; GET RELATED SENSOR INDEX BASED 
; ON DIMITRI BAND ID

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_VISU_POLY: SEARCHING FOR POLYNOMIAL DATA'    
  ;CAL_STR   = STRING('ICOEF_'+IC_REGION+'*REF_'+REF_SENSOR+'_'+REF_PROC_VER+'_'+DIMITRI_WL+'.dat')
  CAL_STR   = STRING('ICDIF_'+IC_REGION+'*REF_'+REF_SENSOR+'_'+REF_PROC_VER+'_'+DIMITRI_WL+'.dat')
  ;ERR_STR   = STRING('ICERR_'+IC_REGION+'*REF_'+REF_SENSOR+'_'+REF_PROC_VER+'_'+DIMITRI_WL+'.dat')
  CAL_FILES = FILE_SEARCH(IC_FOLDER,CAL_STR)
  ;ERR_FILES = FILE_SEARCH(IC_FOLDER,ERR_STR)

;-------------------------------- 
; GET LIST OF ALL SENSOR CONFIGS 
; AND CREATE ARRAY TO HOLD DATA

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_VISU_POLY: DEFINING ARRAY TO HOLD ALL DATA'
  NUM_SENS_CONFIGS  = N_ELEMENTS(SENS_CONFIGS)
  SENS_CONFIG_ABLE  = MAKE_ARRAY(N_ELEMENTS(SENS_CONFIGS),/INTEGER,VALUE=0)
;  diff_DATA         = MAKE_ARRAY(N_ELEMENTS(NEW_X_INFO),NUM_SENS_CONFIGS)
;  POLY_DATA         = MAKE_ARRAY(N_ELEMENTS(NEW_X_INFO),NUM_SENS_CONFIGS,2)
  DIFF_DATA         = MAKE_ARRAY(5000,NUM_SENS_CONFIGS,2)
  POLY_DATA         = MAKE_ARRAY(5000,NUM_SENS_CONFIGS,2)
  POLYMIN           = 0
  POLYMAX           = 1

;-------------------------------- 
; IF NO POLYNOMIAL DATA FOUND 
; THEN RETURN
  
  IF STRCMP(CAL_FILES[0],'') EQ 1 THEN BEGIN
    PRINT, 'DIMITRI_VISU_POLY: NO POLYNOMIAL DATA FOUND, RETURNING'
    RETURN,{ERROR:0,POLY_DATA:POLY_DATA,DIFF_DATA:DIFF_DATA,SENS_CONFIG_ABLE:SENS_CONFIG_ABLE,POLYMIN:POLYMIN,POLYMAX:POLYMAX}
  ENDIF

;--------------------------------  
; RESTORE THE DIFFERENCE AND NEW 
; POLYNOMIAL DATA

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_VISU_POLY: STARTING LOOP ON ALL CAL-SENSOR FILES'
  FOR I=0,N_ELEMENTS(CAL_FILES)-1 DO BEGIN
  
;-------------------------------- 
; GET SENSOR CONFIGURATION FROM FILENAME

    POS   = STRPOS(CAL_FILES[I],IC_REGION,/REVERSE_SEARCH)+STRLEN(IC_REGION)+1
    POS1  = STRPOS(CAL_FILES[I],'REF',/REVERSE_SEARCH)-1
    TMP   = STRMID(CAL_FILES[I],POS,POS1-POS)

    POS = WHERE(STRCMP(SENS_CONFIGS,TMP) EQ 1)
    IF POS[0] EQ -1 OR N_ELEMENTS(POS) GT 1 THEN GOTO,NEXT_FILE
    SENS_CONFIG_ABLE[POS] = 1
    RESTORE,CAL_FILES[I]

    TMP = N_ELEMENTS(ICDIFF_DATA[*,0])
    DIFF_DATA[0:TMP-1,POS,0] = ICDIFF_DATA[*,0]
    DIFF_DATA[0:TMP-1,POS,1] = ICDIFF_DATA[*,1]
    POLY_DATA[0:TMP-1,POS,0] = ICDIFF_DATA[*,0]
    POLY_DATA[0:TMP-1,POS,1] = ICDIFF_DATA[*,2]

    TMIN = MIN([ICDIFF_DATA[*,1],ICDIFF_DATA[*,2]])
    TMAX = MAX([ICDIFF_DATA[*,1],ICDIFF_DATA[*,2]])
    
    IF TMIN LT POLYMIN THEN POLYMIN = TMIN 
    IF TMAX GT POLYMAX THEN POLYMAX = TMAX 


;    POLY_DATA[*,POS] = POLY_COEFS[0]+POLY_COEFS[1]*NEW_X_INFO+POLY_COEFS[2]*(NEW_X_INFO)^2
;
;    RESTORE,ERR_FILES[I]
;    TMP = N_ELEMENTS(ERRORS_OUTPUT[*,0])
;    POLY_ERR_DATA[0:TMP-1,POS,0] = ERRORS_OUTPUT[*,0]
;    POLY_ERR_DATA[0:TMP-1,POS,1] = ERRORS_OUTPUT[*,1]  
    
    NEXT_FILE:
  ENDFOR

;--------------------------------  
; RETURN ALL DATA IN A STRUCTURE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_VISU_POLY: RETURNING POLYNOMIAL DATA STRUCTURE'
  VISU_POLY = {                                              $
              ERROR:0                                       ,$
              POLY_DATA:POLY_DATA                           ,$
              DIFF_DATA:DIFF_DATA                           ,$
              POLYMIN:POLYMIN                               ,$
              POLYMAX:POLYMAX                               ,$
              SENS_CONFIG_ABLE:SENS_CONFIG_ABLE              $
              }

  RETURN,VISU_POLY

END