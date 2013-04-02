;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      RSR_PLOT_RESET    
;* 
;* PURPOSE:
;*      THIS FUNCTION IS CALLED BY THE ROUTINE "PLOT_DIMITRI_SENSOR_RSR" AND RESETS 
;*      THE DIMITRI RSR PLOT BACK TO IT'S NULL STATUS.
;*
;* CALLING SEQUENCE:
;*      RSR_INFO = RSR_PLOT_RESET(RSR_INFO)     
;* 
;* INPUTS:
;*      RSR_INFO  - THE RSR_INFO STRUCTURE AS DEFINED WITHIN "PLOT_DIMITRI_SENSOR_RSR"
;*
;* KEYWORDS:
;*      VERBOSE   - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      NONE
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      30 MAR 2011 - C KENT   - DIMITRI-2 V1.0
;*
;* VALIDATION HISTORY:
;*      14 APR 2011 - C KENT   - WINDOWS 32-BIT IDL 7.1 AND LINUX 64-BIT IDL 8.0 NOMINAL
;*                               COMPILATION AND OPERATION 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION RSR_PLOT_RESET,RSR_INFO,VERBOSE=VERBOSE

;---------------------
; DESTROY ALL PLOT OBJECTS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'RSR_PLOT_RESET: DESTROYING PLOT OBJECTS'
  OBJ_DESTROY,RSR_INFO.RHO_OBJ[*]
  OBJ_DESTROY,RSR_INFO.RSR_OBJ[*]
  OBJ_DESTROY,RSR_INFO.SPC_OBJ[*]

;  TEMP = N_ELEMENTS(RSR_INFO.RHO_OBJ)
;    FOR I=0,N_EL-1 DO OBJ_DESTROY,RSR_INFO.RHO_OBJ[*]
;
;  TEMP = N_ELEMENTS(RSR_INFO.RSR_OBJ)
;    FOR I=0,N_EL-1 DO OBJ_DESTROY,RSR_INFO.RSR_OBJ[*]
;
;  TEMP = N_ELEMENTS(RSR_INFO.SPC_OBJ)
;    FOR I=0,N_EL-1 DO OBJ_DESTROY,RSR_INFO.SPC_OBJ[*]

;---------------------
; SET ALL DATA AS OFF 
; AND CHANGE PLOT TYPE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'RSR_PLOT_RESET: SETTING ALL DATA AS OFF AND PLOT TYPE TO NON'
  RSR_INFO.DATA_ON[*] = 0
  RSR_INFO.PLOT_TYPE = 'NON'

  RETURN,RSR_INFO

END