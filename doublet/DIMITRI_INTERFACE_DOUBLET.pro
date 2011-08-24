;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DIMITRI_INTERFACE_DOUBLET       
;* 
;* PURPOSE:
;*      FORMS THE INTERFACE ROUTINE BETWEEN THE DIMITRI HMI AND THE DOUBLET 
;*      EXTRACTION FUNCTION.
;* 
;* CALLING SEQUENCE:
;*      RES = DIMITRI_INTERFACE_DOUBLET(OUTPUT_FOLDER,ED_REGION,SENSOR1,PROC_VER1,SENSOR2,$
;*                                      PROC_VER2,CHI_THRESHOLD,DAY_OFFSET,CLOUD_PERCENTAGE,$
;*                                      ROI_PERCENTAGE)      
;* 
;* INPUTS:
;*      OUTPUT_FOLDER     - THE FULL PATH OF THE OUTPUT FOLDER  
;*      ED_REGION         - THE VALIDATION SITE NAME E.G. 'Uyuni'
;*      SENSOR1           - THE NAME OF THE 1ST SENSOR FOR DOUBLET EXTRACTION E.G. 'MERIS'
;*      PROC_VER1         - THE PROCESSING VERSION OF THE 1ST SENSOR E.G. '2nd_Processing'
;*      SENSOR2           - THE NAME OF THE 2ND SENSOR FOR DOUBLET EXTRACTION E.G. 'MODISA
;*      PROC_VER2         - THE PROCESSING VERSION OF THE 2ND SENSOR E.G. 'Collection_5'
;*      CHI_THRESHOLD     - THE CHI THRESHOLD VALUE AS RETURNED BY COMPUTE_CHI_THRESHOLD.PRO
;*      DAY_OFFSET        - THE NUMBER OF DAYS DIFFERENCE ALLOWED BETWEEN DOUBLETS E.G 2
;*      CLOUD_PERCENTAGE  - THE PERCENTAGE CLOUD COVER THRESHOLD ALLOWED WITHIN PRODUCTS E.G. 60.0 
;*      ROI_PERCENTAGE    - THE PERCENTAGE ROI COVERAGE ALLOWED WITHIN PRODUCTS E.G. 75.0     
;*      VZA_MIN           - THE MINIMUM VIEWING ZENITH ANGLE ALLOWED FOR AN OBSERVATION
;*      VZA_MAX           - THE MAXIMUM VIEWING ZENITH ANGLE ALLOWED FOR AN OBSERVATION
;*      VAA_MIN           - THE MINIMUM VIEWING AZIMUTH ANGLE ALLOWED FOR AN OBSERVATION
;*      VAA_MAX           - THE MAXIMUM VIEWING AZIMUTH ANGLE ALLOWED FOR AN OBSERVATION
;*      SZA_MIN           - THE MINIMUM SOLAR ZENITH ANGLE ALLOWED FOR AN OBSERVATION
;*      SZA_MAX           - THE MAXIMUM SOLAR ZENITH ANGLE ALLOWED FOR AN OBSERVATION
;*      SAA_MIN           - THE MINIMUM SOLAR AZIMUTH ANGLE ALLOWED FOR AN OBSERVATION
;*      SAA_MAX           - THE MAXIMUM SOLAR AZIMTUH ANGLE ALLOWED FOR AN OBSERVATION
;*
;* KEYWORDS:
;*      VERBOSE           - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      STATUS            - 1: NO ERRORS REPORTED, (-1) OR 0: ERRORS DURING INGESTION 
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*        18 JAN 2011 - C KENT    - DIMITRI-2 V1.0
;*        21 MAR 2011 - C KENT    - MODIFIED FILE DEFINITION TO USE GET_DIMITRI_LOCATION
;*        02 JUL 2011 - C KENT    - ADDED ABSOLUTE ANGULAR CRITERIA
;*
;* VALIDATION HISTORY:
;*        02 DEC 2010 - C KENT    - WINDOWS 32-BIT MACHINE IDL 8.0: COMPILATION SUCCESSFUL. 
;*                                  RESULTS NOMINAL FOR AATSR VS ATSR2 OVER UYUNI IN 2003.
;*        13 APR 2011 - C KENT    - LINUX 64-BIT MACHINE IDL 8.0: COMPILATION AND OPERATION 
;*                                  NOMINAL
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION DIMITRI_INTERFACE_DOUBLET,OUTPUT_FOLDER,ED_REGION,SENSOR1,PROC_VER1,SENSOR2,PROC_VER2,CHI_THRESHOLD,$
                                   DAY_OFFSET,CLOUD_PERCENTAGE,ROI_PERCENTAGE,                               $
                                   VZA_MIN,VZA_MAX,VAA_MIN,VAA_MAX,SZA_MIN,SZA_MAX,SAA_MIN,SAA_MAX,          $
                                   VERBOSE=VERBOSE

