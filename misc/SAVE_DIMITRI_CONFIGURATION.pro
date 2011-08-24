;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      SAVE_DIMITRI_CONFIGURATION 
;* 
;* PURPOSE:
;*      OVERWRITES THE CURRENT CONFIGURATION FILE WITH NEW DATA.
;* 
;* CALLING SEQUENCE:
;*      RES = SAVE_DIMITRI_CONFIGURATION(CFIG_DATA)      
;* 
;* INPUTS:
;*      CFIG_DATA - A STRUCTURE OF THE CONFIG FILE (RETURNED BY GET_DIMITRI_CONFIGURATION.PRO)     
;*
;* KEYWORDS:
;*      VERBOSE  - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      RESULT   - 1: NO ERRORS ENCOUNTERED 
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*        22 MAR 2011 - C KENT    - DIMITRI-2 V1.0
;*
;* VALIDATION HISTORY:
;*        14 APR 2011 - C KENT    - WINDOWS 32-BIT IDL 7.1 AND LINUX 64-BIT IDL 8.0 NOMINAL
;*                                  COMPILATION AND OPERATION        
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION SAVE_DIMITRI_CONFIGURATION,CFIG_DATA,VERBOSE=VERBOSE

;------------------------
; GET THE CFIG LOCATION

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'SAVE_DIMITRI_CONFIG: RETRIEVING FILE LOCATION'
  CFIG_FILE = GET_DIMITRI_LOCATION('CONFIG')

;------------------------
; CREATE A COPY OF THE CURRENT CFIG

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'SAVE_DIMITRI_CONFIG: CREATING TEMPORARY COPY OF FILE'
  TEMP_COPY = CFIG_FILE+'.TEMP'
  FILE_COPY,CFIG_FILE,TEMP_COPY

;------------------------
; DELETE THE CURRENT CFIG, 
; OPEN A NEW VERSION AND 
; PRINT THE HEADER

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'SAVE_DIMITRI_CONFIG: CREATING NEW CONFIG FILE'
  FILE_DELETE,CFIG_FILE
  OPENW,OFIG,CFIG_FILE,/GET_LUN
  PRINTF,OFIG,'OPTION','VALUE',FORMAT='(1(A,1H;),1(A))'

;------------------------
; PRINT OUT EACH LINE

  FOR I=0,N_ELEMENTS(CFIG_DATA.(0))-1 DO BEGIN
    PRINTF,OFIG,CFIG_DATA.(0)[I],CFIG_DATA.(1)[I],FORMAT='(1(A,1H;),1(F15.5))'
  ENDFOR

;------------------------
;CLOSE THE NEW FILE, DELETE 
; THE TEMP COPY AND RETURN

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'SAVE_DIMITRI_CONFIG: CLOSING FILE, DELETING TEMP, AND RETURNING'
  FREE_LUN,OFIG
  FILE_DELETE,TEMP_COPY
  RETURN,1

END