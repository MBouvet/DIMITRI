;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DIMITRI_DATABASE_PLOTS_WD     
;* 
;* PURPOSE:
;*      THIS IS THE MAIN PROGRAM FOR PLOTTING THE ACQUISITION STATISTICS CONTAINED IN 
;*      THE DIMITRI DATABASE FILE. THIS PROGRAM GENERATES AN OBJECT GRAPHICS WIDGET 
;*      ALLOW THE USER TO OVERLAY MULTIPLE SENSOR CONFIGURATIONS. 
;*
;*      THIS FILE CONTAINS A NUMBER OF SMALLER PROGRAMS USED TO ALLOW SAVING AND 
;*      EXITING OF THE PLOTS WIDGET.
;*
;* CALLING SEQUENCE:
;*      DIMITRI_DATABASE_PLOTS_WD,DATA,VAL_SITE,LEADER_ID     
;*
;* INPUTS:
;*      DATA      - THE DATABASE DATA STRUCTURE (IN TEMPLATE RETURNED BY GET_DIMITRI_TEMPLATE)
;*      VAL_SITE  - A STRING OF THE VALIDATION SITE NAME
;*      LEADER_ID - THE ID FOR THE STATS WIDGET BASE, USED AS THE WIDGET GROUP LEADER
;*
;* KEYWORDS:
;*      VERBOSE   - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      NONE
;*
;* COMMON BLOCKS:
;*      DHMI_DATABASE - CONTAINS THE DATABASE DATA FOR THE DIMITRI HMI
;*
;* MODIFICATION HISTORY:
;*      17 FEB 2011 - C KENT    - DIMITRI-2 V1.0
;*      18 FEB 2011 - C KENT    - UPDATED PLOT DYNAMICS INCLUDING FONT SIZE
;*      21 FEB 2011 - C KENT    - ADDED SYSTEM DEPENDENCE ON FONT SIZE
;*      22 MAR 2011 - C KENT    - ADDED CONFIGURAITON FILE DEPENDENCE
;*      06 JUL 2011 - C KENT    - ADDED DATABASE COMMON BLOCK TO DIMITRI HMI, 
;*                                CHANGED PLOT TO BE A BAR PLOT
;*
;* VALIDATION HISTORY:
;*      17 FEB 2011 - C KENT    - WINDOWS 32-BIT MACHINE IDL 7.1/IDL 8.0: NOMINAL 
;*      18 FEB 2011 - C KENT    - LINUX 64-BIT MACHINE IDL 8.0: NOMINAL BEHAVIOUR
;*      14 APR 2011 - C KENT    - WINDOWS 32-BIT IDL 7.1 AND LINUX 64-BIT IDL 8.0 NOMINAL
;*                                COMPILATION AND OPERATION
;*
;**************************************************************************************
;**************************************************************************************

PRO PLOT_OBJECT_OPTION,EVENT

  WIDGET_CONTROL, EVENT.TOP, GET_UVALUE=PLOTS_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,  GET_UVALUE=ACTION

;------------------------------------
; IF NO ACTION THEN GO BACK TO THE PLOT

  IF N_ELEMENTS(ACTION) EQ 0 THEN GOTO, NO_OPTION

  CASE ACTION OF

;------------------------------------
; RESET THE PLOT TO THE INITIAL SETTINGS
  
  'RESET':BEGIN
   IF PLOTS_INFO.VERBOSE EQ 1 THEN PRINT,'DIMITRI_DATABASE_PLOTS->OPTION: RESETTING THE PLOT'
              PLOTS_INFO.ACQ_CFIG_ON[*] = 0
              FOR I=0,PLOTS_INFO.NPT_CONFIGS-1 DO $
                  PLOTS_INFO.ACQ_PLOT_MOD[0,I]->SETPROPERTY,DATAX=[0.0],DATAY=[0.0]
              PLOTS_INFO.STATS_LEGEND->GETPROPERTY,HIDE=TEMP
              IF TEMP EQ 0 THEN PLOTS_INFO.STATS_LEGEND->SETPROPERTY,HIDE=1

              OBJ_DESTROY,PLOTS_INFO.STATS_YAXIS
              PLOTS_INFO.STATS_YAXIS = OBJ_NEW('IDLGRAXIS', 1, TICKLEN=0.025, TITLE=PLOTS_INFO.YTITLE, $
                                        RANGE=[0,1],/EXACT,MINOR=0)

              PLOTS_INFO.STATS_YAXIS->GETPROPERTY,TICKTEXT=TEMP_TEXTY
              TEMP_TEXTY->SETPROPERTY,FONT=PLOTS_INFO.STATS_FONT
              PLOTS_INFO.STATS_MODEL->ADD,    PLOTS_INFO.STATS_YAXIS
              PLOTS_INFO.STATS_WINDOW->DRAW,  PLOTS_INFO.STATS_VIEW
              PLOTS_INFO.YRANGE=[0,1]
          END

