;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_SITE_COORDINATES       
;* 
;* PURPOSE:
;*      RETURNS AN ARRAY OF FILTERS FOR SEARCHING FOR DATA PRODUCTS
;* 
;* CALLING SEQUENCE:
;*      RES = GET_SITE_COORDINATES(SITE_ID,SITE_FILE)      
;* 
;* INPUTS:
;*      SITE_ID = A STRING CONTAINING THE NAME OF THE REQUIRED SITE GOELOCATION
;*
;* KEYWORDS:
;*      VERBOSE  - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      ICOORDS  - AN ARRAY OF THE REQEUSTED COORDINATES (N,S,E,W)
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      23 DEC 2010 - C KENT   - DIMITRI-2 V1.0
;*
;* VALIDATION HISTORY:
;*      23 DEC 2010 - C KENT   - WINDOWS 32-BIT MACHINE IDL 7.1: COMPILATION AND CALLING SUCCESSFUL
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_SITE_COORDINATES,SITE_ID,SITE_FILE,VERBOSE=VERBOSE

  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'SITE_COORDINATES: RETRIEVING COORDINATES FOR SITE - ',SITE_ID

;-----------------------------
; CHECK FILE EXISTS

  TEMP = FILE_INFO(SITE_FILE)
  IF TEMP.EXISTS EQ 0 THEN BEGIN
    PRINT, 'SITE_COORDINATES: ERROR, SITE FILE DOES NOT EXIST'
    RETURN,-1
  ENDIF

;-----------------------------
; GET TEMPLATE FOR SITE FILE

  IF KEYWORD_SET(VERBOSE) THEN SITE_TEMPLATE = GET_DIMITRI_SITE_DATA_TEMPLATE(/VERBOSE) $
  ELSE SITE_TEMPLATE = GET_DIMITRI_SITE_DATA_TEMPLATE()

;-----------------------------
; READ FILE
  
  SITE_DATA = READ_ASCII(SITE_FILE,TEMPLATE=SITE_TEMPLATE)

  RES = WHERE(STRCMP(SITE_DATA.SITE_ID,SITE_ID) EQ 1)
  IF RES[0] EQ -1 OR N_ELEMENTS(RES) GT 1 THEN BEGIN
    PRINT,'SITE_COORDINATES: ERROR, SITE_ID ERROR IN SITE_FILE' 
    RETURN,-1
  ENDIF

;-----------------------------  
; RETRIEVE COORDINATES

  ICOORDS = [SITE_DATA.NLAT[RES],SITE_DATA.SLAT[RES],SITE_DATA.ELON[RES],SITE_DATA.WLON[RES]]

;-----------------------------
; RETURN COORDINATES
  
  RETURN,ICOORDS

END

