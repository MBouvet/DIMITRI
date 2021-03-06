;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DIMITRI_INTERFACE_INTERCALIBRATION       
;* 
;* PURPOSE:
;*      INTERFACES BETWEEN THE DIMITRI HMI AND THE INTERCALIBRATE_DOUBLETS FUNCTION
;* 
;* CALLING SEQUENCE:
;*      RES = DIMITRI_INTERFACE_INTERCALIBRATION(OUTPUT_FOLDER,II_REGION,REF_SENSORS,REF_PROC_VERS, $
;*                                                  CAL_SENSORS,CAL_PROC_VERS,DIMITRI_BAND_IDS)      
;* 
;* INPUTS:
;*      OUTPUT_FOLDER     - THE FULL PATH OF THE OUTPUT FOLDER  
;*      II_REGION         - THE VALIDATION SITE NAME E.G. 'Uyuni'
;*      REF_SENSORS       - A STRING ARRAY CONTAINING THE SENSOR NAMES TO BE TREATED AS 
;*                          REFERENCE SENSORS DURING INTERCALIBRATION
;*      CAL_SENSORS       - A STRING ARRAY CONTAINING THE SENSOR NAMES TO BE 
;*                          INTERCALIBRATED AGAINST THE REFERENCE SENSORS
;*      DIMITRI_BAND_IDS  - AN ARRAY OF DIMITRI BAND INDEXES FOR INTERCALIBRATION (E.G. 0 = 412NM)
;*
;* KEYWORDS:
;*      ALL               - SET TO RUN INTERCALIBRATION ON ALL COMBINATIONS OF REF-CAL 
;*                          SENSOR PROVIDED. IF NOT SET THEN REF_SENSORS AND CAL_SENSORS 
;*                          MUST BE THE SAME DIMENSIONS
;*      VERBOSE           - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      STATUS            - 1: NO ERRORS REPORTED, (-1) OR 0: ERRORS DURING INGESTION 
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*                    - M BOUVET  - PROTOTYPE DIMITRI VERSION
;*        19 JAN 2011 - C KENT    - DIMITRI-2 V1.0
;*        20 JAN 2011 - C KENT    - UPDATED FILE REFERENCES, ADDED INTERCALIBRATION OUTPUT FOLDER, 
;*                                  ADDED TEST TO ENSURE DATA IS NOT COMPARED WITH ITSELF
;*        05 JUL 2011 - C KENT    - ADDED MODISA SURFACE DEPENDANCE
;*        15 AUG 2011 - C KENT    - ADDED UPDATED VERBOSE REPORTING, REMOVED NON-VERBOSE ERROR MESSAGE
;*
;* VALIDATION HISTORY:
;*        13 APR 2011 - C KENT    - WINDOWS 32-BIT IDL 7.1 AND LINUX 64-BIT IDL 8.0 NOMINAL 
;*                                  COMPILATION AND BEHAVIOUR. TESTED FOR MERIS VS MERIS 
;*                                  AND MERIS VS MODIS
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION DIMITRI_INTERFACE_INTERCALIBRATION,OUTPUT_FOLDER,II_REGION,REF_SENSORS,REF_PROC_VERS, $
                     CAL_SENSORS,CAL_PROC_VERS,DIMITRI_BAND_IDS,ALL=ALL,VERBOSE=VERBOSE

;-----------------------------------------
; CHECK OUTPUT_FOLDER EXISTS 
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_INTERFACE_INTERCAL: STARTING INTERFACE MODULE'
  RES = FILE_INFO(OUTPUT_FOLDER)
  IF RES.EXISTS EQ 0 THEN BEGIN
    PRINT,"DIMITRI_INTERFACE_INTERCAL: OUTPUT FOLDER DOESN'T EXIST"
    RETURN,-1
  ENDIF

;-----------------------------------------
; CHECK ARRAYS ARE THER SAME SIZE UNLESS 'ALL' 
; KEYWORD SET

  N_REFS = N_ELEMENTS(REF_SENSORS)
  N_REFP = N_ELEMENTS(REF_PROC_VERS)
  N_CALS = N_ELEMENTS(CAL_SENSORS)
  N_CALP = N_ELEMENTS(CAL_PROC_VERS)

  IF NOT KEYWORD_SET(ALL) AND $
    (N_REFS+N_REFP+N_CALS+N_CALP)/4 NE N_REFS THEN BEGIN
    PRINT,'DIMITRI_INTERFACE_INTERCAL: ERROR, INPUT SENSOR ARRAYS NOT CONSISTENT
    RETURN,-1 
  ENDIF
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_INTERFACE_INTERCAL: INPUT SENSOR ARRAYS NOMINAL'