;------------------------------------
; TURN THE LEGEND ON/OFF

  'LEGEND':BEGIN
   IF PLOTS_INFO.VERBOSE EQ 1 THEN PRINT,'DIMITRI_DATABASE_PLOTS->OPTION: SWITCHING THE LEGEND ON/OFF'
              PLOTS_INFO.STATS_LEGEND->GETPROPERTY,HIDE=TEMP
              IF TEMP EQ 0 THEN BEGIN 
                PLOTS_INFO.STATS_LEGEND->SETPROPERTY,HIDE=1
                GOTO,LEGEND_SWITCH
              ENDIF
              
              RES = WHERE(PLOTS_INFO.ACQ_CFIG_ON EQ 1,COUNT)
              IF COUNT EQ 0 THEN GOTO,LEGEND_SWITCH
              PLOTS_INFO.STATS_LEGEND->SETPROPERTY, ITEM_NAME  = PLOTS_INFO.LEGEND_NAMES[RES] ,$ 
                                       ITEM_COLOR = PLOTS_INFO.COLOURS[*,RES]                 ,$
                                       THICK      = MAKE_ARRAY(N_ELEMENTS(RES),VALUE=2)       ,$
                                       HIDE       = 0
           LEGEND_SWITCH:
           END
  ENDCASE

;------------------------------------
; REDRAW THE PLOT

  IF PLOTS_INFO.VERBOSE EQ 1 THEN PRINT,'DIMITRI_DATABASE_PLOTS->OPTION: REDRAWING THE PLOT'
  NO_OPTION:
  PLOTS_INFO.STATS_WINDOW->DRAW, PLOTS_INFO.STATS_VIEW 
  WIDGET_CONTROL, EVENT.TOP, SET_UVALUE = PLOTS_INFO,/NO_COPY
END

;**************************************************************************************
;**************************************************************************************

PRO PLOT_OBJECT_EXPORT,EVENT

  WIDGET_CONTROL, EVENT.TOP, GET_UVALUE=PLOTS_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,  GET_UVALUE=ACTION

;------------------------------------
; IF NO ACTION THEN GO BACK TO THE PLOT

  IF N_ELEMENTS(ACTION) EQ 0 THEN GOTO, NO_EXPORT

;------------------------------------
; RETRIEVE THE IMAGE VIEW

  IF PLOTS_INFO.VERBOSE EQ 1 THEN PRINT,'DIMITRI_DATABASE_PLOTS->EXPORT: RETRIEVEING THE IMAGE VIEW'
  PLOTS_INFO.STATS_WINDOW->GETPROPERTY, IMAGE_DATA = PLOTS_IMAGE   
  PLOTS_IMAGE2 = COLOR_QUAN(PLOTS_IMAGE,1,R,G,B)
  FTEMP        = 'DIMITRI_ACQUISITION_STATS_'+PLOTS_INFO.VAL_SITE

  CASE ACTION OF

;------------------------------------
; SAVE AS A PNG
 
    'PNG':  BEGIN
    IF PLOTS_INFO.VERBOSE EQ 1 THEN PRINT,'DIMITRI_DATABASE_PLOTS->EXPORT: SAVING AS PNG'
             FILENAME = DIALOG_PICKFILE(/WRITE,FILE=FTEMP+'.png',/OVERWRITE_PROMPT)
              IF FILENAME NE '' THEN WRITE_PNG,FILENAME,PLOTS_IMAGE2,R,G,B
            END
 
;------------------------------------
; SAVE AS A JPG

    'JPG':  BEGIN
    IF PLOTS_INFO.VERBOSE EQ 1 THEN PRINT,'DIMITRI_DATABASE_PLOTS->EXPORT: SAVING AS JPG'
              FILENAME = DIALOG_PICKFILE(/WRITE,FILE=FTEMP+'.jpg',/OVERWRITE_PROMPT)
              IF FILENAME NE '' THEN WRITE_JPEG,FILENAME,PLOTS_IMAGE,TRUE=1
            END  

;------------------------------------
; SAVE AS A CSV

    'CSV':  BEGIN
    IF PLOTS_INFO.VERBOSE EQ 1 THEN PRINT,'DIMITRI_DATABASE_PLOTS->EXPORT: SAVING AS CSV'
              FILENAME = DIALOG_PICKFILE(/WRITE,FILE=FTEMP+'.csv',/OVERWRITE_PROMPT)
              IF FILENAME EQ '' THEN GOTO, NO_EXPORT
  
