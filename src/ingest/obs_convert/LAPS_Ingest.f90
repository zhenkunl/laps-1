SUBROUTINE LAPS_INGEST

!==============================================================================
!doc  THIS ROUTINE INGESTS OBSERVATION DATA BY LAPS LIBRARIES.
!doc
!doc  HISTORY:
!doc	CREATION:	YUANFU XIE	MAY 2007
!==============================================================================

  IMPLICIT NONE

  ! RADAR:
  ! CALL READ_RADAR		! PREFER TO USE LAPS GRIDDED RADAR DATA FOR NOW YUANFU

  ! PROFILER:
  CALL CONV_PROFLR

  ! SONDE:
  CALL CONV_SONDES

  ! SURFACE OBS:
  CALL CONV_SFCOBS

  ! CDW AND ACARS:
  CALL CONV_CDWACA

END SUBROUTINE LAPS_INGEST

SUBROUTINE CONV_PROFLR

!==============================================================================
!doc  THIS ROUTINE READS AND CONVERTS PROFILER OBSERVATION DATA INTO DATA FORMAT
!doc  REQUESTED.
!doc
!doc  HISTORY:
!doc	CREATION:	YUANFU XIE	JUN 2007
!==============================================================================

  USE LAPS_PARAMS

  IMPLICIT NONE

  CHARACTER :: FSPECS*225, EXTNSN*31,C5NAME(MAXNUM_PROFLRS)*5, &
               OBTYPE(MAXNUM_PROFLRS)*8
  INTEGER   :: IOFILE,STATUS,NPRFLR,NLEVEL(MAXNUM_PROFLRS)
  INTEGER   :: I4TIME,OBTIME(MAXNUM_PROFLRS)
  REAL	    :: PRFLAT(MAXNUM_PROFLRS),PRFLON(MAXNUM_PROFLRS),&
               PRFELV(MAXNUM_PROFLRS)
  REAL      :: HGHTOB(MAXNUM_PROFLRS,MAXLVL_PROFLRS)	! HEIGHT OBS
  REAL      :: UWNDOB(MAXNUM_PROFLRS,MAXLVL_PROFLRS)	! U WIND OBS
  REAL      :: VWNDOB(MAXNUM_PROFLRS,MAXLVL_PROFLRS)	! V WIND OBS
  REAL      :: RMSOBS(MAXNUM_PROFLRS,MAXLVL_PROFLRS)	! RMS
  REAL      :: TSFCOB(MAXNUM_PROFLRS)			! SFC T OBS
  REAL      :: PSFCOB(MAXNUM_PROFLRS)			! SFC P OBS
  REAL      :: RHSFCO(MAXNUM_PROFLRS)			! SFC RH OBS
  REAL      :: USFCOB(MAXNUM_PROFLRS)			! SFC U OBS
  REAL      :: VSFCOB(MAXNUM_PROFLRS)			! SFC V OBS

  IOFILE = 12
  NLEVEL = 0

  ! OPEN NEAREST PROFILER FILE TO THE LAPS ANALYSIS TIME:
  EXTNSN = 'pro'
  CALL GET_FILESPEC(EXTNSN,2,FSPECS,STATUS)

  CALL GET_FILE_TIME(FSPECS,SYSTEM_IN4TIME,I4TIME)

  ! CHECK IF DATA FILE IS CLOSE TO SYSTEM TIME:
  IF (ABS(SYSTEM_IN4TIME-I4TIME) .GT. LENGTH_ANATIME) THEN
    PRINT*,'CONV_PROFLR: No recent profiler data files'
    RETURN
  ENDIF

  ! READ PROFILER DATA:
  CALL READ_PRO_DATA(IOFILE,I4TIME,EXTNSN,MAXNUM_PROFLRS,MAXLVL_PROFLRS, & ! I
                     NPRFLR,NLEVEL,PRFLAT,PRFLON,PRFELV,C5NAME,OBTIME,   & ! O
                     OBTYPE,HGHTOB,UWNDOB,VWNDOB,RMSOBS,TSFCOB,PSFCOB,   & ! O
                     RHSFCO,USFCOB,VSFCOB,STATUS)                          ! O
  CALL LAPS_DIVIDER
  WRITE(6,*) 'CONV_PROFLR: Number of profilers data read: ',NPRFLR
  CALL LAPS_DIVIDER

  ! CONVERT TO THE REQUESTED FORMAT:
  IF (NPRFLR .GT. 0) THEN
    WRITE(6,*) 'CONV_PROFLR: Levels at each profiler: ',NLEVEL(1:NPRFLR)
    IF      (FORMAT_REQUEST .EQ. 'BUFR') THEN
      CALL BUFR_PROFLR(NPRFLR,NLEVEL,C5NAME,OBTIME,PRFLAT,PRFLON,PRFELV, &
                       OBTYPE,MAXNUM_PROFLRS,HGHTOB,UWNDOB,VWNDOB,RMSOBS, &
                       PSFCOB,TSFCOB,RHSFCO,USFCOB,VSFCOB)
    ELSE IF (FORMAT_REQUEST .NE. 'WRF') THEN
      CALL WRFD_PROFLR(NPRFLR,NLEVEL,C5NAME,OBTIME,PRFLAT,PRFLON,PRFELV, &
                       OBTYPE,MAXNUM_PROFLRS,HGHTOB,UWNDOB,VWNDOB,PSFCOB, &
                       TSFCOB,RHSFCO,USFCOB,VSFCOB)
    ENDIF
  ENDIF

