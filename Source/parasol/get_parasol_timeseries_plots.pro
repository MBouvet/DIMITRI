;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      GET_AATSR_TIMESERIES_PLOTS       
;* 
;* PURPOSE:
;*      GENERATES PLOTS FROM THE SUPPLIED TIME SERIES OF DIMITRI AATSR DATA.
;* 
;* CALLING SEQUENCE:
;*      RES = GET_PARASOL_TIMESERIES_PLOTS(OUTPUT_SAV)      
;* 
;* INPUTS:
;*      OUTPUT_SAV  -  STRING OF THE SENSOR/PROCESSING OUTPUT SAV      
;*
;* KEYWORDS:
;*      COLOUR_TABLE      - USER DEFINED IDL COLOUR TABLE INDEX (DEFAULT IS 39)
;*      PLOT_XSIZE        - WIDTH OF GENERATED PLOTS (DEFAULT IS 700PX)
;*      PLOT_YSIZE        - HEIGHT OF GENERATED PLOTS (DEFAULT IS 400PX)
;*      NO_ZBUFF          - IF SET THEN PLOTS ARE GENERATED IN WINDOWS AND NOT 
;*                          WITHIN THE Z-BUFFER.
;*      VERBOSE           - PROCESSING STATUS OUTPUTS      
;*
;* OUTPUTS:
;*      PLOTS OF TOA REFLECTANCE, REFLECTANCE EVOLUTION, SOLAR ZENITH ANGLE AND SENSOR 
;*      ZENITH ANGLE AUTOMATICALLY SAVED.  
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      13 DEC 2010 - C KENT   - DIMITRI-2 V1.0
;*      06 JAN 2011 - C KENT   - MODIFIED TOA REF PLOTS TO INCLUDE DIRECTIONS 
;*                               SEPERATELY
;*      07 JAN 2011 - C KENT   - DIMITRI-2 V2.0, MAJOR REVISION, ADDEDD FOR LOOP TO PROVIDE 
;*                               ANALYSIS FOR EACH DIRECTION
;*      10 JAN 2011 - C KENT   - CHANGED INPUT VARIABLE TO SENSOR_L1B_REF
;*      12 JAN 2011 - C KENT   - UPDATED TO REFLECT CHANGES IN SENSORS_L1B_REF (INCLUDES VAA AND SAA)
;*      22 MAR 2011 - C KENT   - ADDED CONFIGURATION FILE DEPENDENCE
;*      04 JUL 2011 - C KENT   - ADDED AUX INFO TO OUTPUT SAV
;*
;* VALIDATION HISTORY:
;*      13 DEC 2010 - C KENT   - WINDOWS 32-BIT MACHINE IDL 7.1: COMPILATION SUCCESSFUL,
;*                               ZBUFFER AND NOMINAL PLOTS PRODUCED OK.
;*      06 JAN 2010 - C KENT   - LINUX 64-BIT MACHINE IDL 8.0: COMPILATION SUCCESSFUL,
;*                               VALUES EQUAL TO WINDOWS 32-BIT MACHINE
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION GET_PARASOL_TIMESERIES_PLOTS,OUTPUT_SAV,NO_ZBUFF=NO_ZBUFF,COLOUR_TABLE=COLOUR_TABLE,PLOT_XSIZE=PLOT_XSIZE,PLOT_YSIZE=PLOT_YSIZE,VERBOSE=VERBOSE

;------------------------------------------------
; SET KEYWORD VALUES

  CFIG_DATA = GET_DIMITRI_CONFIGURATION()
  IF NOT KEYWORD_SET(COLOUR_TABLE) THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL_TIMESERIES_PLOTS: NO COLOR_TABLE SET, USING DEFAULT OF 39'
    COLOUR_TABLE = CFIG_DATA.(1)[2]
  ENDIF
  IF NOT KEYWORD_SET(PLOT_XSIZE) THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL_TIMESERIES_PLOTS: PLOT_XSIZE NOT SET, USING DEFAULT OF 700'
    PLOT_XSIZE = CFIG_DATA.(1)[0]
  ENDIF
  IF NOT KEYWORD_SET(PLOT_YSIZE) THEN BEGIN
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL_TIMESERIES_PLOTS: PLOT_YSIZE NOT SET, USING DEFAULT OF 400'
    PLOT_YSIZE = CFIG_DATA.(1)[1]
  ENDIF 

;-----------------------------------------------
; RESTORE THE L1B REFLECTANCE

  TEMP = FILE_INFO(OUTPUT_SAV)
  IF TEMP.EXISTS EQ 1 THEN BEGIN
    RESTORE,OUTPUT_SAV
  ENDIF ELSE BEGIN
    PRINT, 'PARASOL_TIMESERIES_PLOTS: ERROR, OUTPUT_SAV DOES NOT EXIST'
    RETURN,-1
  ENDELSE