;------------------------------------ 
; OPEN THE CSV FILE AND PRINT THE HEADER
 
     IF PLOTS_INFO.VERBOSE EQ 1 THEN PRINT,'DIMITRI_DATABASE_PLOTS->EXPORT: OPENING THE FILE AND PRINTING THE HEADER'
              OPENW,OUTF,FILENAME,/GET_LUN
              TMP_HD  = STRTRIM(STRING(PLOTS_INFO.YEARS),2)
              HEADER  = ['SENSOR_CONFIGURATION',TMP_HD]
              TMP     = N_ELEMENTS(PLOTS_INFO.YEARS)
              FORMAT  = '('+STRTRIM(STRING(TMP),2)+'(A,1H;),(A))'
              PRINTF,OUTF,FORMAT=FORMAT,HEADER
  
;------------------------------------ 
; LOOP OVER EACH DATASET AND PRINT THE DATA

    IF PLOTS_INFO.VERBOSE EQ 1 THEN $
      PRINT,'DIMITRI_DATABASE_PLOTS->EXPORT: LOOPING OVER EACH CONFIG AND PRINTING THE DATA'  
              RES = WHERE(PLOTS_INFO.ACQ_CFIG_ON EQ 1,COUNT)
              IF COUNT GT 0 THEN BEGIN
                FOR I=0,COUNT-1 DO BEGIN
                  FORMAT = '(1(A,1H;),'+STRTRIM(STRING(TMP-1),2)+'(I,1H;),1(I) )'
                  PRINTF,OUTF,FORMAT=FORMAT,PLOTS_INFO.PT_CONFIGS[RES[I]],PLOTS_INFO.ALL_DATA[*,RES[I]]
                ENDFOR
              ENDIF
              FREE_LUN,OUTF
            END
  ENDCASE

;------------------------------------
; REDRAW THE PLOT

  IF PLOTS_INFO.VERBOSE EQ 1 THEN PRINT,'DIMITRI_DATABASE_PLOTS->EXPORT: REDRAWING THE PLOT'
  NO_EXPORT:
  PLOTS_INFO.STATS_WINDOW->DRAW, PLOTS_INFO.STATS_VIEW 
  WIDGET_CONTROL, EVENT.TOP, SET_UVALUE = PLOTS_INFO,/NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO PLOT_OBJECT_EXIT,EVENT

;------------------------------------
; CLEANUP OBJECTS FROM MEMORY  
  
  WIDGET_CONTROL, EVENT.TOP, GET_UVALUE = PLOTS_INFO, /NO_COPY
  OBJ_DESTROY,    PLOTS_INFO.STATS_PALETTE
  OBJ_DESTROY,    PLOTS_INFO.STATS_FONT
  OBJ_DESTROY,    PLOTS_INFO.XTITLE               
  OBJ_DESTROY,    PLOTS_INFO.YTITLE
  OBJ_DESTROY,    PLOTS_INFO.STATS_XAXIS
  OBJ_DESTROY,    PLOTS_INFO.STATS_YAXIS
  OBJ_DESTROY,    PLOTS_INFO.STATS_LEGEND
  OBJ_DESTROY,    PLOTS_INFO.STATS_MODEL
  OBJ_DESTROY,    PLOTS_INFO.STATS_LEGENDMODEL
  OBJ_DESTROY,    PLOTS_INFO.STATS_VIEW
  OBJ_DESTROY,    PLOTS_INFO.STATS_WINDOW
  OBJ_DESTROY,    PLOTS_INFO.ACQ_PLOT_MOD
  WIDGET_CONTROL, EVENT.TOP, /DESTROY
  IF PLOTS_INFO.VERBOSE EQ 1 THEN PRINT,'DIMITRI_DATABASE_PLOTS->EXIT: DESTROYING THE PLOT WIDGET'
  
END

;**************************************************************************************
;**************************************************************************************

PRO PLOTS_OBJECT_PLOT,EVENT

  WIDGET_CONTROL, EVENT.TOP, GET_UVALUE=PLOTS_INFO, /NO_COPY
  WIDGET_CONTROL, EVENT.ID,  GET_UVALUE=ACTION

;------------------------------------
; CHECK IF CURRENT SELECTION IS ALREADY PLOTTED

  IF PLOTS_INFO.VERBOSE EQ 1 THEN PRINT,'DIMITRI_DATABASE_PLOTS->PLOT: CHECKING WHICH DATA IS PLOTTED'
  RES = WHERE(PLOTS_INFO.PT_CONFIGS EQ ACTION)
  IF RES[0] EQ -1 THEN GOTO, NO_ACTION
  IF PLOTS_INFO.ACQ_CFIG_ON[RES] EQ 1 THEN GOTO, NO_ACTION

