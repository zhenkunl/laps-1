SUBROUTINE BUFR_PROFLR(NUMPROFLR,NUMLEVELS,STATIONID,I4OBSTIME, &
                        LATITUDES,LONGITUDE,ELEVATION,OBSVNTYPE, &
                        MAXPROFLR,HEIGHTOBS,UUWINDOBS,VVWINDOBS, &
                        WNDRMSERR,PRSSFCOBS,TMPSFCOBS,REHSFCOBS, &
                        UWDSFCOBS,VWDSFCOBS)

!==============================================================================
!doc  THIS ROUTINE CONVERTS LAPS PROFILER DATA INTO PREPBUFR FORMAT.
!doc
!doc  HISTORY:
!doc	CREATION:	YUANFU XIE/SHIOW-MING DENG	JUN 2007
!==============================================================================

  USE LAPS_PARAMS

  IMPLICIT NONE

  CHARACTER, INTENT(IN) :: STATIONID(*)*5		! STATION ID
  CHARACTER, INTENT(IN) :: OBSVNTYPE(*)*8		! OBS TYPE
  INTEGER,   INTENT(IN) :: NUMPROFLR,NUMLEVELS(*)	! NUMBER OF PROFILERS/LEVELS
  INTEGER,   INTENT(IN) :: MAXPROFLR			! MAXIMUM NUMBER PROFILRS
                                                	! INSTEAD OF MAXNUM_PROFLRS
                                                	! AVOID CONFUSION ON MEMORY.
  INTEGER,   INTENT(IN) :: I4OBSTIME(*)			! I4 OBS TIMES

  ! OBSERVATIONS:
  REAL,      INTENT(IN) :: LATITUDES(*),LONGITUDE(*),ELEVATION(*)
  REAL,      INTENT(IN) :: HEIGHTOBS(MAXPROFLR,*), &	! UPAIR
                           UUWINDOBS(MAXPROFLR,*), &	! UPAIR
                           VVWINDOBS(MAXPROFLR,*), &	! UPAIR
                           WNDRMSERR(MAXPROFLR,*)	! WIND RMS ERROR
  REAL,      INTENT(IN) :: PRSSFCOBS(*),TMPSFCOBS(*), &	! SURFACE
                           REHSFCOBS(*), &		! SURFACE
                           UWDSFCOBS(*),VWDSFCOBS(*)	! SURFACE

  ! LOCAL VARIABLES:
  CHARACTER :: STTNID*8,SUBSET*8
  INTEGER   :: I,J,INDATE,ZEROCH,STATUS,OBTIME(6)
  REAL      :: MAKE_SSH				! LAPS ROUTINE FROM RH TO SH
  REAL*8    :: HEADER(HEADER_NUMITEM),OBSDAT(OBSDAT_NUMITEM,225)
  REAL*8    :: OBSERR(OBSERR_NUMITEM,225),OBSQMS(OBSQMS_NUMITEM,225)
  EQUIVALENCE(STTNID,HEADER(1))

  PRINT*,'Number of Pofilers: ',NUMPROFLR,NUMLEVELS(1:NUMPROFLR)

  ! OBS DATE: YEAR/MONTH/DAY
  ZEROCH = ICHAR('0')
  INDATE = YYYYMM_DDHHMIN(1)*1000000+YYYYMM_DDHHMIN(2)*10000+ &
           YYYYMM_DDHHMIN(3)*100+YYYYMM_DDHHMIN(4)

  ! WRITE DATA:
  DO I=1,NUMPROFLR

    ! STATION ID:
    STTNID = STATIONID(I)

    ! DATA TYPE:
    IF (OBSVNTYPE(I) .EQ. 'PROFILER') THEN
      SUBSET = 'PROFLR'
      HEADER(2) = 223		! PROFILER CODE
      HEADER(3) = 71		! INPUT REPORT TYPE
    ELSE IF (OBSVNTYPE(I) .EQ. 'VAD') THEN
      SUBSET = 'VADWND'
      HEADER(2) = 224		! PROFILER CODE
      HEADER(3) = 72		! INPUT REPORT TYPE
    ELSE
      PRINT*,'BUFR_PROFLR: ERROR: Unknown profiler data type!'
      STOP
    ENDIF

    ! TIME:
    CALL CV_I4TIM_INT_LP(I4OBSTIME(I),OBTIME(1),OBTIME(2),OBTIME(3), &
                           OBTIME(4),OBTIME(5),OBTIME(6),STATUS)
    IF ((OBTIME(2) .NE. YYYYMM_DDHHMIN(2)) .OR. &
        (OBTIME(3) .NE. YYYYMM_DDHHMIN(3)) ) THEN
      WRITE(*,*) 'BUFR_PROFLR: Error in observation time!'
      STOP
    ENDIF
    ! LAPS cycle time:
    HEADER(4) = YYYYMM_DDHHMIN(4)
    ! DHR: obs time different from the cycle time:
    HEADER(5) = OBTIME(4)+FLOAT(OBTIME(5))/60.0+FLOAT(OBTIME(6))/3600.0-HEADER(4)

    ! LAT/LON/ELEVATION:
    HEADER(6) = LATITUDES(I)
    HEADER(7) = LONGITUDE(I)
    HEADER(8) = ELEVATION(I)

    HEADER(9) = 99			! INSTRUMENT TYPE: COMMON CODE TABLE C-2
    HEADER(10) = I			! REPORT SEQUENCE NUMBER
    HEADER(11) = 0			! MPI PROCESS NUMBER

    ! UPAIR OBSERVATIONS:
    ! MISSING DATA CONVERSION:
    OBSDAT = MISSNG_PREBUFR
    OBSERR = MISSNG_PREBUFR
    OBSQMS = MISSNG_PREBUFR
    DO J=1,NUMLEVELS(I)
      IF (HEIGHTOBS(I,J) .NE. RVALUE_MISSING) OBSDAT(1,J) = HEIGHTOBS(I,J)
      IF (UUWINDOBS(I,J) .NE. RVALUE_MISSING) OBSDAT(4,J) = UUWINDOBS(I,J)
      IF (VVWINDOBS(I,J) .NE. RVALUE_MISSING) OBSDAT(5,J) = VVWINDOBS(I,J)
      IF (WNDRMSERR(I,J) .NE. RVALUE_MISSING) OBSERR(4,J) = WNDRMSERR(I,J)
    ENDDO
    OBSERR(1,1:NUMLEVELS(I)) = 0.0	! ZERO ERROR FOR HEIGHT
    OBSQMS(1,1:NUMLEVELS(I)) = 0	! QUALITY MARK - BUFR CODE TABLE: 
    OBSQMS(4,1:NUMLEVELS(I)) = 0	! 0 always assimilated

    ! WRITE TO BUFR FILE:
    CALL OPENMB(OUTPUT_CHANNEL,SUBSET,INDATE)
    CALL UFBINT(OUTPUT_CHANNEL,HEADER,HEADER_NUMITEM,1,STATUS,HEADER_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSDAT,OBSDAT_NUMITEM, &
                 NUMLEVELS(I),STATUS,OBSDAT_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSERR,OBSERR_NUMITEM, &
                 NUMLEVELS(I),STATUS,OBSERR_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSQMS,OBSQMS_NUMITEM, &
                 NUMLEVELS(I),STATUS,OBSQMS_PREBUFR)
    CALL WRITSB(OUTPUT_CHANNEL)

    ! WRITE SURFACE DATA: FUTURE DEVELOPMENT DEBUG NEEDED
    ! SFCDAT(1) = PRSSFCOBS(I)
    ! SFCDAT(2) = MISSNG_PREBUFR
    ! SFCDAT(3) = TMPSFCOBS(I)
    ! SFCDAT(4) = MISSNG_PREBUFR
    ! USE -132 AS TEMP_REFERENCE:
    ! TEMPERATURE >= TEMP_REFERENCE: RH IS WATER RH;
    ! TEMPERATURE <  TEMP_REFERENCE: RH IS ICE RH;
    ! ASSUME THE SURFACE OBS OF RH IS WATER RH HERE:
    ! SFCDAT(5) = MAKE_SSH(PRSSFCOBS(I),TMPSFCOBS(I),REHSFCOBS(I)/100.0,&
    !              TEMPTR_REFEREN)*0.001 ! KG/KG
    ! CALL OPENMB(OUTPUT_CHANNEL,'ADPSFC',INDATE)
    ! HEADER IS NEEDED TO REFLECT THE OBSERVATION CODE!!!
    ! CALL UFBINT(OUTPUT_CHANNEL,HEADER,HEADER_NUMITEM,1,1,HEADER_PREBUFR)
    ! CALL UFBINT(OUTPUT_CHANNEL,SFCDAT,SURFAC_NUMITEM,1,1,SURFAC_PREBUFR)
    ! CALL UFBINT(OUTPUT_CHANNEL,SFCQMS,SFCQMS_NUMITEM,1,1,SURFAC_PREBUFR)
    ! CALL WRITSB(OUTPUT_CHANNEL)

  ENDDO

