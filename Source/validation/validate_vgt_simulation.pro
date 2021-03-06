pro validate_vgt_simulation

MER_FOLDER = 'Z:\DIMITRI_code\DIMITRI_2.0\Output\TuzGolu_20110513_REF_MERIS_2nd_Reprocessing'
ats_FOLDER = 'Z:\DIMITRI_code\DIMITRI_2.0\Output\TuzGolu_20110512_REF_AATSR_2nd_Reprocessing'
SL_REGION = 'TuzGolu'
VGT_PROC_VER = 'Calibration_1'
MER_PROC_VER = '2nd_Reprocessing'
ATS_PROC_VER = '2nd_Reprocessing'
CLOUD_PERCENTAGE = 10.0
ROI_PERCENTAGE = 20.0
BRDF_BIN_PERIOD = 5.0

res = VGT_SIMULATION(SL_REGION,MER_FOLDER,MER_PROC_VER,ATS_FOLDER,ATS_PROC_VER,VGT_PROC_VER,$
                          CLOUD_PERCENTAGE,ROI_PERCENTAGE,BRDF_BIN_PERIOD,VERBOSE=VERBOSE)


end