;------------------------------------
; GET RANGE OF CURRENT Y AXIS

  IF PLOTS_INFO.VERBOSE EQ 1 THEN PRINT,'DIMITRI_DATABASE_PLOTS->PLOT: DEFINING NEW Y-RANGE DATA'
  YPLOT_RANGE = PLOTS_INFO.YRANGE
  XPLOT_RANGE = PLOTS_INFO.BASE_XRANGE
  NEWYMIN = FLOOR(MIN(PLOTS_INFO.ALL_DATA[*,RES])) MOD 2 EQ 1 ? FLOOR(MIN(PLOTS_INFO.ALL_DATA[*,RES]))-1 : FLOOR(MIN(PLOTS_INFO.ALL_DATA[*,RES]))
  NEWYMAX= FLOOR(MAX(PLOTS_INFO.ALL_DATA[*,RES])) MOD 2 EQ 1 ? FLOOR(MAX(PLOTS_INFO.ALL_DATA[*,RES]))+1 : FLOOR(MAX(PLOTS_INFO.ALL_DATA[*,RES]))

;------------------------------------
; DEFINE NEW RANGE IF NEEDED

  IF NEWYMIN LT YPLOT_RANGE[0] THEN MINY = NEWYMIN ELSE  MINY=YPLOT_RANGE[0]
  IF NEWYMAX GT YPLOT_RANGE[1] THEN MAXY = NEWYMAX ELSE  MAXY=YPLOT_RANGE[1]
  MAXY = CEIL(MAXY/10.)*10
  PLOTS_INFO.YRANGE=[MINY,MAXY]

  TRANGE      = MAXY-MINY
  TTICK       = CEIL((TRANGE)/10.0)
  TTICK       = 1+TRANGE/TTICK

;------------------------------------
; DESTROY THE OLD AXIS AND CREATE A NEW ONE

  IF PLOTS_INFO.VERBOSE EQ 1 THEN PRINT,'DIMITRI_DATABASE_PLOTS->PLOT: DESTROYING OLD Y-AXIS, CREATING A NEW ONE'
  OBJ_DESTROY,PLOTS_INFO.STATS_YAXIS
  PLOTS_INFO.STATS_YAXIS = OBJ_NEW('IDLGRAXIS', 1, TICKLEN=0.025, TITLE=PLOTS_INFO.YTITLE ,MAJOR=TTICK, $
                                    RANGE=[MINY,MAXY],/EXACT,MINOR=0                      ,$
                                    YCOORD_CONV=NORM_COORD([MINY,MAXY]))

  ;IF MAXY LE 10 THEN TICKINTERVAL=1 ELSE TICKINTERVAL=MAXY/10.
  ;PLOTS_INFO.STATS_YAXIS->SETPROPERTY,TICKINTERVAL=TICKINTERVAL
  PLOTS_INFO.STATS_YAXIS->GETPROPERTY,TICKTEXT=TEMP_TEXTY
  TEMP_TEXTY->SETPROPERTY,FONT=PLOTS_INFO.STATS_FONT
  PLOTS_INFO.STATS_MODEL->ADD,    PLOTS_INFO.STATS_YAXIS
  PLOTS_INFO.STATS_WINDOW->DRAW,  PLOTS_INFO.STATS_VIEW

;------------------------------------
; PLOT ALL DATA REQUESTED

  IF PLOTS_INFO.VERBOSE EQ 1 THEN PRINT,'DIMITRI_DATABASE_PLOTS->PLOT: REPLOTTING ALL DATA'  
  PLOTS_INFO.ACQ_CFIG_ON[RES] = 1
  RES = WHERE(PLOTS_INFO.ACQ_CFIG_ON EQ 1,COUNT)
  FOR I=0,COUNT-1 DO BEGIN
    PLOTS_INFO.ACQ_PLOT_MOD[0,RES[I]]->SETPROPERTY,DATAX=PLOTS_INFO.YEARS               ,$
                                                   DATAY=PLOTS_INFO.ALL_DATA[*,RES[I]]  ,$
                                                   COLOR=PLOTS_INFO.COLOURS[*,RES[I]]   ,$
                                                   XCOORD_CONV=NORM_COORD(XPLOT_RANGE)  ,$
                                                   YCOORD_CONV=NORM_COORD([MINY,MAXY])
  ENDFOR

