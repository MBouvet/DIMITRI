PRO REMOVE_NIGHT_PRODUCTS

; DEFINE DATABASE FILE
  
  ;DL          = GET_DIMITRI_LOCATION('DL')  
  ;DB_FILE     = GET_DIMITRI_LOCATION('DATABASE')
  ;DB_TEMPLATE = GET_DIMITRI_TEMPLATE(1,/TEMPLATE,VERBOSE=VERBOSE)
  DB_DATA     = READ_ASCII(DB_FILE,TEMPLATE=DB_TEMPLATE)

; DEFINE INPUT FOLDER
  
  ;IFOLDER     = GET_DIMITRI_LOCATION('INPUT')

; DEFINE WHICH SITE
  
  IREGIONS     = ['SIO','SPG']

; DEFINE WHICH PROCESSORS AND PROCVERS

  ISENSORS     = [           'AATSR',             'ATSR2',             'MERIS',           'MERIS',      'MODISA']
  IPROCV       = ['2nd_Reprocessing', 'Reprocessing_2008',  '2nd_Reprocessing','3rd_Reprocessing','Collection_5']
  NOVAL        = -1.0
  PCOUNTER     = 0
  CD,CURRENT=CDIR

  FOR IR=0,N_ELEMENTS(IREGIONS)-1 DO BEGIN ;LOOP OVER EACH SITE
    FOR IS = 0,N_ELEMENTS(ISENSORS)-1 DO BEGIN ;LOOP OVER EACH SENSOR/PROCV

      IDX = WHERE(  DB_DATA.REGION EQ IREGIONS[IR]            AND $
                    DB_DATA.SENSOR EQ ISENSORS[IS]            AND $
                    DB_DATA.PROCESSING_VERSION EQ IPROCV[IS]  AND $
                    FIX(ABS(DB_DATA.NUM_ROI_PX-NOVAL)) EQ 0, COUNT)  

      IF COUNT EQ 0 THEN CONTINUE
    
      FOR II = 0,count-1 DO BEGIN ;LOOP OVER EACH BAD PRODUCT
    
        TYEAR = STRTRIM(STRING(DB_DATA.YEAR[IDX[II]]),2)
        TFILE = DB_DATA.FILENAME[IDX[II]]
        SSTR = STRING(STRMID(TFILE,0,STRLEN(TFILE)-5)+'*')
        TFOLD = IFOLDER+'Site_'+IREGIONS[IR]+DL+ISENSORS[IS]+dl+'Proc_'+IPROCV[IS]+DL+TYEAR+DL
    
        CD,TFOLD
        FSRC = FILE_SEARCH(SSTR)

        IF FSRC[0] EQ '' THEN CONTINUE
        FOR JJ=0,N_ELEMENTS(FSRC)-1 DO FILE_DELETE,TFOLD+FSRC[JJ]
        PCOUNTER++

      ENDFOR ;LOOP OVER EACH BAD PRODUCT
    ENDFOR ;LOOP OVER EACH SENSOR/PROCV
  ENDFOR ;LOOP OVER EACH SITE

  CD,CDIR
  PRINT, '-----------------------------------------'
  PRINT, 'DELETED A TOTAL OF ',STRTRIM(STRING(PCOUNTER),2),' PRODUCTS'
  PRINT, '-----------------------------------------'

END

;**********************************************************************************************************************
;**********************************************************************************************************************

PRO REMOVE_DIMITRI_SAVS

  CD,CURRENT=CDIR
  IFOLDER = '/mnt/Projects/MEREMSII/DIMITRI/20120305/DIMITRI_2.0/Input/'
  DL = PATH_SEP()
  
  TREGIONS = ['Amazon','BOUSSOLE','DomeC','Libya4','SIO','SPG','TuzGolu','Uyuni']
  TSENS = ['AATSR'           ,             'ATSR2',             'MERIS',           'MERIS',      'MODISA',      'PARASOL',          'VEGETATION']
  TPROC = ['2nd_Reprocessing', 'Reprocessing_2008',  '2nd_Reprocessing','3rd_Reprocessing','Collection_5','Calibration_1','Calibration_1']

  FOR I=0,N_ELEMENTS(TREGIONS)-1 DO BEGIN
      for jj=0,n_elements(tsens)-1 do begin
   
   tmp = IFOLDER+DL+'Site_'+TREGIONS[I]+DL+TSENS[jj]+DL+'Proc_'+TPROC[jj]