END SUBROUTINE CONV_PROFLR


SUBROUTINE CONV_SONDES

!==============================================================================
!  THIS ROUTINE READS AND CONVERTS SONDING OBSERVATION DATA INTO DATA FORMAT
!  REQUESTED.
!
!  HISTORY:
!	CREATION:	YUANFU XIE	JUN 2007
!==============================================================================

  USE LAPS_PARAMS

  IMPLICIT NONE

  CHARACTER :: FSPECS*225, EXTNSN*3,C5NAME(MAXNUM_PROFLRS)*5, &
               OBTYPE(MAXNUM_PROFLRS)*8
  INTEGER   :: IOFILE,STATUS,NPRFLR,NLEVEL(MAXNUM_PROFLRS), &
               WINDOW,MODEOB
  INTEGER   :: I4TIME,PRFTIM(MAXNUM_PROFLRS,MAXLVL_PROFLRS)
  REAL	    :: PRFLAT(MAXNUM_PROFLRS,MAXLVL_PROFLRS), &
               PRFLON(MAXNUM_PROFLRS,MAXLVL_PROFLRS), &
               PRFELV(MAXNUM_PROFLRS)
  REAL      :: HGHTOB(MAXNUM_PROFLRS,MAXLVL_PROFLRS)	! HEIGHT OBS
  REAL      :: PRSOBS(MAXNUM_PROFLRS,MAXLVL_PROFLRS)	! PRESSURE OBS
  REAL      :: UWNDOB(MAXNUM_PROFLRS,MAXLVL_PROFLRS)	! U WIND OBS
  REAL      :: VWNDOB(MAXNUM_PROFLRS,MAXLVL_PROFLRS)	! V WIND OBS
  REAL      :: TEMPOB(MAXNUM_PROFLRS,MAXLVL_PROFLRS)	! T OBS
  REAL      :: DEWOBS(MAXNUM_PROFLRS,MAXLVL_PROFLRS)	! DEW POINT OBS

  IOFILE = 12
  NLEVEL = 0
  WINDOW = 0			! I4TIME WINDOW MIMIC READ_PROFILES.F
  MODEOB = 3			! KEY LEVELS OFF OF WIND DATA

  ! OPEN NEAREST PROFILER FILE TO THE LAPS ANALYSIS TIME:
  EXTNSN = 'snd'
  CALL GET_FILESPEC(EXTNSN,2,FSPECS,STATUS)

  CALL GET_FILE_TIME(FSPECS,SYSTEM_IN4TIME,I4TIME)
  IF (ABS(SYSTEM_IN4TIME-I4TIME) .GT. LENGTH_ANATIME) THEN
    WRITE(6,*) 'CONV_SONDES: Warning: nearest sonde file is outside window'
  ELSE

    ! READ SONDE DATA:
    CALL READ_SND_DATA2(IOFILE,I4TIME,EXTNSN,MAXNUM_PROFLRS,MAXLVL_PROFLRS, & ! I
                       DOMAIN_LATITDE,DOMAIN_LONGITD,NUMBER_GRIDPTS(1),     & ! I
                       NUMBER_GRIDPTS(2),NUMBER_GRIDPTS(3),HEIGHT_GRID3DM,  & ! I
                       .TRUE.,MODEOB,                                       & ! I
                       NPRFLR,PRFELV,NLEVEL,C5NAME,OBTYPE,HGHTOB,           & ! O
                       PRSOBS,UWNDOB,VWNDOB,TEMPOB,DEWOBS,PRFLAT,PRFLON,    & ! O
                       PRFTIM,STATUS)                                         ! O
    CALL LAPS_DIVIDER
    WRITE(6,*) 'CONV_SONDES: Number of sonde data read: ',NPRFLR
    CALL LAPS_DIVIDER

    ! CONVERT TO THE REQUESTED FORMAT:
    IF (NPRFLR .GT. 0) THEN
      WRITE(6,*) 'CONV_SONDES: Levels at each sonde: ',NLEVEL(1:NPRFLR)
      IF      (FORMAT_REQUEST .EQ. 'BUFR') THEN
        CALL BUFR_SONDES(NPRFLR,NLEVEL,C5NAME,PRFTIM,PRFLAT,PRFLON,PRFELV, &
                         OBTYPE,HGHTOB,PRSOBS,TEMPOB,DEWOBS,UWNDOB,VWNDOB)
      ELSE IF (FORMAT_REQUEST .NE. 'WRF') THEN
        CALL WRFD_SONDES(NPRFLR,NLEVEL,C5NAME,PRFTIM,PRFLAT,PRFLON,PRFELV, &
                         OBTYPE,HGHTOB,PRSOBS,TEMPOB,DEWOBS,UWNDOB,VWNDOB)
      ENDIF
    ENDIF

  ENDIF