;------------------------------------
; REDRAW THE LEGEND IF IT IS ON    

    IF PLOTS_INFO.VERBOSE EQ 1 THEN PRINT,'DIMITRI_DATABASE_PLOTS->PLOT: CHECKING LEGEND STATUS AND UPDATING'
    PLOTS_INFO.STATS_LEGEND->GETPROPERTY,HIDE=TEMP
    IF TEMP EQ 0 THEN BEGIN
      RES = WHERE(PLOTS_INFO.ACQ_CFIG_ON EQ 1)
      PLOTS_INFO.STATS_LEGEND->SETPROPERTY, ITEM_NAME  = PLOTS_INFO.LEGEND_NAMES[RES]         ,$ 
                                            ITEM_COLOR = PLOTS_INFO.COLOURS[*,RES]            ,$
                                            THICK      = MAKE_ARRAY(N_ELEMENTS(RES),VALUE=2)  ,$
                                            HIDE       = 0     
      
    ENDIF

;------------------------------------  
; REDRAW THE PLOT

  IF PLOTS_INFO.VERBOSE EQ 1 THEN PRINT,'DIMITRI_DATABASE_PLOTS->PLOT: REDRAWING THE PLOT'
  NO_ACTION:
  PLOTS_INFO.STATS_WINDOW->DRAW, PLOTS_INFO.STATS_VIEW 
  WIDGET_CONTROL, EVENT.TOP, SET_UVALUE = PLOTS_INFO,/NO_COPY

END

;**************************************************************************************
;**************************************************************************************

PRO DIMITRI_DATABASE_PLOTS_WD,VAL_SITE,LEADER_ID,VERBOSE=VERBOSE

COMMON DHMI_DATABASE
IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DATABASE_PLOTS: STARTING PLOT MODULE'

;------------------------------------ 
; FIND INDEX OF RECORDS WITHIN THIS SITE
  
  SITE_INDEX = WHERE(DHMI_DB_DATA.REGION EQ VAL_SITE,COUNT)
  IF COUNT EQ 0 THEN BEGIN
    PRINT, 'DIMITRI_DATABASE_PLOTS: INTERNAL ERROR, NO SITE DATA FOUND'
    RETURN
  ENDIF

;------------------------------------ 
; FIND NUMBER OF DIFFERENT SENSOR 
; CONFIGS AVAILABLE 

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DATABASE_PLOTS: RETRIEVING SENSOR CONFIGURATIONS'
  CGIF_STR    = DHMI_DB_DATA.SENSOR[SITE_INDEX]+'_'+DHMI_DB_DATA.PROCESSING_VERSION[SITE_INDEX]
  PT_CONFIGS  = CGIF_STR[UNIQ(CGIF_STR)]
  NPT_CONFIGS = N_ELEMENTS(PT_CONFIGS)

;------------------------------------ 
; DEFINE AN ARRAY TO HOLD ACQUISITION 
; STATS (NUM_YEARS,NUM_SENSORS)
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DATABASE_PLOTS: DEFINING ARRAYS TO HOLD DATA'  
  START_YEAR    = 2001
  TEMP          = SYSTIME()
  TEMP_LEN      = STRLEN(TEMP)
  END_YEAR      = FIX(STRMID(TEMP,TEMP_LEN-4,4))
  NYEARS        = (END_YEAR-START_YEAR)+1
  ACQ_PLOT_DATA = INTARR(NYEARS,NPT_CONFIGS)
  YEARS         = INDGEN(NYEARS)+START_YEAR

;------------------------------------
; DEFINE OBJ_ARRAY TO HOLD THE PLOTS AND 
; MODELS (2,NUM_SENSORS), AND AN ARRAY 
; INDICATING WHICHDATA IS TURNED ON

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DATABASE_PLOTS: DEFINING ARRAY TO HOLD PLOT OBJECTS'  
  ACQ_PLOT_MOD  = OBJARR(2,NPT_CONFIGS)
  ACQ_CFIG_ON   = INTARR(NPT_CONFIGS)
  ACQ_LGD_NAMES = STRARR(NPT_CONFIGS)

;------------------------------------
; DEFINE DIMITRI SENSORS AND SHORT NAMES 

  DSENS     = ['AATSR','ATSR2','MERIS','MODISA','PARASOL','VEGETATION']
  DSENS_SML = [  'ATS',  'AT2',  'MER',   'AQA',    'PAR',       'VGT']

;------------------------------------
; LOOP OVER EACH SENSOR CONFIG AND GET 
; THE DATA NUMBER OF INGESTED PRODUCTS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DATABASE_PLOTS: STARTING LOOP OVER EACH CONFIG AND RETRIEVING DATA'
  FOR I=0,NPT_CONFIGS-1 DO BEGIN

