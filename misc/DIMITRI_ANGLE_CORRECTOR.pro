;**************************************************************************************
;**************************************************************************************
;*
;* NAME:
;*      DIMITRI_ANGLE_CORRECTOR       
;* 
;* PURPOSE:
;*      CHECKS THAT THE PROVIDED ANGULAR INFORMAITON IS IN THE CORRECT RANGE.
;* 
;* CALLING SEQUENCE:
;*      RES = DIMITRI_ANGLE_CORRECTOR(VZA,VAA,SZA,SAA)      
;* 
;* INPUTS:
;*      VZA - THE VIEWING ZENITH ANGLE IN DEGREES 
;*      VAA - THE VIEWING AZIMUTH ANGLE IN DEGREES
;*      SZA - THE SOLAR ZENITH ANGLE IN DEGREES
;*      SAA - THE SOLAR AZIMUTH ANGLE IN DEGREES     
;*
;* KEYWORDS:
;*      VERBOSE - PROCESSING STATUS OUTPUTS
;*
;* OUTPUTS:
;*      ANGLES - THE CORRECTED ANGULAR INFORMATION 
;*
;* COMMON BLOCKS:
;*      NONE
;*
;* MODIFICATION HISTORY:
;*      01 JUL 2011 - C KENT    - DIMITRI-2 V1.0
;*
;* VALIDATION HISTORY:
;*      02 DEC 2010 - C KENT    - 
;*      12 APR 2011 - C KENT    -  
;*
;**************************************************************************************
;**************************************************************************************

FUNCTION DIMITRI_ANGLE_CORRECTOR,VZA,VAA,SZA,SAA,VERBOSE=VERBOSE

  ANGLES = {VZA:VZA,VAA:VAA,SZA:SZA,SAA:SAA}
  MINVAL = [0.,0.,0.,0.]
  MAXVAL = [90.,360.,90.,360.]
  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_ANGLE_CORRECTOR: STARTING ANGLE CORRECTION'

  FOR IANG = 0,3 DO BEGIN

    IF IANG EQ 0 OR 2 THEN BEGIN

      RES = WHERE(ANGLES.(IANG) LT MINVAL[IANG],COUNT)
      IF COUNT GT 0 THEN ANGLES.(IANG)[RES] = MINVAL[IANG]

      RES = WHERE(ANGLES.(IANG) GT MAXVAL[IANG],COUNT)
      IF COUNT GT 0 THEN ANGLES.(IANG)[RES] = MAXVAL[IANG]
      
   ;   ANGLES.(IANG) = ANGLES[IANG] LT MINVAL[IANG] ? MINVAL[IANG] : ANGLES[IANG]
   ;   ANGLES.(IANG) = ANGLES[IANG] GT MAXVAL[IANG] ? MAXVAL[IANG] : ANGLES[IANG]

    ENDIF ELSE BEGIN

      RES = WHERE(ANGLES.(IANG) LT MINVAL[IANG],COUNT)
      IF COUNT GT 0 THEN ANGLES.(IANG)[RES] = 360.0+ANGLES.(IANG)[RES]

      RES = WHERE(ANGLES.(IANG) GT MAXVAL[IANG],COUNT)
      IF COUNT GT 0 THEN ANGLES.(IANG)[RES] = ANGLES.(IANG)[RES]-360.0

  ;    ANGLES[IANG] = ANGLES[IANG] LT MINVAL[IANG] ? 360.0+ANGLES[IANG] : ANGLES[IANG]
  ;    ANGLES[IANG] = ANGLES[IANG] GT MAXVAL[IANG] ? ANGLES[IANG]-360.0 : ANGLES[IANG]

    ENDELSE

  ENDFOR

  IF KEYWORD_SET(VERBOSE) THEN PRINT,'DIMITRI_ANGLE_CORRECTOR: COMPLETED ANGLE CORRECTION'
  RETURN, ANGLES

END
