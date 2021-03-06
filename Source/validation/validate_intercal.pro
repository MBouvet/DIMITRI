PRO VALIDATE_intercal

case strupcase(!version.os_family) of
'WINDOWS':OUTPUT_FOLDER = 'Z:\DIMITRI_code\DIMITRI_2.0\Output\doublet_validation\'
'UNIX':OUTPUT_FOLDER = '/mnt/Demitri/DIMITRI_code/DIMITRI_2.0/Output/doublet_validation/'
endcase
 
;ED_REGION = 'SIO'
;SENSOR1 = 'MERIS'
;PROC_VER1 = '2nd_Reprocessing'
;SENSOR2 = 'MODISA'
;PROC_VER2 = 'Collection_5'
;CHI_THRESHOLD = 5.0
;DAY_OFFSET = 5.0
;CLOUD_PERCENTAGE = 30.0
;ROI_PERCENTAGE = 10.0
;
;RES = DIMITRI_INTERFACE_DOUBLET(OUTPUT_FOLDER,ED_REGION,SENSOR1,PROC_VER1,SENSOR2,PROC_VER2,CHI_THRESHOLD,$
;                                   DAY_OFFSET,CLOUD_PERCENTAGE,ROI_PERCENTAGE,/VERBOSE)

II_REGION = 'SIO'
REF_SENSORS = 'MERIS'
REF_PROC_VERS = '2nd_Reprocessing'
CAL_SENSORS = 'MERIS'
CAL_PROC_VERS = '3rd_Reprocessing'
DIMITRI_BAND_IDS = indgen(25)

RES = DIMITRI_INTERFACE_INTERCALIBRATION(OUTPUT_FOLDER,II_REGION,REF_SENSORS,REF_PROC_VERS, $
                                                  CAL_SENSORS,CAL_PROC_VERS,DIMITRI_BAND_IDS,/verbose)
print, res
END