if file_test(tmp,/directory) eq 0 then continue
CD, tmp

  RES = FILE_SEARCH('*'+TSENS[JJ]+'_*')
  IF RES[0] NE '' THEN FOR J=0,N_ELEMENTS(RES)-1 DO FILE_DELETE,RES[J]
  endfor  
  ENDFOR 
  
  CD,CDIR

END

;**********************************************************************************************************************
;**********************************************************************************************************************

PRO BATCH_INGEST_ALL

  TREGIONS  = ['Amazon','BOUSSOLE','DomeC','Libya','SIO','SPG','TuzGolu','Uyuni']
  TSENS     = ['AATSR'           ,             'ATSR2',             'MERIS',           'MERIS',      'MODISA']
  TPROC     = ['2nd_Reprocessing', 'Reprocessing_2008',  '2nd_Reprocessing','3rd_Reprocessing','Collection_5']
  YEARS     = ['2002','2003','2004','2005','2006','2007','2008','2009','2010','2011']

  FOR IR = 0,N_ELEMENTS(TREGIONS)-1 DO BEGIN
    FOR IS = 0,N_ELEMENTS(TSENS)-1 DO BEGIN
      FOR IY = 0,N_ELEMENTS(TYEARS)-1 DO BEGIN
stop
       ; RES = DIMITRI_INTERFACE_INGEST(TREGIONS[IR],TSENS[IS],TPROC[IS], COLOUR_TABLE=39,PLOT_XSIZE=700,PLOT_YSIZE=400,YEAR=YEARS[IY],/verbose)

      ENDFOR
    ENDFOR 
  ENDFOR

END

;**********************************************************************************************************************
;**********************************************************************************************************************

PRO RESET_DIMITRI_DATABASE

;STEPS TO CLEAN TYHE DIMITRI DATABASE AND OTHER FILES

; idl> CD,''
; idl> @compile_dimitri

;1) REMOVE EMPTY PRODUCTS FROM SIO AND SPG

  PRINT, 'RDD STATUS ',SYSTIME(),': STARTING REMOVAL OF NIGHT PRODUCTS'
  REMOVE_NIGHT_PRODUCTS
  PRINT, 'RDD STATUS ',SYSTIME(),': COMPLETED REMOVAL OF NIGHT PRODUCTS'

;2) REMOVE SAV FILES

  PRINT, 'RDD STATUS ',SYSTIME(),': STARTING REMOVAL OF DIMITRI SAVS'
  REMOVE_DIMITRI_SAVS
  PRINT, 'RDD STATUS ',SYSTIME(),': COMPLETED REMOVAL OF DIMITRI SAVS'

;3) BACKUP AND REMOVE DATABASE FILE

  PRINT, 'RDD STATUS ',SYSTIME(),': STARTING BACKUP OF DIMITRI DATABASE'
  DB_FILE  = GET_DIMITRI_LOCATION('DATABASE')
  FILE_COPY,DB_FILE,DB_FILE+'_RESET_BACKUP'
  FILE_DELETE,DB_FILE
  PRINT, 'RDD STATUS ',SYSTIME(),': COMPLETED BACKUP OF DIMITRI DATABASE'

;4) REPROESS ALL SITES/SENSOR COMBINATIONS

  PRINT, 'RDD STATUS ',SYSTIME(),': STARTING REPROCESSING OF ALL DIMITRI DATA'
  BATCH_INGEST_ALL
  PRINT, 'RDD STATUS ',SYSTIME(),': COMPLETED REPROCESSING OF ALL DIMITRI DATA'

END