END SUBROUTINE CONV_SONDES

SUBROUTINE CONV_SFCOBS

!==============================================================================
!  THIS ROUTINE READS AND CONVERTS SURFACE OBSERVATIONS INTO REQUESTED DATA
!  FORMAT.
!
!  HISTORY:
!	CREATION:	YUANFU XIE	JUN 2007
!==============================================================================

  USE LAPS_PARAMS

  IMPLICIT NONE

  CHARACTER*24 :: FILETM		! OBS FILE TIME
  INTEGER :: MAXSTN,STATUS,I		! MAXIMUM STATIONS
  INTEGER :: NOBGRD,NOBBOX		! NUMBER OF OBS OVER GRID AND BOX

  CHARACTER*20,ALLOCATABLE,DIMENSION(:) :: STNAME	! STATION NAMES
  CHARACTER*11,ALLOCATABLE,DIMENSION(:) :: PVNAME	! PROVIDER NAMES
  CHARACTER*25,ALLOCATABLE,DIMENSION(:) :: PRSTWX	! PRESENT WEATHER
  CHARACTER*6, ALLOCATABLE,DIMENSION(:) :: RPTYPE	! REPORT TYPE
  CHARACTER*6, ALLOCATABLE,DIMENSION(:) :: STNTYP	! STATION TYPE
  INTEGER,     ALLOCATABLE,DIMENSION(:) :: OBTIME,WMOIDS! OBS TIME/WMO ID
  INTEGER,     ALLOCATABLE,DIMENSION(:) :: CLDLYR,PRSCHC! CLOUD LAYER/PRS CHG
  REAL,        ALLOCATABLE,DIMENSION(:) :: &
    OBSLAT,OBSLON,OBSELV,OBSTMP,ERRTMP,OBSDEW,ERRDEW,OBSRHS,ERRRHS, &
    OBSDIR,ERRDIR,OBSSPD,ERRSPD,GUSDIR,GUSSPD,OBSALT,ERRALT,STNPRS, &
    MSLPRS,PRSCH3,ERRPRS,OBSVIS,ERRVIS,OBSSOL,ERRSOL,SFCTMP,ERRSFT, &
    SFCMOI,ERRSFM,PRECP1,PRECP3,PRECP6,PREC24,ERRPCP,SNOWCV,ERRSNW, &
    MAXTMP,MINTMP,igrid,jgrid

  CHARACTER*4, ALLOCATABLE,DIMENSION(:,:) :: CLDAMT     ! CLOUD AMOUNT

  REAL,        ALLOCATABLE,DIMENSION(:,:) :: CLDHGT	! CLOUD HEIGHTS
  REAL,        ALLOCATABLE,DIMENSION(:,:) :: OBSWND, &  ! OBS WIND
                                             ERRWND	! OBS WIND ERROR

  ! GET MAXIMUM NUMBER OF SURFACE STATIONS:
  CALL GET_MAXSTNS(MAXSTN,STATUS)
  IF (STATUS .NE. 1) THEN
    WRITE(6,*) 'CONV_SONDES: ERROR IN READING MAXIMUM SFC STATIONS'
    STOP
  ENDIF

  ! ALLOCATABLE MEMORY FOR SURFACE VARIABLES:
  ALLOCATE(OBTIME(MAXSTN),WMOIDS(MAXSTN),STNAME(MAXSTN), &
           PVNAME(MAXSTN),PRSTWX(MAXSTN),RPTYPE(MAXSTN), &
           STNTYP(MAXSTN),OBSLAT(MAXSTN),OBSLON(MAXSTN), &
           OBSELV(MAXSTN),OBSTMP(MAXSTN),OBSDEW(MAXSTN), &
           OBSRHS(MAXSTN),OBSDIR(MAXSTN),OBSSPD(MAXSTN), &
           GUSDIR(MAXSTN),GUSSPD(MAXSTN),OBSALT(MAXSTN), &
           STNPRS(MAXSTN),MSLPRS(MAXSTN),PRSCHC(MAXSTN), &
           PRSCH3(MAXSTN),OBSVIS(MAXSTN),OBSSOL(MAXSTN), &
           SFCTMP(MAXSTN),SFCMOI(MAXSTN),PRECP1(MAXSTN), &
           PRECP3(MAXSTN),PRECP6(MAXSTN),PREC24(MAXSTN), &
           SNOWCV(MAXSTN),CLDLYR(MAXSTN),MAXTMP(MAXSTN), &
           MINTMP(MAXSTN),ERRTMP(MAXSTN),ERRDEW(MAXSTN), &
           ERRRHS(MAXSTN),ERRDIR(MAXSTN),ERRSPD(MAXSTN), &
           ERRALT(MAXSTN),ERRPRS(MAXSTN),ERRVIS(MAXSTN), &
           ERRSOL(MAXSTN),ERRSFT(MAXSTN),ERRSFM(MAXSTN), &
           ERRPCP(MAXSTN),ERRSNW(MAXSTN), igrid(maxstn),jgrid(maxstn), &
           CLDAMT(MAXSTN,5),CLDHGT(MAXSTN,5), &
           OBSWND(2,MAXSTN),ERRWND(2,MAXSTN), STAT=STATUS)
  IF (STATUS .NE. 0) THEN
    WRITE(6,*) 'CONV_SFCOBS: ERROR IN ALLOCATING MEMORY FOR SURFACE DATA'
    STOP
  ENDIF

  ! READ SFC OBS:
  CALL READ_SURFACE_DATA(SYSTEM_IN4TIME,FILETM,NOBGRD,NOBBOX,OBTIME,WMOIDS,&
                         STNAME,PVNAME,PRSTWX,RPTYPE,STNTYP,OBSLAT,OBSLON, &
                         OBSELV,OBSTMP,OBSDEW,OBSRHS,OBSDIR,OBSSPD,GUSDIR, &
                         GUSSPD,OBSALT,STNPRS,MSLPRS,PRSCHC,PRSCH3,OBSVIS, &
                         OBSSOL,SFCTMP,SFCMOI,PRECP1,PRECP3,PRECP6,PREC24, &
                         SNOWCV,CLDLYR,MAXTMP,MINTMP,                             &
                         ERRTMP,ERRDEW,ERRRHS,ERRDIR,ERRSPD,ERRALT,ERRPRS, &
                         ERRVIS,ERRSOL,ERRSFT,ERRSFM,ERRPCP,ERRSNW,CLDAMT, &
                         CLDHGT,MAXSTN,STATUS)

  IF (STATUS .NE. 1) THEN
    WRITE(6,*) 'CONV_SFCOBS: ERROR IN READING SURFACE OBS'
    STOP
  ENDIF

  ! CONVERT WIND DIRECTION AND SPEED INTO U AND V:
  DO I=1,NOBBOX
    call latlon_to_rlapsgrid(obslat(I),obslon(I),DOMAIN_LATITDE,DOMAIN_LONGITD, &
				NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2),igrid(i),jgrid(i),status)
    IF ((OBSDIR(I) .NE. RVALUE_MISSING) .AND. &
        (OBSDIR(I) .NE. SFCOBS_INVALID) .AND. &
        (OBSSPD(I) .NE. RVALUE_MISSING) .AND. &
        (OBSSPD(I) .NE. SFCOBS_INVALID)) THEN
      CALL DISP_TO_UV(OBSDIR(I),OBSSPD(I),OBSWND(1,I),OBSWND(2,I))
      CALL DISP_TO_UV(ERRDIR(I),ERRSPD(I),ERRWND(1,I),ERRWND(2,I))
    ELSE
      OBSWND(1:2,I) = RVALUE_MISSING
      ERRWND(1:2,I) = RVALUE_MISSING
    ENDIF
  ENDDO

  CALL LAPS_DIVIDER
  WRITE(6,*) 'CONV_SFCOBS: Number of surface obs data read: ',NOBBOX,NOBGRD
  CALL LAPS_DIVIDER

  ! CONVERT TO THE REQUESTED DATA FORMAT:
  IF      (FORMAT_REQUEST .EQ. 'BUFR') THEN
    CALL BUFR_SFCOBS(NOBBOX,OBTIME, &
                     OBSLAT,OBSLON,STNAME,RPTYPE,PVNAME,OBSELV, &
                     MSLPRS,ERRPRS,STNPRS,ERRPRS,OBSTMP,ERRTMP, &
                     OBSWND,ERRWND,OBSRHS,ERRRHS,STNPRS,PRECP1,ERRPCP)
  ELSE IF (FORMAT_REQUEST .EQ. 'WRF' ) THEN
    CALL WRFD_SFCOBS(NOBBOX,OBTIME, &
                     OBSLAT,OBSLON,STNAME,RPTYPE,PVNAME,OBSELV, &
                     MSLPRS,ERRPRS,STNPRS,ERRPRS,OBSTMP,ERRTMP, &
                     OBSWND,ERRWND,OBSRHS,ERRRHS,STNPRS,PRECP1,ERRPCP)
  ENDIF

  ! DEALLOCATABLE MEMORY FOR SURFACE VARIABLES:
  DEALLOCATE(OBTIME,WMOIDS,STNAME, &
             PVNAME,PRSTWX,RPTYPE, &
             STNTYP,OBSLAT,OBSLON, &
             OBSELV,OBSTMP,OBSDEW, &
             OBSRHS,OBSDIR,OBSSPD, &
             GUSDIR,GUSSPD,OBSALT, &
             STNPRS,MSLPRS,PRSCHC, &
             PRSCH3,OBSVIS,OBSSOL, &
             SFCTMP,SFCMOI,PRECP1, &
             PRECP3,PRECP6,PREC24, &
             SNOWCV,CLDLYR,MAXTMP, &
             MINTMP,ERRTMP,ERRDEW, &
             ERRRHS,ERRDIR,ERRSPD, &
             ERRALT,ERRPRS,ERRVIS, &
             ERRSOL,ERRSFT,ERRSFM, &
             ERRPCP,ERRSNW, &
             CLDAMT,CLDHGT, &
             OBSWND,ERRWND, STAT=STATUS)
  IF (STATUS .NE. 0) THEN
    WRITE(6,*) 'CONV_SFCOBS: ERROR IN DEALLOCATING MEMORY FOR SURFACE OBS'
    STOP
  ENDIF