END SUBROUTINE BUFR_PROFLR

SUBROUTINE BUFR_SONDES(NUMSONDES,NUMLEVELS,STATIONID,I4OBSTIME, &
                         LATITUDES,LONGITUDE,ELEVATION,OBSVNTYPE,HEIGHTOBS, &
                         PRESSROBS,TEMPTROBS,DEWPNTOBS,UUWINDOBS,VVWINDOBS)

!==============================================================================
!doc  THIS ROUTINE CONVERTS LAPS SONDE DATA INTO PREPBUFR FORMAT.
!doc
!doc  HISTORY:
!doc	CREATION:	YUANFU XIE/SHIOW-MING DENG	JUN 2007
!==============================================================================

  USE LAPS_PARAMS

  IMPLICIT NONE

  CHARACTER, INTENT(IN) :: STATIONID(*)*5		! STATION ID
  CHARACTER, INTENT(IN) :: OBSVNTYPE(*)*8		! OBS TYPE
  INTEGER,   INTENT(IN) :: NUMSONDES, &                 ! NUMBER OF PROFILERS
                           NUMLEVELS(*)			! NUMBER OF LEVELS
  INTEGER,   INTENT(IN) :: I4OBSTIME(*)			! I4 OBS TIMES

  ! OBSERVATIONS:
  REAL,      INTENT(IN) :: LATITUDES(*),LONGITUDE(*),ELEVATION(*)
  REAL,      INTENT(IN) :: HEIGHTOBS(MAXNUM_PROFLRS,*), &	! UPAIR
                           PRESSROBS(MAXNUM_PROFLRS,*), &	! UPAIR
                           TEMPTROBS(MAXNUM_PROFLRS,*), &	! UPAIR
                           DEWPNTOBS(MAXNUM_PROFLRS,*), &	! UPAIR
                           UUWINDOBS(MAXNUM_PROFLRS,*), &	! UPAIR
                           VVWINDOBS(MAXNUM_PROFLRS,*)		! UPAIR

  ! LOCAL VARIABLES:
  CHARACTER :: STTNID*8,SUBSET*8
  INTEGER   :: I,J,INDATE,ZEROCH,STATUS,OBTIME(6)
  REAL      :: SSH2		! LAPS FUNCTION FOR SPECIFIC HUMIDITY
  REAL*8    :: HEADER(HEADER_NUMITEM),OBSDAT(OBSDAT_NUMITEM,225)
  REAL*8    :: OBSERR(OBSERR_NUMITEM,225),OBSQMS(OBSQMS_NUMITEM,225)
  EQUIVALENCE(STTNID,HEADER(1))

  PRINT*,'Number of sondes: ',NUMSONDES,NUMLEVELS(1:NUMSONDES)

  ! OBS DATE: YEAR/MONTH/DAY
  ZEROCH = ICHAR('0')
  INDATE = YYYYMM_DDHHMIN(1)*1000000+YYYYMM_DDHHMIN(2)*10000+ &
           YYYYMM_DDHHMIN(3)*100+YYYYMM_DDHHMIN(4)

  ! WRITE DATA:
  DO I=1,NUMSONDES

    ! NO VALID LEVEL DATA:
    IF (NUMLEVELS(I) .LE. 0) CYCLE

    ! STATION ID:
    STTNID = STATIONID(I)

    ! DATA TYPE:
    SUBSET = 'ADPUPA'
    SELECT CASE (OBSVNTYPE(I))
    CASE ('RADIOMTR','RAOB')
      HEADER(2) = 120		! PREPBUFR REPORT TYPE: TABLE 2
      HEADER(3) = 11		! INPUT REPORT TYPE: TABLE 6
      OBSERR(1,1:NUMLEVELS(I)) = 0.0	! ZERO ERROR FOR HEIGHT
      OBSERR(3,1:NUMLEVELS(I)) = 2.0	! ASSUME 2 DEG ERROR
      OBSERR(4,1:NUMLEVELS(I)) = 0.5	! ASSUME 0.5 M/S ERROR
      OBSERR(6,1:NUMLEVELS(I)) = 2.0	! ASSUME 2 MM ERROR
    CASE ('POESSND')
      HEADER(2) = 257		! PREPBUFR REPORT TYPE: TABLE 2
      HEADER(3) = 63		! INPUT REPORT TYPE: TABLE 6: SATELLITE-DERIVED WIND
      OBSERR(1,1:NUMLEVELS(I)) = 0.0	! ZERO ERROR FOR HEIGHT
      OBSERR(3,1:NUMLEVELS(I)) = 2.0	! ASSUME 2 DEG ERROR
      OBSERR(4,1:NUMLEVELS(I)) = 1.0	! 2 M/S ERROR ASSUMED FOR SATWIND
      OBSERR(6,1:NUMLEVELS(I)) = 2.0	! ASSUME 2 MM ERROR
    CASE DEFAULT
      PRINT*,'BUFR_SONDES: UNKNOWN OBSERVATION DATA TYPE! ',OBSVNTYPE(I),I
      STOP
    END SELECT

    ! TIME:
    CALL CV_I4TIM_INT_LP(I4OBSTIME(I),OBTIME(1),OBTIME(2),OBTIME(3), &
                           OBTIME(4),OBTIME(5),OBTIME(6),STATUS)
    IF ((OBTIME(2) .NE. YYYYMM_DDHHMIN(2)) .OR. &
        (OBTIME(3) .NE. YYYYMM_DDHHMIN(3)) ) THEN
      WRITE(*,*) 'BUFR_SONDES: Error in observation time!'
      STOP
    ENDIF
    HEADER(4) = YYYYMM_DDHHMIN(4)
    HEADER(5) = OBTIME(4)+FLOAT(OBTIME(5))/60.0+FLOAT(OBTIME(6))/3600.0-HEADER(4)

    ! LAT/LON/ELEVATION:
    HEADER(6) = LATITUDES(I)
    HEADER(7) = LONGITUDE(I)
    HEADER(8) = ELEVATION(I)

    HEADER(9) = 90			! INSTRUMENT TYPE: COMMON CODE TABLE C-2
    HEADER(10) = I			! REPORT SEQUENCE NUMBER
    HEADER(11) = 0			! MPI PROCESS NUMBER

    ! UPAIR OBSERVATIONS:
    ! MISSING DATA CONVERSION:
    OBSDAT = MISSNG_PREBUFR
    OBSQMS = MISSNG_PREBUFR
    DO J=1,NUMLEVELS(I)
      IF (HEIGHTOBS(I,J) .NE. RVALUE_MISSING) THEN
	OBSDAT(1,J) = HEIGHTOBS(I,J)
        OBSERR(1,J) = 0.1
      ENDIF
      IF (PRESSROBS(I,J) .NE. RVALUE_MISSING) THEN
	OBSDAT(2,J) = PRESSROBS(I,J)
	OBSERR(2,J) = 10.0
      ENDIF
      IF (TEMPTROBS(I,J) .NE. RVALUE_MISSING) THEN
	OBSDAT(3,J) = TEMPTROBS(I,J)
	OBSERR(3,J) = 0.1
      ENDIF
      IF (UUWINDOBS(I,J) .NE. RVALUE_MISSING) OBSDAT(4,J) = UUWINDOBS(I,J)
      IF (VVWINDOBS(I,J) .NE. RVALUE_MISSING) OBSDAT(5,J) = VVWINDOBS(I,J)
      IF ((OBSDAT(4,J) .NE. RVALUE_MISSING) .AND. &
	  (OBSDAT(5,J) .NE. RVALUE_MISSING)) OBSERR(4,J) = 0.1

      ! SPECIFIC HUMIDITY:
      IF ((PRESSROBS(I,J) .NE. RVALUE_MISSING) .AND. &
          (DEWPNTOBS(I,J) .NE. RVALUE_MISSING) .AND. &
          (TEMPTROBS(I,J) .NE. RVALUE_MISSING)) THEN
        OBSDAT(6,J) = SSH2(PRESSROBS(I,J),TEMPTROBS(I,J), &
                          DEWPNTOBS(I,J),TEMPTR_REFEREN)*1000.0 !MG/KG
        OBSERR(6,J) = 0.01
      ENDIF
    ENDDO
    OBSQMS(1:6,1:NUMLEVELS(I)) = 1	! QUALITY MARK - BUFR CODE TABLE: 
					! GOOD ASSUMED.

    ! WRITE TO BUFR FILE:
    CALL OPENMB(OUTPUT_CHANNEL,SUBSET,INDATE)
    CALL UFBINT(OUTPUT_CHANNEL,HEADER,HEADER_NUMITEM,1,STATUS,HEADER_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSDAT,OBSDAT_NUMITEM, &
                 NUMLEVELS(I),STATUS,OBSDAT_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSERR,OBSERR_NUMITEM, &
                 NUMLEVELS(I),STATUS,OBSERR_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSQMS,OBSQMS_NUMITEM, &
                 NUMLEVELS(I),STATUS,OBSQMS_PREBUFR)
    CALL WRITSB(OUTPUT_CHANNEL)

  ENDDO