;------------------------------------------------
; GET THE SIZE DIMENSIONS OF INPUT L1B TIMESERIES (NOTE, EXPECTING DIMITRI-PARASOL VARIABLE STRUCTURE)

  NUM_NON_REFS = 5+12
  NB_BANDS = 9
  NB_COLS = NUM_NON_REFS+2*NB_BANDS
  RES = SIZE(SENSOR_L1B_REF)
  IF RES[1] NE NB_COLS THEN BEGIN
    PRINT, 'PARASOL_TIMESERIES_PLOTS: ERROR, INPUT L1B VARIABLE STRUCTURE MUST BE IN DIMITRI FORMAT'
    RETURN, -1
  ENDIF 

;------------------------------------------------
; SETUP WINDOW PROPERTIES

  MACHINE_WINDOW = !D.NAME
  IF NOT KEYWORD_SET(NO_ZBUFF) THEN BEGIN
  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL_TIMESERIES_PLOTS: GENERATING PLOTS WITHIN Z-BUFFER'
  SET_PLOT, 'Z'
  DEVICE, SET_RESOLUTION=[PLOT_XSIZE,PLOT_YSIZE],SET_PIXEL_DEPTH=24
  ERASE  
  ENDIF ELSE WINDOW,XSIZE = PLOT_XSIZE,YSIZE=PLOT_YSIZE
  DEVICE, DECOMPOSED = 0
  LOADCT, COLOUR_TABLE

;------------------------------------------------
; DEFINE OUTPUT FILENAMES BASED ON OUTPUT_SAV

  OUTPUT_BASE = STRMID(OUTPUT_SAV,0,STRLEN(OUTPUT_SAV)-11)
  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL_TIMESERIES_PLOTS: OUTPUT_BASE = ',OUTPUT_BASE
 
;------------------------------------------------
; DEFINE INDEX ARRAYS FOR FWARD AND NADIR VIEWS

  DIR_STR =['DIR_1','DIR_2','DIR_3','DIR_4','DIR_5','DIR_6','DIR_7','DIR_8','DIR_9','DIR_10','DIR_11','DIR_12','DIR_13','DIR_14','DIR_15','DIR_16']
  NUM_DIR = N_ELEMENTS(DIR_STR)
  NUM_DATA = N_ELEMENTS(SENSOR_L1B_REF[0,*])
  DIR_IDX = MAKE_ARRAY(NUM_DATA/NUM_DIR,NUM_DIR,/FLOAT)
  
  FOR I=0l,NUM_DIR-1 DO BEGIN
   FOR J=0l,NUM_DATA/NUM_DIR-1 DO BEGIN
    DIR_IDX[J,I] = I+J*16
   ENDFOR
  ENDFOR

;-----------------------------------------------
; LOOP OVER EACH DIRECTION 
  
  FOR TP_DIR = 0,N_ELEMENTS(DIR_STR)-1 DO BEGIN
  
    TEMP_IDX = DIR_IDX[*,TP_DIR]

;-----------------------------------------------
; FIND ONLY THE GOOD DATA

    RES = WHERE(SENSOR_L1B_REF[NUM_NON_REFS,TEMP_IDX] GT 0.0 and SENSOR_L1B_REF[NUM_NON_REFS,TEMP_IDX] lt 1.0)
    IF RES[0] EQ -1 THEN RETURN,-1
    PARASOL_L1B_REF_GD = SENSOR_L1B_REF[*,TEMP_IDX[RES]]  

    YMIN = 0.0
    YMAX = 1.0

;------------------------------------------------
; PLOT REFLECTANCE DATA AGAINST DOY

    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL_TIMESERIES_PLOTS: PLOTTING TOA REFLECTANCE AGAINST DOY, DIRECTION: ',DIR_STR[TP_DIR]
    PLOT,PARASOL_L1B_REF_GD[0,*],PARASOL_L1B_REF_GD[NUM_NON_REFS,*],/NODATA,$
    COLOR = 0, BACKGROUND = 255,$
    YTITLE = 'TOA REFLECTANCE (DL)',$
    XTITLE = 'DECIMAL YEAR',$
    YRANGE = [YMIN,YMAX],$
    XTICKFORMAT='((F8.3))'

    FOR PLOT_BAND=0,NB_BANDS-1 DO BEGIN
      TT = WHERE(PARASOL_L1B_REF_GD[NUM_NON_REFS+PLOT_BAND,*] GT 0.0 AND PARASOL_L1B_REF_GD[NUM_NON_REFS+PLOT_BAND,*] LT 1.0)
      IF TT[0] GT -1 THEN OPLOT, PARASOL_L1B_REF_GD[0,TT],PARASOL_L1B_REF_GD[NUM_NON_REFS+PLOT_BAND,TT],COLOR = 250.*PLOT_BAND/NB_BANDS
    ENDFOR

    TEMP = TVRD(TRUE=1)
    OUTPUT_IMAGE = STRING(OUTPUT_BASE+DIR_STR[TP_DIR]+'_TOA_REFLECTANCE.jpg')
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL_TIMESERIES_PLOTS: REFLECTANCE OUTPUT AT ',OUTPUT_IMAGE
    WRITE_JPEG,OUTPUT_IMAGE,TEMP,TRUE=1,QUALITY=100
    ERASE
 
