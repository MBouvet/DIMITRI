function read_sade_txt,sadefile,sensor

case sensor of
'AATSR'       : NBANDS=7 
'MERIS'       : NBANDS=15 
'MODISA'      : NBANDS=10 
'PARASOL'     : NBANDS=9 
'VEGETATION'  : NBANDS=4 
endcase

BANDS = INDGEN(NBANDS)
BAND_STR = STRARR(NBANDS)
FOR I=0,NBANDS-1 DO BAND_STR[I] = BANDS[I] LE 9 ? '0'+STRTRIM(STRING(BANDS[I]),2) : STRTRIM(STRING(BANDS[I]),2)

NAMES_REF = MAKE_ARRAY(NBANDS,/STRING,VALUE='RHO')+'_'+BAND_STR
NAMES_STD = MAKE_ARRAY(NBANDS,/STRING,VALUE='STD')+'_'+BAND_STR
NAMES_VZA = MAKE_ARRAY(NBANDS,/STRING,VALUE='VZA')+'_'+BAND_STR
NAMES_VAA = MAKE_ARRAY(NBANDS,/STRING,VALUE='VAA')+'_'+BAND_STR

FIELDTYPES = [7,7,7,7,MAKE_ARRAY(4*NBANDS,/INTEGER,VALUE=4),3,4,4,4,4,7]

template=CREATE_STRUCT('VERSION', 1.0,$
                      'DATASTART',0,$
                      'DELIMITER', ' ',$  ;IS SPACE DELIMITED
                      'MISSINGVALUE',-999,$
                      'COMMENTSYMBOL','"',$
                      'FIELDCOUNT',N_ELEMENTS(FIELDTYPES),$
                      'FIELDTYPES', FIELDTYPES,$
                      'FIELDNAMES', ['PROCNAME','ACQDATE','PROCDATE','SITE',NAMES_REF,NAMES_STD,NAMES_VZA,NAMES_VAA,'NPIXS','LAT','LON','SZA','SAA','JPG'],$
                      'FIELDLOCATIONS',FINDGEN(N_ELEMENTS(FIELDTYPES)),$
                      'FIELDGROUPS',FINDGEN(N_ELEMENTS(FIELDTYPES)))

SADEDATA = READ_ASCII(SADEFILE,TEMPLATE=TEMPLATE)
RETURN,SADEDATA

end