END SUBROUTINE BUFR_SONDES

SUBROUTINE BUFR_SFCOBS(NUMBEROBS,HHMINTIME,LATITUDES,LONGITUDE,STATIONID, &
                         OBSVNTYPE,PROVIDERS,ELEVATION,MSLPRSOBS,MSLPRSERR, &
                         STNPRSOBS,STNPRSERR,TEMPTROBS,TEMPTRERR,WIND2DOBS, &
                         WIND2DERR,RELHUMOBS,RELHUMERR,SFCPRSOBS,PRECP1OBS, &
                         PRECP1ERR)


!==============================================================================
!doc  THIS ROUTINE CONVERTS LAPS SONDE DATA INTO PREPBUFR FORMAT.
!doc
!doc  HISTORY:
!doc	CREATION:	YUANFU XIE/SHIOW-MING DENG	JUN 2007
!==============================================================================

  USE LAPS_PARAMS

  IMPLICIT NONE

  CHARACTER, INTENT(IN) :: STATIONID(*)*20		! STATION ID
  CHARACTER, INTENT(IN) :: PROVIDERS(*)*11		! PROVIDER'S NAME
  CHARACTER, INTENT(IN) :: OBSVNTYPE(*)*6		! OBS TYPE
  INTEGER,   INTENT(IN) :: NUMBEROBS                    ! NUMBER OF PROFILERS
  INTEGER,   INTENT(IN) :: HHMINTIME(*)			! I4 OBS TIMES

  ! OBSERVATIONS:
  REAL,      INTENT(IN) :: LATITUDES(*),LONGITUDE(*),ELEVATION(*)
  REAL,      INTENT(IN) :: MSLPRSOBS(*), &		! MEAN SEA LEVEL PRESSURE
                           MSLPRSERR(*), &		! ERROR
                           STNPRSOBS(*), &		! STATION PRESSURE
                           STNPRSERR(*), &		! STATION PRESSURE ERROR
                           TEMPTROBS(*), &		! TEMPERATURE
                           TEMPTRERR(*), &		! TEMPERATURE ERROR
                           WIND2DOBS(2,*), &  		! 2D WIND OBS
                           WIND2DERR(2,*), &  		! 2D WINDOBS ERRKR
                           RELHUMOBS(*), &  		! RELATIVE HUMIDITY
                           RELHUMERR(*), &  		! HUMIDITY ERROR
                           SFCPRSOBS(*), &     		! SURFACE PRESSURE
                           PRECP1OBS(*), &   		! PRECIPITATION
                           PRECP1ERR(*)			! PRECIPITATION ERROR

  ! LOCAL VARIABLES:
  CHARACTER :: STTNID*8,SUBSET*8
  INTEGER   :: I,INDATE,ZEROCH,STATUS,OBTIME(6)
  INTEGER   :: I4TIME
  REAL      :: MAKE_SSH		! LAPS FUNCTION FOR SPECIFIC HUMIDITY FROM RH
  REAL*8    :: HEADER(HEADER_NUMITEM),OBSDAT(OBSDAT_NUMITEM)
  REAL*8    :: OBSERR(OBSERR_NUMITEM),OBSQMS(OBSQMS_NUMITEM)
  EQUIVALENCE(STTNID,HEADER(1))

  PRINT*,'Number of surface obs: ',NUMBEROBS

  ! OBS DATE: YEAR/MONTH/DAY
  ZEROCH = ICHAR('0')
  INDATE = YYYYMM_DDHHMIN(1)*1000000+YYYYMM_DDHHMIN(2)*10000+ &
           YYYYMM_DDHHMIN(3)*100+YYYYMM_DDHHMIN(4)

  ! WRITE DATA:
  DO I=1,NUMBEROBS

    ! STATION ID:
    STTNID = STATIONID(I)

    ! DATA TYPE:
    SUBSET = 'ADPSFC'
    SELECT CASE (OBSVNTYPE(I))
    CASE ('MARTIM','SYNOP')	! MARINE AND SYNOP
      HEADER(2) = 281		! BUFR REPORT TYPE:  TABLE 2
      HEADER(3) = 511		! INPUT REPORT TYPE: TABLE 6
    CASE ('METAR','SPECI','LDAD') ! SPECI: SPECIAL METAR DATA
      HEADER(2) = 181		! BUFR REPORT TYPE:  TABLE 2
      HEADER(3) = 512		! INPUT REPORT TYPE: TABLE 6
    CASE DEFAULT
      PRINT*,'BUFR_SFCOBS: UNKOWN OBSERVATION DATA TYPE! ',OBSVNTYPE(I),'HHH',I
      CLOSE(OUTPUT_CHANNEL)
      STOP
    END SELECT

    ! TIME:
    CALL GET_SFC_OBTIME(HHMINTIME(I),SYSTEM_IN4TIME,I4TIME,STATUS)
    CALL CV_I4TIM_INT_LP(I4TIME,OBTIME(1),OBTIME(2),OBTIME(3), &
                           OBTIME(4),OBTIME(5),OBTIME(6),STATUS)
    IF ((OBTIME(2) .NE. YYYYMM_DDHHMIN(2)) .OR. &
        (OBTIME(3) .NE. YYYYMM_DDHHMIN(3)) ) THEN
      WRITE(*,*) 'BUFR_SFCOBS: Error in observation time!'
      STOP
    ENDIF
    HEADER(4) = YYYYMM_DDHHMIN(4)
    HEADER(5) = OBTIME(4)+FLOAT(OBTIME(5))/60.0+FLOAT(OBTIME(6))/3600.0-HEADER(4)

    ! LAT/LON/ELEVATION:
    HEADER(6) = LATITUDES(I)
    HEADER(7) = LONGITUDE(I)
    HEADER(8) = ELEVATION(I)

    HEADER(9) = 90			! INSTRUMENT TYPE: COMMON CODE TABLE C-2
    HEADER(10) = I			! REPORT SEQUENCE NUMBER
    HEADER(11) = 0			! MPI PROCESS NUMBER

    ! UPAIR OBSERVATIONS:
    ! MISSING DATA CONVERSION:
    OBSDAT = MISSNG_PREBUFR
    OBSERR = MISSNG_PREBUFR
    OBSQMS = MISSNG_PREBUFR

    ! SURFACE OBS: ZOB IS THE ELEVATION HEIGHT:
    OBSDAT(1) = ELEVATION(I)
    OBSERR(1) = 0.0		! PERFECT HEIGHT

    IF ((TEMPTROBS(I) .NE. RVALUE_MISSING) .AND. &
        (TEMPTROBS(I) .NE. SFCOBS_INVALID)) THEN
	OBSDAT(3) = (TEMPTROBS(I)-32.0)*5.0/9.0
        IF ((TEMPTRERR(I) .NE. RVALUE_MISSING) .AND. &
            (TEMPTRERR(I) .NE. SFCOBS_INVALID)) &
          OBSERR(3) = TEMPTRERR(I)
    ENDIF
    IF ((WIND2DOBS(1,I) .NE. RVALUE_MISSING) .AND. &
        (WIND2DOBS(1,I) .NE. SFCOBS_INVALID)) OBSDAT(4) = WIND2DOBS(1,I)
    IF ((WIND2DOBS(2,I) .NE. RVALUE_MISSING) .AND. &
        (WIND2DOBS(2,I) .NE. SFCOBS_INVALID)) OBSDAT(5) = WIND2DOBS(2,I)
    IF ((WIND2DERR(1,I) .NE. RVALUE_MISSING) .AND. &
        (WIND2DERR(1,I) .NE. SFCOBS_INVALID) .AND. &
        (WIND2DERR(2,I) .NE. RVALUE_MISSING) .AND. &
        (WIND2DERR(2,I) .NE. SFCOBS_INVALID)) &
	OBSERR(4) = SQRT(WIND2DERR(1,I)**2+WIND2DERR(2,I)**2)
    ! SPECIFIC HUMIDITY:
    IF ((SFCPRSOBS(I) .NE. RVALUE_MISSING) .AND. &
        (SFCPRSOBS(I) .NE. SFCOBS_INVALID) .AND. &
        (TEMPTROBS(I) .NE. RVALUE_MISSING) .AND. &
        (TEMPTROBS(I) .NE. SFCOBS_INVALID) .AND. &
        (RELHUMOBS(I) .NE. RVALUE_MISSING) .AND. &
        (RELHUMOBS(I) .NE. SFCOBS_INVALID)) THEN
      OBSDAT(6) = MAKE_SSH(SFCPRSOBS(I),OBSDAT(3),RELHUMOBS(I)/100.0,&
                           TEMPTR_REFEREN)*1000.0 ! MG/KG
      IF ((STNPRSERR(I) .NE. RVALUE_MISSING) .AND. &
        (STNPRSERR(I) .NE. SFCOBS_INVALID) .AND. &
        (TEMPTRERR(I) .NE. RVALUE_MISSING) .AND. &
        (TEMPTRERR(I) .NE. SFCOBS_INVALID) .AND. &
        (RELHUMERR(I) .NE. RVALUE_MISSING) .AND. &
        (RELHUMERR(I) .NE. SFCOBS_INVALID)) &
      OBSERR(5) = MAKE_SSH(STNPRSERR(I),OBSERR(3),RELHUMERR(I)/100.0,&
                           TEMPTR_REFEREN)*1000.0 ! MG/KG
    ENDIF
    IF ((MSLPRSOBS(I) .NE. RVALUE_MISSING) .AND. &
        (MSLPRSOBS(I) .NE. SFCOBS_INVALID)) OBSDAT(7) = MSLPRSOBS(I)
    IF ((STNPRSOBS(I) .NE. RVALUE_MISSING) .AND. &
        (STNPRSOBS(I) .NE. SFCOBS_INVALID)) OBSDAT(2) = STNPRSOBS(I)
    IF ((SFCPRSOBS(I) .NE. RVALUE_MISSING) .AND. &
        (SFCPRSOBS(I) .NE. SFCOBS_INVALID)) OBSDAT(8) = SFCPRSOBS(I)
    IF ((STNPRSERR(I) .NE. RVALUE_MISSING) .AND. &
        (STNPRSERR(I) .NE. SFCOBS_INVALID)) OBSERR(2) = STNPRSERR(I)
    IF ((PRECP1OBS(I) .NE. RVALUE_MISSING) .AND. &
        (PRECP1OBS(I) .NE. SFCOBS_INVALID)) OBSDAT(9) = PRECP1OBS(I)*INCHES_CONV2MM
    IF ((PRECP1ERR(I) .NE. RVALUE_MISSING) .AND. &
        (PRECP1ERR(I) .NE. SFCOBS_INVALID)) OBSERR(6) = PRECP1ERR(I)
    OBSQMS(1:5) = 0	! QUALITY MARK - BUFR CODE TABLE: 
			! 0 always assimilated.

    ! WRITE TO BUFR FILE:
    CALL OPENMB(OUTPUT_CHANNEL,SUBSET,INDATE)
    CALL UFBINT(OUTPUT_CHANNEL,HEADER,HEADER_NUMITEM,1,STATUS,HEADER_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSDAT,OBSDAT_NUMITEM,1,STATUS,OBSDAT_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSERR,OBSERR_NUMITEM,1,STATUS,OBSERR_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSQMS,OBSQMS_NUMITEM,1,STATUS,OBSQMS_PREBUFR)
    CALL WRITSB(OUTPUT_CHANNEL)

  ENDDO