;------------------------------------
; RETRIEVE SENSOR NAME AND PROC 
; VERSION FROM PT_CONFIGS

    POS       = STRPOS(PT_CONFIGS[I],'_')
    TEMP_SENS = STRMID(PT_CONFIGS[I],0,POS)
    TEMP_CFIG = STRMID(PT_CONFIGS[I],POS+1,STRLEN(PT_CONFIGS[I])-POS)

    TMP = WHERE(DSENS EQ TEMP_SENS)
    IF TMP[0] EQ -1 THEN BEGIN
      PRINT, 'DIMITRI_DATABASE_PLOTS: INTERNAL ERROR, SENSOR NOT FOUND'
      RETURN
    ENDIF
 
;------------------------------------
; SORT OUT LEGEND NAME

    IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DATABASE_PLOTS: COMPUTING LEGEND NAME'   
    IF STRLEN(TEMP_CFIG) LT 5 THEN POS_MAX = STRLEN(TEMP_CFIG) ELSE POS_MAX = 5
    ACQ_LGD_NAMES[I] = STRING(DSENS_SML[TMP]+'_'+STRMID(TEMP_CFIG,0,POS_MAX))

;------------------------------------
; FIND THE NUMBER OF PRODUCTS ACQUIRED 
; FOR EACH YEAR 

    RES = WHERE(DHMI_DB_DATA.REGION EQ VAL_SITE   AND                    $
                DHMI_DB_DATA.SENSOR EQ TEMP_SENS  AND                    $
                DHMI_DB_DATA.PROCESSING_VERSION   EQ TEMP_CFIG, COUNT)

    IF COUNT EQ 0 THEN GOTO, NEXT_PTCFIG
    FOR J=0,NYEARS-1 DO BEGIN
      TEMP_YY = START_YEAR+J
      RES2 = WHERE(DHMI_DB_DATA.DECIMAL_YEAR[RES] GE TEMP_YY AND DHMI_DB_DATA.DECIMAL_YEAR[RES] LT TEMP_YY+1,COUNT_Y)
      ACQ_PLOT_DATA[J,I] = COUNT_Y
    ENDFOR

    NEXT_PTCFIG:
  ENDFOR

;------------------------------------ 
; CREATE THE PALETTE OBJECT

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DATABASE_PLOTS: CREATING THE PLOTS PALETTE AND AXES'  
  CFIG_DATA = GET_DIMITRI_CONFIGURATION() 
  COLORTABLE      = CFIG_DATA.(1)[6]
  STATS_PALETTE   = OBJ_NEW('IDLGRPALETTE')
  STATS_PALETTE->LOADCT, COLORTABLE

  BASE_XRANGE = [START_YEAR,END_YEAR]
  BASE_YRANGE = [0,1]
  
  IF STRCMP(STRUPCASE(!VERSION.OS_FAMILY),'WINDOWS') EQ 1 THEN   STATS_FONT  = OBJ_NEW('IDLGRFONT',SIZE=11.0) ELSE $
  STATS_FONT  = OBJ_NEW('IDLGRFONT',SIZE=9.0)
  
  XTITLE      = OBJ_NEW('IDLGRTEXT',"Date",RECOMPUTE_DIMENSION=2,FONT=STATS_FONT)
  YTITLE      = OBJ_NEW('IDLGRTEXT',"Number of Products",RECOMPUTE_DIMENSION=2,FONT=STATS_FONT)

;------------------------------------ 
; CREATE THE AXIS AND LEGEND OBJECTS

  STATS_XAXIS  = OBJ_NEW('IDLGRAXIS', 0, TICKLEN=0.025, TITLE=XTITLE,MAJOR=NYEARS,MINOR=0, $
                      RANGE=BASE_XRANGE, /EXACT,XCOORD_CONV=NORM_COORD(BASE_XRANGE))
  STATS_YAXIS  = OBJ_NEW('IDLGRAXIS', 1, TICKLEN=0.025, TITLE=YTITLE, $
                      RANGE=BASE_YRANGE, /EXACT,YCOORD_CONV=NORM_COORD(BASE_YRANGE))
  
  STATS_XAXIS->GETPROPERTY,TICKTEXT=TEMP_TEXTX  
  STATS_YAXIS->GETPROPERTY,TICKTEXT=TEMP_TEXTY
  TEMP_TEXTX->SETPROPERTY,FONT=STATS_FONT
  TEMP_TEXTY->SETPROPERTY,FONT=STATS_FONT
  STATS_LEGEND = OBJ_NEW('IDLGRLEGEND',/SHOW_OUTLINE,/HIDE,BORDER_GAP=0.2,FONT=STATS_FONT)

