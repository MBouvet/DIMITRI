;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_MODISA_L1B_EMISSIVE_LINUX      
;* 
;* PURPOSE:
;*      RETURNS THE L1B EMISSIVE RADIANCE FOR A SPECIFIC MODISA BAND
;* 
;* CALLING SEQUENCE:
;*      RES = GET_MODISA_L1B_EMISSIVE_LINUX(FILENAME,IN_BAND)      
;* 
;* INPUTS:
;*      FILENAME - A SCALAR CONTAINING THE FILENAME OF THE PRODUCT FOR REFLECTANCE EXTRACTION 
;*      IN_BAND  - THE BAND INDEX TO BE RETRIEVED WITHIN THE RESOLUTION DATA SET
;*
;* KEYWORDS:
;*      VERBOSE     - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      TOA_EMM     - TOA REFLECTANCE FOR PRODUCT FOLLOWING USE OF SCALING FACTOR 
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      26 APR 2011 - C KENT   - DIMITRI-2 V1.0
;*
;* VALIDATION HISTORY:
;*      26 APR 2011 - C KENT    - 
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_MODISA_L1B_EMISSIVE_LINUX,FILENAME,IN_BAND,VERBOSE=VERBOSE


;------------------------------------------------
; CHECK FILENAME AND IN_BAND ARE NOMINAL

  IF FILENAME EQ '' THEN BEGIN
    PRINT, 'MODISA L1B EMISSIVE LINUX: ERROR, INPUT FILENAME INCORRECT'
    RETURN,-1
  ENDIF
 
;------------------------------------------------ 
; START THE SD INTERFACE AND OPEN THE PRODUCT 

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'MODISA L1B EMISSIVE LINUX: STARTING IDL HDF SD INTERFACE'  
  HDF_ID = HDF_SD_START(FILENAME,/READ) 

;------------------------------------------------
; RETRIEVE THE EMMISIVE WAVEBANDS

    IF KEYWORD_SET(VERBOSE) THEN PRINT,'MODISA L1B EMISSIVE LINUX: RETRIEVING DATA'
    SDS_NAME = HDF_SD_NAMETOINDEX(HDF_ID, 'EV_1KM_Emissive')
    SDS_ID=HDF_SD_SELECT(HDF_ID,SDS_NAME)
    HDF_SD_GETDATA,SDS_ID,TOA_EMM_COUNTS
    TOA_EMM_COUNTS = TOA_EMM_COUNTS[*,*,IN_BAND]
  
    ATTR_INDX = HDF_SD_ATTRFIND(SDS_ID, 'radiance_scales')
      IF ATTR_INDX GE 0 THEN HDF_SD_ATTRINFO, SDS_ID, ATTR_INDX, DATA=TOA_EMM_SLOPES
  
    ATTR_INDX = HDF_SD_ATTRFIND(SDS_ID, 'radiance_offsets')
      IF ATTR_INDX GE 0 THEN HDF_SD_ATTRINFO, SDS_ID, ATTR_INDX, DATA=TOA_EMM_OFFSET  

    HDF_SD_ENDACCESS, SDS_ID

    TOA_EMM = FLOAT(TEMPORARY(TOA_EMM))

;-----------------------------------------------
; CONVERT TO RADIANCE

  TEMP_DIMS = SIZE(TOA_EMM)
  FOR I=0,TEMP_DIMS[3]-1 DO BEGIN
  TOA_EMM[*,*,I] = TOA_EMM_SLOPES[I]*(TOA_EMM[*,*,I]-TOA_EMM_OFFSET[I])
  ENDFOR
  
  
;-----------------------------------------------
; CLOSE THE PRODUCT AND SD INTERFACE

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'MODISA L1B EMISSIVE LINUX: CLOSING PRODUCT AND RETURNING EMISSIVE DATA'
  HDF_SD_END,HDF_ID  
  
;-----------------------------------------------
; RETURN,L1B_EMM
  
  RETURN,TOA_EMM
 
END
