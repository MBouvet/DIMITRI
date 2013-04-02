;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_VEGETATION_HEADER_INFO       
;* 
;* PURPOSE:
;*      RETIREVES THE HEADER INFORMATION FROM A VEGETATION LOG FILE
;* 
;* CALLING SEQUENCE:
;*      RES = INGEST_VEGETATION_PRODUCT(LOG_FILE)      
;* 
;* INPUTS:
;*      LOG_FILE   -  THE FULL PATH OF THE LOG FILE TO BE READ     
;*
;* KEYWORDS:
;*      VERBOSE    - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      VGT_HEADER - A STRUCTURE CONTAINING THE DIMITRI RELEVANT HEADER INFORMATION
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*        17 DEC 2010 - C KENT    - DIMITRI-2 V1.0
;*        14 JUL 2011 - C KENT    - UPDATED TIME EXTRACTION SECTION
;*
;* VALIDATION HISTORY:
;*        02 DEC 2010 - C KENT    - WINDOWS 32BIT MACHINE idl 7.1: COMPILATION AND EXECUTION 
;*                                  SUCCESSFUL. TESTED MULTIPLE OPTIONS ON MULTIPLE 
;*                                  PRODUCTS
;*        06 JAN 2011 - C KENT    - LINUX 64-BIT MACHINE IDL 8.0: COMPILATION SUCCESSFUL, 
;*                                  NO APPARENT DIFFERENCES WHEN COMPARED TO WINDOWS MACHINE
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_VEGETATION_HEADER_INFO,LOG_FILE,VERBOSE=VERBOSE

;--------------------------------------------
;CHECK FILE EXISTS

  IF STRCMP(STRING(LOG_FILE),'') THEN BEGIN
    PRINT, 'VEGETATION L1B HEADER: ERROR, NO INPUT FILES PROVIDED, RETURNING...'
    RETURN,{ERROR:-1}
  ENDIF  

  TEMP = FILE_INFO(LOG_FILE)
  IF TEMP.EXISTS EQ 0 THEN BEGIN
    PRINT, 'VEGETATION L1B HEADER: ERROR, LOG FILE DOES NOT EXIST'
    RETURN,{ERROR:-1}
  ENDIF  

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'VEGETATION L1B HEADER: LOG FILE NOMINAL, DEFINING STRUCTURE'

;--------------------------------------------
; DEFINE DATA STRUCTURE
  
  TEMP = STRARR(1)
  VGT_HEADER =  {$
                PRD_ID      : TEMP,$
                ACQ_DATE    : TEMP,$
                ACQ_TIME    : TEMP,$
                AUX_GEO     : TEMP,$
                AUX_DEM     : TEMP,$
                AUX_RAD_EQL : TEMP,$
                AUX_RAD_ABS : TEMP $
                }

;--------------------------------------------
; READ THE LOG FILE AS A STRING

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'VEGETATION L1B HEADER: READING LOG FILE'
  TEMP = READ_BINARY(LOG_FILE)
  TEMP = STRING(TEMP)

;--------------------------------------------
; RETRIEVE DATA
  
  RES = STRPOS(TEMP,'PRODUCT_ID')
    VGT_HEADER.PRD_ID = STRMID(TEMP,RES+26,22)
  RES = STRPOS(TEMP,'SEGM_FIRST_DATE')  
    VGT_HEADER.ACQ_DATE = STRMID(TEMP,RES+26,8)
  RES = STRPOS(TEMP,'SEGM_FIRST_TIME')  
    VGT_HEADER.ACQ_TIME = STRMID(TEMP,RES+26,6)
  RES = STRPOS(TEMP,'GEOM_CHAR_REF')  
   VGT_HEADER.AUX_GEO = STRMID(TEMP,RES+26,26)
  RES = STRPOS(TEMP,'DEM_REF')  
   VGT_HEADER.AUX_DEM = STRMID(TEMP,RES+26,19)
  RES = STRPOS(TEMP,'DEM_DATE')    
   VGT_HEADER.AUX_DEM = STRING(VGT_HEADER.AUX_DEM+'_'+STRMID(TEMP,RES+26,8))    
  RES = STRPOS(TEMP,'RADIOM_EQUAL_REF')  
   VGT_HEADER.AUX_RAD_EQL = STRMID(TEMP,RES+26,26)    
  RES = STRPOS(TEMP,'RADIOM_ABS_CAL_REF')  
   VGT_HEADER.AUX_RAD_ABS = STRMID(TEMP,RES+26,26)

;--------------------------------------------
; RETURN THE STRUCTURE

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'VEGETATION L1B HEADER: RETURNING HEADER DATA'
  RETURN,VGT_HEADER

END