;------------------------------------ 
; CREATE THE MODEL AND VIEW OBJECTS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DATABASE_PLOTS: DEFINING THE PLOT MODEL, LEGEND MODEL AND VIEW'
  STATS_MODEL = OBJ_NEW('IDLGRMODEL')
  STATS_MODEL->ADD,STATS_XAXIS
  STATS_MODEL->ADD,STATS_YAXIS
  STATS_LEGENDMODEL = OBJ_NEW('IDLGRMODEL')
  STATS_LEGENDMODEL->ADD,STATS_LEGEND

  STATS_VIEW = OBJ_NEW('IDLGRVIEW',/DOUBLE)
  STATS_VIEW->ADD,STATS_MODEL
  STATS_VIEW->ADD,STATS_LEGENDMODEL
  ;STATS_VIEW->SETPROPERTY, VIEWPLANE_RECT = [-0.1, -0.1, 1.2, 1.2]
  STATS_VIEW->SETPROPERTY, VIEWPLANE_RECT = [-0.14, -0.12, 1.3, 1.2]

;------------------------------------ 
; CREATE THE PLOT AND MODEL OBJECTS 
; FOR EACH CONFIGURATION WITH DATA

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DATABASE_PLOTS: DEFINING THE PLOT FOR EACH SENSOR CONFIGURATION FOUND'
  FOR I=0,NPT_CONFIGS-1 DO BEGIN
    ACQ_PLOT_MOD[0,I] = OBJ_NEW('IDLGRPLOT',[0.0],[0.0]                               ,$
                              LINESTYLE=0, COLOR=[255,255,255],THICK=1,HISTOGRAM=1    ,$
                              XCOORD_CONV = NORM_COORD(BASE_XRANGE)                   ,$
                              YCOORD_CONV = NORM_COORD(BASE_YRANGE)                   $
                             )

    ACQ_PLOT_MOD[1,I]  = OBJ_NEW('IDLGRMODEL')
    ACQ_PLOT_MOD[1,I]->ADD,ACQ_PLOT_MOD[0,I]
    STATS_VIEW->ADD,  ACQ_PLOT_MOD[1,I]
  ENDFOR
  
;------------------------------------ 
; GET COLOURS FOR THE PLOT
  
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DATABASE_PLOTS: RETRIEVING COLOURS FOR PLOT'  
  TEMP_COLOURS = GET_DIMITRI_VISUALISATION_COLOURS(NPT_CONFIGS)

;------------------------------------ 
; GET THE DISPLAY RESOLUTION FOR WIDGET POSITIONING

  DIMS  = GET_SCREEN_SIZE()
  XSIZE = 700
  YSIZE = 450
  XLOC  = (DIMS[0]/2)-(XSIZE/2)
  YLOC  = (DIMS[1]/2)-(YSIZE/2)

;------------------------------------ 
; DEFINE THE BASE WIDGET

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DATABASE_PLOTS: DEFINING THE BASE WIDGET'
  PLOT_TITLE   = STRING('DIMITRI 2.0 ACQUISITION STATS: '+VAL_SITE)
  PLOT_WD_TLB  = WIDGET_BASE(TITLE=PLOT_TITLE,MBAR=MENUBASE,$
                              COLUMN=1, BASE_ALIGN_CENTER=1,XOFFSET=XLOC, YOFFSET=YLOC)
  PLOT_WD_DRAW = WIDGET_DRAW(PLOT_WD_TLB, XSIZE=XSIZE, YSIZE=YSIZE, GRAPHICS_LEVEL=2, RETAIN=2)
  
  ;------------------------------------ 
; CREATE THE FILE MENU AND BUTTONS

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DATABASE_PLOTS: CREATING THE FILE MENU'
  PLOT_WD_DLIM = WIDGET_BUTTON(MENUBASE,      VALUE='||', SENSITIVE=0)
  PLOT_WD_FILE = WIDGET_BUTTON(MENUBASE,      VALUE='File'      ,/MENU)
  PLOT_WD_DLIM = WIDGET_BUTTON(MENUBASE,      VALUE='||', SENSITIVE=0)
  PLOT_WD_EXPT = WIDGET_BUTTON(PLOT_WD_FILE,  VALUE='Save as...',/MENU)
  PLOT_WD_OUPT = WIDGET_BUTTON(PLOT_WD_EXPT,  VALUE='JPG'       ,UVALUE='JPG'   ,EVENT_PRO='PLOT_OBJECT_EXPORT')
  PLOT_WD_OUPT = WIDGET_BUTTON(PLOT_WD_EXPT,  VALUE='PNG'       ,UVALUE='PNG'   ,EVENT_PRO='PLOT_OBJECT_EXPORT')
  PLOT_WD_OUPT = WIDGET_BUTTON(PLOT_WD_EXPT,  VALUE='CSV'       ,UVALUE='CSV'   ,EVENT_PRO='PLOT_OBJECT_EXPORT')
  PLOT_WD_EXIT = WIDGET_BUTTON(PLOT_WD_FILE, /SEPARATOR         ,VALUE ='Exit'  ,EVENT_PRO='PLOT_OBJECT_EXIT')
  
  PLOT_WD_OPTI = WIDGET_BUTTON(MENUBASE,      VALUE='Options'      ,/MENU)  
  PLOT_WD_DLIM = WIDGET_BUTTON(MENUBASE,      VALUE='||', SENSITIVE=0)
  PLOT_WD_OUPT = WIDGET_BUTTON(PLOT_WD_OPTI,  VALUE='Legend'       ,UVALUE='LEGEND'  ,EVENT_PRO='PLOT_OBJECT_OPTION')
  PLOT_WD_OUPT = WIDGET_BUTTON(PLOT_WD_OPTI,  VALUE='Reset '       ,UVALUE='RESET'   ,EVENT_PRO='PLOT_OBJECT_OPTION')
  PLOT_WD_VIEW = WIDGET_BUTTON(MENUBASE,      VALUE='Sensor Configurations'     ,/MENU)
  
