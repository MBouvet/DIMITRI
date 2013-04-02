;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_SENSOR_BAND_NAME       
;* 
;* PURPOSE:
;*      RETURNS THE BAND WAVELENGTH FOR A GIVEN SENSOR AND BAND INDEX.
;* 
;* CALLING SEQUENCE:
;*      RES = GET_SENSOR_BAND_NAME(BN_SENSOR,BN_ID)      
;* 
;* INPUTS:
;*      BN_SENSOR - A STRING OF THE SENSOR NAME (E.G. 'MERIS')
;*      BN_ID     - AN INTEGER OF THE SENSOR BAND INDEX (E.G. MERIS 0 = 412NM)
;*
;* KEYWORDS:
;*      VERBOSE   - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      ITW_VALUE - A STRING OF THE SENSOR WAVELENGTH FOR GIVEN SENSOR AND BAND INDEX
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      19 SEP 2011 - C KENT   - DIMITRI-2 V1.0
;*
;* VALIDATION HISTORY:
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_SENSOR_BAND_NAME,BN_SENSOR,BN_ID

;------------------------------------
; DEFINE SENSOR FILE
  
  SBI_FILE = GET_DIMITRI_LOCATION('BAND_NAME')
  RES = FILE_INFO(SBI_FILE)
  IF RES.EXISTS EQ 0 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'GET_SENSOR_BAND_NAME: ERROR, SENSOR INFORMATION FILE NOT FOUND'
    RETURN,'ERROR'
  ENDIF

;------------------------------------
; RETRIEVE TEMPLATE AND READ DATA FILE  
  
  TEMP = GET_DIMITRI_BAND_NAME_TEMPLATE()
  BI_DATA = READ_ASCII(SBI_FILE,TEMPLATE=TEMP)

;------------------------------------
; FIND INDEX OF INPUT SENSOR

  RES = WHERE(STRCMP(TEMP.FIELDNAMES,BN_SENSOR) EQ 1)
  IF RES[0] EQ -1 OR N_ELEMENTS(RES) GT 1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'GET_SENSOR_BAND_NAME: ERROR, SENSOR INDEX RETRIEVAL'
    RETURN,'ERROR'  
  ENDIF

;------------------------------------
; FIND INDEX OF INPUT INDEX AND RETURN 
; THE ASSOCIATED WAVECENTRE  

  TEMP = BI_DATA.(RES)[BN_ID]
  IF TEMP[0] LT 0 OR N_ELEMENTS(TEMP) GT 1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'INDEX TO WAVELENGTH: ERROR, CANNOT FIND WAVELENGTH ID'
    RETURN,'ERROR'  
  ENDIF  

  ITW_VALUE = STRTRIM(STRING(FIX(TEMP)),2)
  RETURN,ITW_VALUE

END