;--------------------------------
; COMPUTE DIMITRI DIRECTORY

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI INTERFACE DOUBLET: STARTING DOUBLET EXTRACTION'

;--------------------------------
; DEFINE MAIN DIRECTORY, REGION, 
; SENSOR1 AND SENSOR2 FOLDERS  

  DL            = GET_DIMITRI_LOCATION('DL')
  INPUT_FOLDER  = GET_DIMITRI_LOCATION('INPUT')
  RFOLDER       = INPUT_FOLDER+'Site_'+ED_REGION
  S1_FOLDER     = STRING(RFOLDER+DL+SENSOR1+DL+'Proc_'+PROC_VER1)
  S2_FOLDER     = STRING(RFOLDER+DL+SENSOR2+DL+'Proc_'+PROC_VER2)

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI INTERFACE DOUBLET: SENSOR1 FOLDER = ',S1_FOLDER
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI INTERFACE DOUBLET: SENSOR2 FOLDER = ',S2_FOLDER

;--------------------------------
; CREATE OUTPUT FOLDER IF IT DOESN'T EXIST

  RES = FILE_INFO(OUTPUT_FOLDER)
  IF RES.EXISTS NE 1 OR RES.DIRECTORY NE 1 THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT,"DIMITRI INTERFACE DOUBLET: OUTPUT FOLDER DOESN'T EXIST, CREATING"
    FILE_MKDIR,OUTPUT_FOLDER 
  ENDIF
  
;--------------------------------
; CHANGE OUTPUT_FOLDER TO OFOLDER
  
  RES = STRMID(OUTPUT_FOLDER,STRLEN(OUTPUT_FOLDER)-1,1)
  IF STRCMP(RES,DL) EQ 0 THEN OFOLDER = STRING(OUTPUT_FOLDER+DL) ELSE OFOLDER = OUTPUT_FOLDER

;--------------------------------
; CHECK REGION IS A DIMITRI VALIDATION 
; SITE AND SENSOR INFORMATION IS CORRECT

  RES1 = FILE_INFO(RFOLDER)
  RES2 = FILE_INFO(S1_FOLDER)
  RES3 = FILE_INFO(S2_FOLDER)
  IF  RES1.EXISTS EQ 0 OR $
      RES2.EXISTS EQ 0 OR $
      RES3.EXISTS EQ 0 THEN BEGIN
      PRINT, 'DIMITRI INTERFACE DOUBLET: ERROR, REGION AND SENSOR CONFIGURATION INCORRECT' 
      RETURN,-1
  ENDIF
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI INTERFACE DOUBLET: REGION AND SENSOR DATA VALID'

;--------------------------------
; CHECK USER PARAMETERS ARE VALID

  CHI_THRESHOLD     = FLOAT(CHI_THRESHOLD)
  DAY_OFFSET        = FIX(DAY_OFFSET)
  CLOUD_PERCENTAGE  = CLOUD_PERCENTAGE>0.0
  CLOUD_PERCENTAGE  = CLOUD_PERCENTAGE<100.0
  ROI_PERCENTAGE    = ROI_PERCENTAGE>0.0
  ROI_PERCENTAGE    = ROI_PERCENTAGE<100.0
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI INTERFACE DOUBLET: USER PARAMETERS APPEAR VALID'

;--------------------------------  
; CALL EXTRACT DOUBLET FUNCTION
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI INTERFACE DOUBLET: CALLING DOUBLET EXTRACTION ROUTINE'
  RES = EXTRACT_DOUBLETS(OFOLDER,ED_REGION,SENSOR1,PROC_VER1,SENSOR2,PROC_VER2,CHI_THRESHOLD, $
                         DAY_OFFSET,CLOUD_PERCENTAGE,ROI_PERCENTAGE,                          $
                         VZA_MIN,VZA_MAX,VAA_MIN,VAA_MAX,SZA_MIN,SZA_MAX,SAA_MIN,SAA_MAX,VERBOSE=VERBOSE)

;--------------------------------  
; CHECK RETURN PARAMETER
  
  IF RES NE 1 THEN BEGIN
    PRINT, 'DIMITRI INTERFACE DOUBLET: ERROR OCCURED DURING DOUBLET EXTRACTION'
    RETURN,-1
  ENDIF ELSE BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI INTERFACE DOUBLET: DOUBLET EXTRACTION SUCCESSFUL'
    RETURN,1
  ENDELSE

END