END SUBROUTINE CONV_SFCOBS

SUBROUTINE CONV_CDWACA

!==============================================================================
!  THIS ROUTINE READS AND CONVERTS CLOUD DRIFT WIND AND ACARS (PIREP) DATA INTO
!  REQUESTED DATA FORMAT
!
!  HISTORY:
!	CREATION:	YUANFU XIE	JUN 2007
!==============================================================================

  USE LAPS_PARAMS

  IMPLICIT NONE

  ! LOCAL VARIABLES:
  INTEGER, PARAMETER :: MAXOBS=200000	! LOCALLY DEFINED,CHANGE IT IF NEEDED
  CHARACTER :: EXTEND*3,OBSTYP*4,ASCTIM*9
  INTEGER   :: NUMOBS,STATUS
  INTEGER   :: OBSINT(3,MAXOBS)
  REAL      :: OBSLAT,OBSLON,OBSELV,OBSPRS,OBSDIR,OBSSPD,OBSTMP,OBSNON
  REAL*8    :: OBARRY(7,MAXOBS)

  ! CLOUD DRIFT WIND:
  NUMOBS = 0
  EXTEND = 'cdw'
  CALL OPEN_LAPSPRD_FILE_READ(POINTS_CHANNEL,SYSTEM_IN4TIME,EXTEND,STATUS)
  IF (STATUS .NE. 1) THEN
    PRINT*,'CONV_CDWACA: No cloud drift wind data'
  ELSE
    STATUS = 0
    DO
      CALL READ_LAPS_CDW_WIND(POINTS_CHANNEL,OBSLAT,OBSLON,OBSPRS,OBSDIR,OBSSPD, &
                               ASCTIM,STATUS)
      IF (STATUS .NE. 0) EXIT
      NUMOBS = NUMOBS+1
      IF (NUMOBS .GT. MAXOBS) THEN
        PRINT*,'CONV_CDW_ACA: Data array is too small, MAXOBS needs enlarge ',NUMOBS,MAXOBS
        STOP
      ENDIF
      PRINT*,'CONV_CDWACA: FOUND CDW DATA, COMPLETE THIS CODE'

      OBARRY(1:7,NUMOBS) = RVALUE_MISSING
      OBARRY(1,NUMOBS) = OBSLAT
      OBARRY(2,NUMOBS) = OBSLON
      OBARRY(4,NUMOBS) = OBSPRS
      OBARRY(5,NUMOBS) = OBSDIR
      OBARRY(6,NUMOBS) = OBSSPD

      OBSINT(1,NUMOBS) = 63		! USE BUFR REPORT TYPE CODE: 
                                        ! 63 SATELLITE DERIVED WIND
      OBSINT(2,NUMOBS) = 241		! RERORT TYPE: SATWIND
      CALL CV_ASC_I4TIME(ASCTIM,OBSINT(3,NUMOBS))
      PRINT*,'CDW: ',OBSLAT,OBSLON,OBSPRS,OBSDIR,OBSSPD,OBSINT(3,NUMOBS)
    ENDDO
  ENDIF
  CLOSE(POINTS_CHANNEL)
  PRINT*,'CONV_CDWACA: Total of CDW OBS: ',NUMOBS

  ! ACAR (PIREP):
  EXTEND = 'pin'

  ! 1. TEMP:
  OBSTYP = 'temp'
  CALL OPEN_LAPSPRD_FILE_READ(POINTS_CHANNEL,SYSTEM_IN4TIME,EXTEND,STATUS)
  IF (STATUS .NE. 1) THEN
    PRINT*,'CONV_CDWACA: No ACAR (PIREP) temp data'
  ELSE
    STATUS = 0
    DO
      CALL READ_ACARS_OB(POINTS_CHANNEL,OBSTYP,OBSLAT,OBSLON,OBSELV,OBSTMP,OBSNON, &
                               ASCTIM,0,STATUS)
      IF (STATUS .NE. 0) EXIT
      NUMOBS = NUMOBS+1
      IF (NUMOBS .GT. MAXOBS) THEN
        PRINT*,'CONV_CDW_ACA: Data array is too small, MAXOBS needs enlarge ',NUMOBS,MAXOBS
        STOP
      ENDIF
      OBARRY(1:7,NUMOBS) = RVALUE_MISSING
      OBARRY(1,NUMOBS) = OBSLAT
      OBARRY(2,NUMOBS) = OBSLON
      OBARRY(3,NUMOBS) = OBSELV
      OBARRY(7,NUMOBS) = OBSTMP
      OBSINT(1,NUMOBS) = 41		! USE BUFR REPORT TYPE CODE: 
                                        ! 41 ACARS TEMPERATURE
      OBSINT(2,NUMOBS) = 130		! PILOR REPORT: TEMPERATURE
      CALL CV_ASC_I4TIME(ASCTIM,OBSINT(3,NUMOBS))
      PRINT*,'ACAR TEMP: ',OBSLAT,OBSLON,OBSELV,OBSTMP,OBSINT(3,NUMOBS)
    ENDDO
  ENDIF
  CLOSE(POINTS_CHANNEL)
  PRINT*,'CONV_CDWACA: Total of CDW + ACAR TEMP OBS: ',NUMOBS

  ! 1. WIND:
  OBSTYP = 'wind'
  CALL OPEN_LAPSPRD_FILE_READ(POINTS_CHANNEL,SYSTEM_IN4TIME,EXTEND,STATUS)
  IF (STATUS .NE. 1) THEN
    PRINT*,'CONV_CDWACA: No ACAR (PIREP) wind data'
  ELSE
    STATUS = 0
    DO
      CALL READ_ACARS_OB(POINTS_CHANNEL,OBSTYP,OBSLAT,OBSLON,OBSELV,OBSDIR,OBSSPD, &
                               ASCTIM,0,STATUS)
      IF (STATUS .NE. 0) EXIT
      NUMOBS = NUMOBS+1
      IF (NUMOBS .GT. MAXOBS) THEN
        PRINT*,'CONV_CDWACA: Data array is too small, MAXOBS needs enlarge ',NUMOBS,MAXOBS
        STOP
      ENDIF
      OBARRY(1:7,NUMOBS) = RVALUE_MISSING
      OBARRY(1,NUMOBS) = OBSLAT
      OBARRY(2,NUMOBS) = OBSLON
      OBARRY(3,NUMOBS) = OBSELV
      CALL DISP_TO_UV(OBSDIR,OBSSPD,OBSTMP,OBSNON)
      CALL UVTRUE_TO_UVGRID(OBSTMP,OBSNON,OBSDIR,OBSSPD,OBSLON)
      OBARRY(5,NUMOBS) = OBSDIR
      OBARRY(6,NUMOBS) = OBSSPD
      OBSINT(1,NUMOBS) = 41		! USE BUFR REPORT TYPE CODE: 
                                        ! ACARS WIND
      OBSINT(2,NUMOBS) = 230		! PILOR REPORT: TEMPERATURE
      CALL CV_ASC_I4TIME(ASCTIM,OBSINT(3,NUMOBS))
      PRINT*,'ACAR WIND: ',OBSLAT,OBSLON,OBSELV,OBSDIR,OBSSPD,OBSINT(3,NUMOBS)
    ENDDO
  ENDIF
  CLOSE(POINTS_CHANNEL)
  PRINT*,'CONV_CDWACA: Total of CDW + ACAR TEMP + ACAR WIND OBS: ',NUMOBS

  IF (NUMOBS .EQ. 0) RETURN

  IF (FORMAT_REQUEST .EQ. 'BUFR') THEN
    CALL BUFR_CDWACA(NUMOBS,OBARRY,OBSINT)
  ELSE IF (FORMAT_REQUEST .EQ. 'WRF' ) THEN
    CALL WRFD_CDWACA(NUMOBS,OBARRY,OBSINT)
  ENDIF