;----------------------------------------------
;PLOT REFLECTANCE EVOLUTION AGAINST DOY

    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL_TIMESERIES_PLOTS: PLOTTING TOA REFLECTANCE EVOLUTION AGAINST DOY, DIRECTION: ',DIR_STR[TP_DIR]
    PLOT,PARASOL_L1B_REF_GD[0,*],100.0*(PARASOL_L1B_REF_GD[NUM_NON_REFS,*]-PARASOL_L1B_REF_GD[NUM_NON_REFS,0])/PARASOL_L1B_REF_GD[NUM_NON_REFS,0],/NODATA,$
    COLOR = 0, BACKGROUND = 255,$
    YTITLE = 'TOA REFLECTANCE EVOLUTION (%)',$
    XTITLE = 'DECIMAL YEAR',$
    XTICKFORMAT='((F8.3))'
 
    FOR PLOT_BAND=0,NB_BANDS-1 DO BEGIN
      TT = WHERE(PARASOL_L1B_REF_GD[NUM_NON_REFS+PLOT_BAND,*] GT 0.0 AND PARASOL_L1B_REF_GD[NUM_NON_REFS+PLOT_BAND,*] LT 1.0)
      IF TT[0] GT -1 THEN OPLOT, PARASOL_L1B_REF_GD[0,TT],100.0*(PARASOL_L1B_REF_GD[NUM_NON_REFS+PLOT_BAND,TT]-PARASOL_L1B_REF_GD[NUM_NON_REFS+PLOT_BAND,0])/PARASOL_L1B_REF_GD[NUM_NON_REFS+PLOT_BAND,0],$
      COLOR = 250.*PLOT_BAND/NB_BANDS
    ENDFOR

    TEMP = TVRD(/TRUE)
    OUTPUT_IMAGE = STRING(OUTPUT_BASE+DIR_STR[TP_DIR]+'_TOA_EVOLUTION.jpg')
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL_TIMESERIES_PLOTS: EVOLUTION OUTPUT AT ',OUTPUT_IMAGE
    WRITE_JPEG,OUTPUT_IMAGE,TEMP,TRUE=1,QUALITY=100
    ERASE 

;-----------------------------------------------
; PLOT SOLAR ZENITH AGAINST DOY

    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL_TIMESERIES_PLOTS: PLOTTING SOLAR ZENITH AGAINST DOY, DIRECTION: ',DIR_STR[TP_DIR] 
    PLOT,PARASOL_L1B_REF_GD[0,*],PARASOL_L1B_REF_GD[3,*],/NODATA,$
    COLOR = 0, BACKGROUND = 255,$
    YTITLE = 'SOLAR ZENITH OVER ROI (DEGREES)',$
    XTITLE = 'DECIMAL YEAR',$
    XTICKFORMAT='((F8.3))'
  
    OPLOT,PARASOL_L1B_REF_GD[0,*],PARASOL_L1B_REF_GD[3,*],$
    PSYM = 2,$
    COLOR = 70

    TEMP = TVRD(/TRUE)
    OUTPUT_IMAGE = STRING(OUTPUT_BASE+DIR_STR[TP_DIR]+'_SOLAR_ZENITH_ANGLE.jpg')
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL_TIMESERIES_PLOTS: SOLAR ZENITH OUTPUT AT ',OUTPUT_IMAGE
    WRITE_JPEG,OUTPUT_IMAGE,TEMP,TRUE=1,QUALITY=100
    ERASE 

;-----------------------------------------------
; PLOT SENSOR ZENITH AGAINST DOY

    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL_TIMESERIES_PLOTS: PLOTTING SENSOR ZENITH AGAINST DOY, DIRECTION: ',DIR_STR[TP_DIR] 
    PLOT,PARASOL_L1B_REF_GD[0,*],PARASOL_L1B_REF_GD[1,*],/NODATA,$
    COLOR = 0, BACKGROUND = 255,$
    YTITLE = 'SENSOR ZENITH OVER ROI (DEGREES)',$
    XTITLE = 'DECIMAL YEAR',$
    XTICKFORMAT='((F8.3))'
  
    OPLOT,PARASOL_L1B_REF_GD[0,*],PARASOL_L1B_REF_GD[1,*],$
    PSYM = 2,$
    COLOR = 250

    TEMP = TVRD(/TRUE)
    OUTPUT_IMAGE = STRING(OUTPUT_BASE+DIR_STR[TP_DIR]+'_SENSOR_ZENITH_ANGLE.jpg')
    IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL_TIMESERIES_PLOTS: SENSOR ZENITH OUTPUT AT ',OUTPUT_IMAGE
    WRITE_JPEG,OUTPUT_IMAGE,TEMP,TRUE=1,QUALITY=100
    ERASE 
  
  ENDFOR

;-----------------------------------------------
; RETURN DEVICE WINDOW TO NOMINAL SETTING
 
  IF KEYWORD_SET(VERBOSE) THEN PRINT, 'PARASOL_TIMESERIES_PLOTS: RESETTING DEVICE WINDOW PROPERTIES'
  IF KEYWORD_SET(NO_ZBUFF) THEN WDELETE
  SET_PLOT, MACHINE_WINDOW
  RETURN,1

END