END SUBROUTINE BUFR_SFCOBS

SUBROUTINE BUFR_CDWACA(NUMBEROBS,OBSVARRAY,OBI4ARRAY)

!==============================================================================
!doc  THIS ROUTINE CONVERTS LAPS CLOUD DRIFT WIND AND ACARS DATA INTO PREPBUFR
!doc  FORMAT.
!doc
!doc  HISTORY:
!doc	CREATION:	YUANFU XIE/SHIOW-MING DENG	JUN 2007
!==============================================================================

  USE LAPS_PARAMS

  IMPLICIT NONE

  INTEGER, INTENT(IN) :: NUMBEROBS,OBI4ARRAY(3,*)
  REAL*8,  INTENT(IN) :: OBSVARRAY(7,*)

  ! LOCAL VARIABLES:
  CHARACTER :: STTNID*8,SUBSET*8
  INTEGER   :: I,INDATE,ZEROCH,STATUS,OBTIME(6)
  REAL*8    :: HEADER(HEADER_NUMITEM),OBSDAT(OBSDAT_NUMITEM)
  REAL*8    :: OBSERR(OBSERR_NUMITEM),OBSQMS(OBSQMS_NUMITEM)
  EQUIVALENCE(STTNID,HEADER(1))

  PRINT*,'Number of cloud drift wind and ACAR obs: ',NUMBEROBS

  ! OBS DATE: YEAR/MONTH/DAY
  ZEROCH = ICHAR('0')
  INDATE = YYYYMM_DDHHMIN(1)*1000000+YYYYMM_DDHHMIN(2)*10000+ &
           YYYYMM_DDHHMIN(3)*100+YYYYMM_DDHHMIN(4)

  ! WRITE DATA:
  DO I=1,NUMBEROBS

    HEADER(2:3) = OBI4ARRAY(1:2,I)	! CODE AND REPORT TYPE
    SELECT CASE (OBI4ARRAY(2,I))
    CASE (241)
      ! STATION ID:
      STTNID = 'CDW'
      ! DATA TYPE:
      SUBSET = 'SATWND'
    CASE (130,230)
      ! STATION ID:
      STTNID = 'ACAR'
      ! DATA TYPE:
      SUBSET = 'AIRCAR'
    CASE DEFAULT
      PRINT*,'BUFR_CDWACA: UNKNOWN OBSERVATION DATA TYPE! ',OBI4ARRAY(2,I)
      STOP
    END SELECT

    ! TIME:
    CALL CV_I4TIM_INT_LP(OBI4ARRAY(3,I),OBTIME(1),OBTIME(2),OBTIME(3), &
                          OBTIME(4),OBTIME(5),OBTIME(6),STATUS)
    IF ((OBTIME(2) .NE. YYYYMM_DDHHMIN(2)) .OR. &
        (OBTIME(3) .NE. YYYYMM_DDHHMIN(3)) ) THEN
      WRITE(*,*) 'BUFR_SONDES: Error in observation time!'
      STOP
    ENDIF
    HEADER(4) = YYYYMM_DDHHMIN(4)
    HEADER(5) = OBTIME(4)+FLOAT(OBTIME(5))/60.0+FLOAT(OBTIME(6))/3600.0-HEADER(4)

    ! LAT/LON/ELEVATION:
    HEADER(6) = OBSVARRAY(1,I)
    HEADER(7) = OBSVARRAY(2,I)
    HEADER(8) = OBSVARRAY(3,I)

    HEADER(9) = 90			! INSTRUMENT TYPE: COMMON CODE TABLE C-2
					! CANNOT FIND CODE TABLE FOR ACARS INSTRUMENT
    HEADER(10) = I			! REPORT SEQUENCE NUMBER
    HEADER(11) = 0			! MPI PROCESS NUMBER

    ! UPAIR OBSERVATIONS:
    ! MISSING DATA CONVERSION:
    OBSDAT = MISSNG_PREBUFR
    OBSERR = MISSNG_PREBUFR
    OBSQMS = MISSNG_PREBUFR
    IF (OBSVARRAY(3,I) .NE. RVALUE_MISSING) OBSDAT(1) = OBSVARRAY(3,I)	! HEIGHT
    IF (OBSVARRAY(4,I) .NE. RVALUE_MISSING) OBSDAT(2) = OBSVARRAY(4,I)	! PRESSURE
    IF (OBSVARRAY(7,I) .NE. RVALUE_MISSING) OBSDAT(3) = &
					OBSVARRAY(7,I)-ABSOLU_TMPZERO	! TEMPERATURE
    IF (OBSVARRAY(5,I) .NE. RVALUE_MISSING) OBSDAT(4) = OBSVARRAY(5,I)	! U
    IF (OBSVARRAY(6,I) .NE. RVALUE_MISSING) OBSDAT(5) = OBSVARRAY(6,I)	! V

    OBSERR(1) = 0.0	! ZERO ERROR FOR HEIGHT
    OBSERR(3) = 0.0	! ASSUME 0 DEG ERROR
    OBSERR(4) = 0.0	! ASSUME 0 M/S ERROR
    OBSQMS(1:6) = 1	! QUALITY MARK - BUFR CODE TABLE: 
					! GOOD ASSUMED.

    ! WRITE TO BUFR FILE:
    CALL OPENMB(OUTPUT_CHANNEL,SUBSET,INDATE)
    CALL UFBINT(OUTPUT_CHANNEL,HEADER,HEADER_NUMITEM,1,STATUS,HEADER_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSDAT,OBSDAT_NUMITEM,1,STATUS,OBSDAT_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSERR,OBSERR_NUMITEM,1,STATUS,OBSERR_PREBUFR)
    CALL UFBINT(OUTPUT_CHANNEL,OBSQMS,OBSQMS_NUMITEM,1,STATUS,OBSQMS_PREBUFR)
    CALL WRITSB(OUTPUT_CHANNEL)
  ENDDO

END SUBROUTINE BUFR_CDWACA