END SUBROUTINE CONV_CDWACA


SUBROUTINE READ_RADAR

!==============================================================================
!doc  THIS ROUTINE READS MULTIPLE RADAR RADIAL WIND VELOCITY USING LAPS'
!doc  GET_MULTIRADAR_VEL.
!doc
!doc  HISTORY:
!doc	CREATION:	YUANFU XIE	MAR 2008
!==============================================================================

  USE LAPS_PARAMS
  USE MEM_NAMELIST		! LAPS WIND PARAMETER MODULE

  IMPLICIT NONE

  ! LOCAL VARIABLES:
  CHARACTER*31 :: RADEXT(MAX_RADARS)	! POSSIBLE RADAR NAME EXTENSIONS
  CHARACTER*4  :: RADNAM(MAX_RADARS)	! RADAR STATION NAMES
  INTEGER      :: NRADAR		! NUMBER OF RADAR AVAILABLE
  INTEGER      :: LCYCLE		! LAPS CYCLE TIME
  INTEGER      :: STTRAD,STTNQY 	! RADAR AND ITS NYQUIST STATUS
  INTEGER      :: NGRDRD(MAX_RADARS) 	! NUMBER OF GRIDPOINTS WITH MEASURABLE VEL
  INTEGER      :: NGRDRD_old(MAX_RADARS) 	! NUMBER OF GRIDPOINTS WITH MEASURABLE VEL
  INTEGER      :: RADTIM(MAX_RADARS)	! RADAR OBSERVATION TIME
  INTEGER      :: RADIDS(MAX_RADARS) 	! RADAR IDS
  INTEGER      :: I,J,K,L
  LOGICAL      :: CLUTTR		! .TRUE. -- REMOVE 3D RADAR CLUTTER
  REAL         :: RADVEL_old(NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2),NUMBER_GRIDPTS(3),MAX_RADARS)
  REAL         :: RADVEL(NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2),NUMBER_GRIDPTS(3),MAX_RADARS)
                  ! RADAR 4D VELOCITY GRID
  REAL         :: RADNQY(NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2),NUMBER_GRIDPTS(3),MAX_RADARS)
                  ! RADAR 4D NYQUIST VELOCITY
  REAL         :: UVZERO(NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2),NUMBER_GRIDPTS(3),2)
                  ! ZERO UV GRIDS USED FOR CALLING LAPS QC_RADAR_OBS
  REAL         :: UVBKGD(NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2),NUMBER_GRIDPTS(3),2)
                  ! UV BACKGROUND GRIDS USED FOR CALLING LAPS QC_RADAR_OBS
  REAL         :: UV4DML(NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2),NUMBER_GRIDPTS(3),-1:1,2)
                  ! UV BACKGROUND GRIDS USED FOR CALLING LAPS QC_RADAR_OBS
  REAL         :: VOLNQY(MAX_RADARS)		! VOLUME NYQUIST VELOCITY
  REAL         :: RADLAT(MAX_RADARS),RADLON(MAX_RADARS),RADHGT(MAX_RADARS)
  REAL         :: UVGRID(2)

  INCLUDE 'main_sub.inc'

  CLUTTR = .TRUE.		! TRUE. -- REMOVE 3D RADAR CLUTTER
  RADARS_TIMETOL = 900
  CALL GET_MULTIRADAR_VEL(SYSTEM_IN4TIME,RADARS_TIMETOL,RADTIM,MAX_RADARS, &
                           NRADAR,RADEXT,RVALUE_MISSING,CLUTTR, &
                           NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2),NUMBER_GRIDPTS(3), &
                           RADVEL,RADNQY,RADIDS,VOLNQY,NGRDRD,RADLAT,RADLON,RADHGT, &
                           RADNAM,STTRAD,STTNQY)

  ! SET UV ZERO GRIDS:
  UVZERO = 0.0

  ! GET LAPS BACKGROUND:
  CALL GET_LAPS_CYCLE_TIME(LCYCLE,STTRAD)
  CALL GET_FG_WIND_NEW(SYSTEM_IN4TIME,LCYCLE,NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2), &
                        NUMBER_GRIDPTS(3),-1,1,UV4DML(1,1,1,-1,1),UV4DML(1,1,1,-1,2), &
                        UVBKGD(1,1,1,1),UVBKGD(1,1,1,2),STTRAD)

  ! CONVERT TO GRID NORTH FROM TRUE NORTH:
  IF (( .NOT. L_GRID_NORTH_BKG) .AND. L_GRID_NORTH_ANAL) THEN
    WRITE(6,*) ' Rotating first guess (background) to grid north'

    DO K=1,NUMBER_GRIDPTS(3)
      DO J=1,NUMBER_GRIDPTS(2)
        DO I=1,NUMBER_GRIDPTS(1)
          CALL UVTRUE_TO_UVGRID(UVBKGD(1,1,1,1),UVBKGD(1,1,1,2), &
                                 UVGRID(1),UVGRID(2),DOMAIN_LONGITD(I,J))
          UVBKGD(i,j,k,1:2) = UVGRID(1:2)
        ENDDO
      ENDDO
    ENDDO
  ENDIF ! END OF CONVERSION TO GRID NORTH


  RADVEL_old = RADVEL
  NGRDRD_old = NGRDRD

  ! NYQUIST UNFOLDING:
!!! UNFINISHED: NEED MORE WORK APR. 2008
  DO L=1,NRADAR
    ! QC and unfolding radar nyquist:
!    CALL QC_RADAR_OBS(NUMBER_GRIDPTS(1),NUMBER_GRIDPTS(2),NUMBER_GRIDPTS(3), &
!                       RVALUE_MISSING,RADVEL(1,1,1,L),RADNQY(1,1,1,L),NGRDRD(L), &
!                       DOMAIN_LATITDE,DOMAIN_LONGITD,RADLAT(L),RADLON(L),RADHGT(L), &
!                       UVZERO(1,1,1,1),UVZERO(1,1,1,2),UVBKGD(1,1,1,1),UVBKGD(1,1,1,2), &
!                       VOLNQY(L),L_CORRECT_UNFOLDING,L_GRID_NORTH,STTRAD)
    PRINT*,'STATUS OF QC_RADAR_OBS: ',STTRAD

  IF (NGRDRD_old(L) .NE. NGRDRD(L)) PRINT*,'Number grid RADAR CHANGE: ',ngrdrd_old(L),ngrdrd(L)
    DO K=1,NUMBER_GRIDPTS(3)
      DO J=1,NUMBER_GRIDPTS(2)
        DO I=1,NUMBER_GRIDPTS(1)
          IF (RADVEL(I,J,K,L) .NE. RVALUE_MISSING) PRINT*,'RADIAL: ', &
	      RADVEL(I,J,K,L),RADNQY(I,J,K,L),I,J,K,L,NGRDRD(L),VOLNQY(L)
          IF (RADVEL_old(i,j,k,L) .NE. RADVEL(i,j,k,L)) print*,'Unfolded: ', &
              radvel_old(i,j,k,l),radvel(i,j,k,l)
        ENDDO
      ENDDO
    ENDDO

  ENDDO

  STOP

END SUBROUTINE READ_RADAR