;-----------------------------------------
; CREATE NEW ARRAYS TO CONTAIN SENSOR INFORMATION
  
  IF NOT KEYWORD_SET(ALL) THEN BEGIN
    IREFS = REF_SENSORS & IREFP = REF_PROC_VERS & ICALS = CAL_SENSORS & ICALP = CAL_PROC_VERS
  ENDIF ELSE BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_INTERFACE_INTERCAL: ALL COMBINATIONS KEYWORD SET, CREATING NEW ARRAYS'
    N_COM = N_REFS*N_CALS
    IREFS = STRARR(N_COM) & IREFP = STRARR(N_COM) & ICALS = STRARR(N_COM) & ICALP = STRARR(N_COM)
    REF_COUNT=0
    FOR NR=0,N_REFS-1 DO BEGIN
      FOR NC=0,N_CALS-1 DO BEGIN
        IREFS[REF_COUNT] = REF_SENSORS[NR]
        IREFP[REF_COUNT] = REF_PROC_VERS[NR]
        ICALS[REF_COUNT] = CAL_SENSORS[NC]
        ICALP[REF_COUNT] = CAL_PROC_VERS[NC]  
        REF_COUNT++
      ENDFOR
    ENDFOR
  ENDELSE

;-----------------------------------------
; RETRIEVE THE SITE TYPE

  SITE_TYPE = GET_SITE_TYPE(II_REGION,VERBOSE=VERBOSE)

;-----------------------------------------
; LOOP OVER THE REQUIRED REF_SENSOR-CAL_SENSOR 
; COMBINATIONS FOR INTERCALIBRATION

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_INTERFACE_INTERCAL: STARTING LOOP ON REQUIRED SENSOR COMBINATIONS'
  FOR DI_ICAL = 0,N_ELEMENTS(IREFS)-1 DO BEGIN
    FOR DI_BID = 0,N_ELEMENTS(DIMITRI_BAND_IDS)-1 DO BEGIN

;-----------------------------------------
; ADD MODIS LAND/OCEAN EXCEPTION
      
      IF IREFS[DI_ICAL] EQ 'MODISA' THEN BEGIN
        IF STRUPCASE(SITE_TYPE) EQ 'OCEAN' THEN TEMP_RSENS = IREFS[DI_ICAL]+'_O' ELSE TEMP_RSENS = IREFS[DI_ICAL]+'_L'
      ENDIF ELSE TEMP_RSENS = IREFS[DI_ICAL]

      IF ICALS[DI_ICAL] EQ 'MODISA' THEN BEGIN
        IF STRUPCASE(SITE_TYPE) EQ 'OCEAN' THEN TEMP_CSENS = ICALS[DI_ICAL]+'_O' ELSE TEMP_CSENS = ICALS[DI_ICAL]+'_L'
      ENDIF ELSE TEMP_CSENS = ICALS[DI_ICAL]      

;-----------------------------------------
; COMPARE BAND ID'S AND INTERCAL IF MATCHING
      
      BID1 = GET_SENSOR_BAND_INDEX(TEMP_RSENS,DIMITRI_BAND_IDS[DI_BID])
      BID2 = GET_SENSOR_BAND_INDEX(TEMP_CSENS,DIMITRI_BAND_IDS[DI_BID])
      IF BID1 LT 0 OR BID2 LT 0 THEN BEGIN
        IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_INTERFACE_INTERCAL: ERROR, NO SENSOR BAND INDEXES FOUND FOR DIMITRI INDEX ',STRTRIM(STRING(DIMITRI_BAND_IDS[DI_BID]),2)
        GOTO,NEXT_DI_BID
      ENDIF
      RES = INTERCALIBRATE_DOUBLETS(OUTPUT_FOLDER,II_REGION,IREFS[DI_ICAL],IREFP[DI_ICAL],BID1,ICALS[DI_ICAL],ICALP[DI_ICAL],BID2,VERBOSE=VERBOSE)
      NEXT_DI_BID:
    ENDFOR
  ENDFOR

;----------------------------------------
; RETURN NO FATAL ERRORS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_INTERFACE_INTERCAL: COMPLETED INTERCALIBRATION, NO FATAL ERRORS IDENTIFIED'  
  RETURN,1

END