PRO VALIDATE_CLOUD_SCREENING
;RESTORES DIMITRI TOA TIME SERIES, PLOTS THE FIRST BAND AND OUTPUTS A SAV AND CSV FILE FOR CHECKING

;------------------------
; DEFINE SETUP

  DEVICE,DECOMPOSED=0
  LOADCT,39
  CP_LIMIT  = 0.
  RP_LIMIT  = 1.
  ROICOVER  = 1
  PX_THRESH = 1  
  SENSORS   = ['PARASOL'];['MERIS','MERIS','MODISA','AATSR','ATSR2'];,'VEGETATION']
  PROCVER   = ['Calibration_1'];['2nd_Reprocessing','3rd_Reprocessing','Collection_5','2nd_Reprocessing','Reprocessing_2008'];,'Calibration_1']
  SITES     = ['Amazon','BOUSSOLE','Libya4','DomeC','SIO','SPG','TuzGolu','Uyuni']
  OFOLDER   = '/mnt/Projects/MEREMSII/DIMITRI/20120305/DIMITRI_2.0/Source/validation/'

  DID = 0
  BID = 12+5
  TOL = 0.00005

;------------------------
; READ DATABASE

  DB_FILE   = GET_DIMITRI_LOCATION('DATABASE')
  IFOLDER   = GET_DIMITRI_LOCATION('INPUT')
  DL        = PATH_SEP()
  DB_DATA   = READ_ASCII(DB_FILE,TEMPLATE=GET_DIMITRI_TEMPLATE(1,/TEMPLATE))

;------------------------ 
; LOOP OVER EACH SENSOR + PROCV AND EACH SITE

  FOR II=0L,N_ELEMENTS(SENSORS)-1 DO BEGIN
  FOR KK=0L,N_ELEMENTS(SITES)-1 DO BEGIN

;------------------------ 
; RESTORE TOA_REF

    S1_IFILE = STRING(IFOLDER+DL+'Site_'+SITES[KK]+DL+SENSORS[II]+DL+'Proc_'+PROCVER[II]+DL+SENSORS[II]+'_TOA_REF.dat')
    IF NOT FILE_TEST(S1_IFILE) THEN CONTINUE
    RESTORE,S1_IFILE

;------------------------ 
; FIND ALL DATA WHICH IS CLASSED 
; AS CLOUD FREE AND ROI COVERED

    RES = WHERE(STRCMP(DB_DATA.REGION,SITES[KK])               EQ 1 AND $
                STRCMP(DB_DATA.SENSOR,SENSORS[II])             EQ 1 AND $
                STRCMP(DB_DATA.PROCESSING_VERSION,PROCVER[II]) EQ 1 AND $
                DB_DATA.ROI_COVER  GE ROICOVER                 AND $
                DB_DATA.NUM_ROI_PX GE PX_THRESH)

;----------------------------------------
; GET A LIST OF DATES IN WHICH DATA IS ALSO 
; WITHIN THE CLOUD PERCENTAGE 

    GD_DATE = 0.0
    FOR I_CS=0L,N_ELEMENTS(RES)-1 DO BEGIN
      IF DB_DATA.MANUAL_CS[RES[I_CS]]  GE 1.0 THEN CONTINUE
      IF (DB_DATA.MANUAL_CS[RES[I_CS]] EQ 0.0) OR $
         (DB_DATA.AUTO_CS[RES[I_CS]]   LE CP_LIMIT AND DB_DATA.AUTO_CS[RES[I_CS]] GT -1.0) THEN GD_DATE = [GD_DATE,DB_DATA.DECIMAL_YEAR[RES[I_CS]]]
    ENDFOR;END OF LOOP ON GOOD DATES
    GD_DATE = GD_DATE[1:N_ELEMENTS(GD_DATE)-1]
    GD_IDX = MAKE_ARRAY(N_ELEMENTS(SENSOR_L1B_REF[0,*]),/INTEGER,VALUE=0)
    FOR GD=0L,N_ELEMENTS(GD_DATE)-1 DO BEGIN
      RES = WHERE(ABS(SENSOR_L1B_REF[0,*]-GD_DATE[GD]) LE TOL AND SENSOR_L1B_REF[BID,*] GT 0.0 AND SENSOR_L1B_REF[BID,*] lT 5.0)                  
      GD_IDX[RES]=1
    ENDFOR ;END OF LOOP ON GOOD DATES TO FIND INDEX IN ALL_DATA ARRAY
    RES = WHERE(GD_IDX EQ 1)
    DATA = SENSOR_L1B_REF[*,RES]

    data = data[*,where(data[BID,*] GT 0.0)]  
  

;------------------------
; PLOT THE DATA AND SAVE AS IDL SAV

    WINDOW,1,XSIZE=700,YSIZE=400
    PLOT,DATA[DID,*],DATA[BID,*],/NODATA,COLOR=0,BACKGROUND=255,$
    XTITLE='DATE',YTITLE='TOA_RHO',TITLE=SITES[KK]+'_'+SENSORS[II]+'_'+PROCVER[II]
    OPLOT,DATA[DID,*],DATA[BID,*],COLOR=60,THICK=2
    IMG = TVRD(/TRUE)
    WRITE_PNG,OFOLDER+'plots'+DL+SENSORS[II]+'_'+PROCVER[II]+'_'+SITES[KK]+'.png',IMG
    WDELETE,1
    SAVE,DATA,FILENAME=OFOLDER+'SAVS'+DL+SENSORS[II]+'_'+PROCVER[II]+'_'+SITES[KK]+'.sav'

;------------------------
; PRINT AS CSV

    OPENW,OUTF,OFOLDER+'csv'+DL+SENSORS[II]+'_'+PROCVER[II]+'_'+SITES[KK]+'.csv',/GET_LUN
    PRINTF,OUTF,'DATE;RHO1'
    FOR LL=0L,N_ELEMENTS(DATA[BID,*])-1 DO PRINTF,OUTF,DATA[DID,LL],DATA[BID,LL],FORMAT='( 1(D15.7,1H;),1(D15.7))'
    FREE_LUN,OUTF

  ENDFOR
  ENDFOR
  
END