;------------------------------------
; ADD BUTTONS FOR EACH AVAILABLE CONFIG

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DATABASE_PLOTS: ADDING BUTTONS FOR EACH SENSOR CONFIG'
  FOR I=0,NPT_CONFIGS-1 DO BEGIN
    PLOT_WD_PLOT = WIDGET_BUTTON(PLOT_WD_VIEW,VALUE=PT_CONFIGS[I],UVALUE=PT_CONFIGS[I],$
                                  EVENT_PRO='PLOTS_OBJECT_PLOT')
  ENDFOR
  
;------------------------------------  
; CREATE THE BLANK PLOT AND MOVE THE LEGEND

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DATABASE_PLOTS: REALISE THE WIDGET AND RETRIEVE THE WINDOW' 
  WIDGET_CONTROL, PLOT_WD_TLB, /REALIZE
  WIDGET_CONTROL, PLOT_WD_DRAW, GET_VALUE=STATS_WINDOW
 
  STATS_WINDOW->DRAW, STATS_VIEW
  DIMS = STATS_LEGEND->COMPUTEDIMENSIONS(STATS_WINDOW) 
  STATS_LEGENDMODEL->TRANSLATE, .94, .75, 0 
  STATS_WINDOW->SETPROPERTY, PALETTE=STATS_PALETTE
  STATS_WINDOW->DRAW, STATS_VIEW
  IF KEYWORD_SET(VERBOSE) THEN VERBOSE = 1 ELSE VERBOSE = 0

;------------------------------------  
; SET THE PLOTS INFO DATA    

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DATABASE_PLOTS: DEFINING THE PLOT INFO'  
  PLOT_INFO = {                                             $
               ALL_DATA             : ACQ_PLOT_DATA         ,$
               ACQ_CFIG_ON          : ACQ_CFIG_ON           ,$
               LEGEND_NAMES         : ACQ_LGD_NAMES         ,$
               PT_CONFIGS           : PT_CONFIGS            ,$
               NPT_CONFIGS          : NPT_CONFIGS           ,$
               YEARS                : YEARS                 ,$
               STATS_PALETTE        : STATS_PALETTE         ,$
               XTITLE               : XTITLE                ,$
               YTITLE               : YTITLE                ,$
               BASE_XRANGE          : BASE_XRANGE           ,$
               STATS_FONT           : STATS_FONT            ,$
               STATS_XAXIS          : STATS_XAXIS           ,$
               STATS_YAXIS          : STATS_YAXIS           ,$
               STATS_LEGEND         : STATS_LEGEND          ,$
               STATS_MODEL          : STATS_MODEL           ,$
               STATS_LEGENDMODEL    : STATS_LEGENDMODEL     ,$
               STATS_VIEW           : STATS_VIEW            ,$
               STATS_WINDOW         : STATS_WINDOW          ,$
               ACQ_PLOT_MOD         : ACQ_PLOT_MOD          ,$
               VAL_SITE             : VAL_SITE              ,$
               YRANGE               : [0.0,1.0]             ,$
               VERBOSE              : VERBOSE               ,$
               COLOURS              : TEMP_COLOURS          $
               }

;------------------------------------
; SET THE WIDGET'S VALUES 
; AND REGISTER WITH THE XMANAGER

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_DATABASE_PLOTS: STARTING THE PLOT WIDGET'
  WIDGET_CONTROL, PLOT_WD_TLB,SET_UVALUE=PLOT_INFO,/NO_COPY,GROUP_LEADER=LEADER_ID
  XMANAGER,'PLOTS_OBJECT', PLOT_WD_TLB
    
END