cdis   
cdis    Open Source License/Disclaimer, Forecast Systems Laboratory
cdis    NOAA/OAR/FSL, 325 Broadway Boulder, CO 80305
cdis    
cdis    This software is distributed under the Open Source Definition,
cdis    which may be found at http://www.opensource.org/osd.html.
cdis    
cdis    In particular, redistribution and use in source and binary forms,
cdis    with or without modification, are permitted provided that the
cdis    following conditions are met:
cdis    
cdis    - Redistributions of source code must retain this notice, this
cdis    list of conditions and the following disclaimer.
cdis    
cdis    - Redistributions in binary form must provide access to this
cdis    notice, this list of conditions and the following disclaimer, and
cdis    the underlying source code.
cdis    
cdis    - All modifications to this software must be clearly documented,
cdis    and are solely the responsibility of the agent making the
cdis    modifications.
cdis    
cdis    - If significant modifications or enhancements are made to this
cdis    software, the FSL Software Policy Manager
cdis    (softwaremgr@fsl.noaa.gov) should be notified.
cdis    
cdis    THIS SOFTWARE AND ITS DOCUMENTATION ARE IN THE PUBLIC DOMAIN
cdis    AND ARE FURNISHED "AS IS."  THE AUTHORS, THE UNITED STATES
cdis    GOVERNMENT, ITS INSTRUMENTALITIES, OFFICERS, EMPLOYEES, AND
cdis    AGENTS MAKE NO WARRANTY, EXPRESS OR IMPLIED, AS TO THE USEFULNESS
cdis    OF THE SOFTWARE AND DOCUMENTATION FOR ANY PURPOSE.  THEY ASSUME
cdis    NO RESPONSIBILITY (1) FOR THE USE OF THE SOFTWARE AND
cdis    DOCUMENTATION; OR (2) TO PROVIDE TECHNICAL SUPPORT TO USERS.
cdis   
cdis
cdis
cdis   
cdis
      Subroutine Remap_process(
     :         i_tilt,                                     ! Integer*4 (input)
     :         i_last_scan,                                ! Integer*4 (input)
     :         i_first_scan,                               ! Integer*4 (input)
     :         grid_rvel,grid_rvel_sq,grid_nyq,ngrids_vel,n_pot_vel,
     :         grid_ref,ngrids_ref,n_pot_ref,
     :         NX_L,NY_L,NZ_L,
     :         laps_radar_ext,c3_radar_subdir,             ! Char*3    (input)
     :         path_to_vrc,                                ! Char      (input)
     :         i_product_i4time,                           ! Integer*4 (input)
     :         full_fname,                                 ! Character*91
     :         i4_fn_length,                               ! Integer*4 (output)
     :         i_num_finished_products,                    ! Integer*4 (output)
     :         i_status)                                   ! Integer*4 (output)
c
c     Subroutine remap_process
c
c     PURPOSE:
c       Main process routine for the REMAPPING algorithm
c
c **************************** History Section ****************************
c
c       Windsor, C. R.  10-JUL-1985     Original version
c       Albers, Steve    7-APR-1986     Update for version 03
c       Albers, Steve      JUN-1987     Map velocities to LAPS grid
c       Albers, Steve      MAR-1988     Streamlined and converted to 87 data
c       Albers, Steve      DEC-1988     FURTHER conversions for RT87 cartesian
c       Albers, Steve      MAY-1992     Turn off range unfolding for velocities
c       Albers, Steve      FEB-1993     MIN#, 40% FRAC QC for Reflectivity added
c       Albers, Steve      MAY-1994     88D Version for SUN RISC BOX
c       Brewster, Keith    AUG-1994     Clean-out of artifacts
c       Brewster, Keith    APR-1995     Added INITIAL_GATE parameter
c                                       Modified volume nyquist determination.
c       Brewster, Keith    SEP-1995     Added point-by-point Nyquist calc.
c       Albers, Steve   19-DEC-1995     Changed gate_spacing_m variable to 
c                                       gate_spacing_m_ret to prevent 
c                                       reassigning a parameter value. The 
c                                       location is the call to read_data_88D 
c                                       and a new declaration.
c                                       Environment variable evaluations added
c                                       for FTPing and purging the output.
c                                       New streamlined purging function.
c       Albers, Steve      FEB-1996     Linear reflectivity averaging (via lut)
c       Albers, Steve      MAY-1996     New igate_lut to reduce processing 
c       Albers, Steve          1998     More flexibility added

*********************** Declaration Section **************************
c
      include 'trigd.inc'
      implicit none
c
c     Input variables
c
      integer*4 i_tilt
      integer*4 i_last_scan
      integer*4 i_first_scan
      integer*4 i_product_i4time
      integer   NX_L,NY_L,NZ_L
c
c     LAPS Grid Dimensions
c
      include 'remap_constants.dat'
      include 'remap.cmn'
      include 'remap.inc'
c
c     Output variables
c
      character*91 full_fname
      integer*4 i4_fn_length
      integer*4 i_num_finished_products
      integer*4 i_status
c
c     Processing parameters
c
      real re43
      parameter (re43 = 8503700.) ! 4/3 radius of the earth in meters
c
c
      integer*4 max_fields
      parameter (max_fields = 10)
c
c     Variables for NetCDF I/O
c
      character*150 dir

      character*9 gtime
      character*4 fhh
      character*31 ext,ext_in
      character*3 var_a(max_fields)
      character*125 comment_a(max_fields)
      character*10  units_a(max_fields)
      character*3 laps_radar_ext, c3_radar_subdir
      character*(*) path_to_vrc

c
c     Functions
c
      real height_to_zcoord
      real height_of_level
c
c     Misc local variables
c
      integer igate,i_scan_mode,jray,end_ext,ilut_ref
c
      Real*4  Slant_ranges_m (max_gates),
     :        Elevation_deg,
     :        Az_array(max_rays),
     :        Velocity(max_gates,max_rays),
     :        Reflect(max_gates,max_rays)

      real*4 out_array_4d(NX_L,NY_L,NZ_L,3)
      real*4 r_missing_data
c
      logical l_unfold
c 
      real*4 avgvel,vel_nyquist,vel_value,ref_value
      real*4 v_nyquist_tilt(max_tilts)
      real*4 v_nyquist_vol
      real*4 gate_spacing_m_ret
c
      integer i,j,k,k_low,ielev,igate_lut
      integer nazi,iran
      integer num_sweeps,n_rays,n_gates,n_obs_vel,n_output_data,nf
      integer igate_max
      integer igate_interval
      integer n_vel_grids_final,n_vel_grids_prelim
      integer n_ref_grids,n_ref_grids_qc_fail,nycor
      integer istatus,istatus_qc
      integer ishow_timer,i4_elapsed
      integer i_purge

      real vel_thr_rtau,rvel
      real rmax,height_max,rlat_radar,rlon_radar,rheight_radar
      real vknt,rknt,variance

      character*4 c4_radarname
      character*7 c7_laps_xmit
      character*7 c7_laps_purge
      character*7 c7_laps_sleep
c
c     Beginning of executable code
c
      rlat_radar = rlat_radar_cmn
      rlon_radar = rlon_radar_cmn
      rheight_radar = rheight_radar_cmn
      c4_radarname = c4_radarname_cmn

      i_num_finished_products = 0

      write(6,*)
      write(6,805) i_first_scan,i_last_scan,i_tilt
  805 format(' REMAP_PROCESS > V960112  ifirst,ilast,tilt'
     :                                           ,4i5)

      call get_r_missing_data(r_missing_data, i_status)
      if(i_status .ne. 1)then
          write(6,*)' Error in obtaining r_missing_data'
          return
      endif
c
c     For first scan, initialize sums and counters to zero.
c
      IF (i_first_scan .eq. 1 .or. i_first_scan .eq. 999) THEN

        I4_elapsed = ishow_timer()

        write(6,806)
  806   format
     1  (' REMAP_PROCESS > 1st sweep - Initializing vel/ref arrays')

        n_obs_vel = 0
        n_output_data = 0

        DO 100 k = 1,NZ_L
        DO 100 j = 1,NY_L
        DO 100 i = 1,NX_L
          grid_rvel(i,j,k) = 0.
          grid_rvel_sq(i,j,k) = 0.
          grid_nyq(i,j,k) = 0.
          grid_ref(i,j,k) = 0.
          ngrids_vel(i,j,k) = 0
          ngrids_ref(i,j,k) = 0
          n_pot_vel(i,j,k) = 0
          n_pot_ref(i,j,k) = 0
  100   CONTINUE
c
c     Compute maximum height of data needed.
c
        height_max = height_of_level(NZ_L)
c
c     Define Lower Limit of Radar Coverage in LAPS grid
c
        k_low = int(height_to_zcoord(rheight_radar,i_status))
        k_low = max(k_low,1)

      END IF

      I4_elapsed = ishow_timer()

c
c     Get radar data from the storage area.
c
      call Read_Data_88D(
     :               i_tilt,
     :               vel_thr_rtau,
     :               r_missing_data,       ! Input
     :               gate_spacing_m_ret,   ! Output
     :               Num_sweeps,
     :               Elevation_deg,
     :               n_rays,
     :               n_gates,          ! Ref and Vel are on the same # of gates
     :               Slant_ranges_m,
     :               Velocity,
     :               Reflect,
     :               Az_Array,
     :               vel_nyquist,
     :               i_status)
c
      IF (i_status .ne. 1) GO TO 998 ! abnormal return
c
      v_nyquist_tilt(i_tilt) = vel_nyquist
c
      write(6,*)' REMAP_PROCESS > vel_nyquist for this tilt = '
     :        ,i_tilt,vel_nyquist
c
c     Find elevation index in look up table
c
      ielev = nint((elevation_deg * LUT_ELEVS)/MAX_ELEV)
      ielev = max(ielev,0)
      ielev = min(ielev,LUT_ELEVS)
      write(6,*)' REMAP_PROCESS > elev index = ',ielev
c
c     Compute max range from elevation angle
c
      rmax = -re43 * sind(elevation_deg)
     :  + sqrt(re43*re43*sind(elevation_deg)**2 +
     :          height_max * (2.*re43 + height_max))


      print *, ' rmax,height_max= ',rmax,height_max

      print *, ' gate_spacing_m,gate_interval= ',gate_spacing_m,
     :           gate_interval

      igate_max = min(int(rmax/gate_spacing_m) , n_gates)

      write(6,809) i_scan_mode,n_gates,igate_max,elevation_deg
 809  format
     :(' REMAP_PROCESS > i_scan_mode,n_gates,igate_max,elevation = '
     :                                                 ,i3,2i5,f5.1)

      I4_elapsed = ishow_timer()

      write(6,*)' REMAP_PROCESS > Looping through rays and gates'

      DO 200 jray=1, n_rays

        nazi = nint(az_array(jray))
        nazi = mod(nazi,360)

        igate_interval=1

        DO 180 igate=INITIAL_REF_GATE,igate_max,igate_interval

          if(lgate_lut(igate))then ! we'll process this gate, it may have data

            igate_lut = igate/GATE_INTERVAL

            iran = gate_elev_to_projran_lut(igate_lut,ielev)

            i = azran_to_igrid_lut(nazi,iran)
            j = azran_to_jgrid_lut(nazi,iran)
            k = gate_elev_to_z_lut(igate_lut,ielev)

            IF (i .eq. 0 .OR. j.eq.0 .OR. k.eq.0 ) GO TO 180

            IF( lgate_vel_lut(igate) ) THEN

!           IF( igate .ge. INITIAL_VEL_GATE) THEN
c
c      Velocity Data
c
              n_pot_vel(i,j,k) = n_pot_vel(i,j,k) + 1
c
c      Map velocity if data present and abs value of velocity is
c      more than 2 ms-1.
c
              vel_value = Velocity(igate,jray)

              IF (abs(vel_value) .lt. VEL_MIS_CHECK .and.
     :            abs(vel_value) .gt. ABS_VEL_MIN ) THEN

                IF(ngrids_vel(i,j,k).eq.0) THEN

                  rvel =  vel_value

                ELSE

                  avgvel=grid_rvel(i,j,k)/float(ngrids_vel(i,j,k))
                  nycor=nint(0.5*(avgvel-vel_value)/
     :                     vel_nyquist)
                  rvel=vel_value+((2*nycor)*vel_nyquist)

                END IF

                n_obs_vel = n_obs_vel + 1
                grid_rvel(i,j,k) = grid_rvel(i,j,k) + rvel
                grid_rvel_sq(i,j,k) =
     :          grid_rvel_sq(i,j,k) + rvel*rvel
                grid_nyq(i,j,k)=grid_nyq(i,j,k)+vel_nyquist
                ngrids_vel(i,j,k) = ngrids_vel(i,j,k) + 1

              END IF

            END IF
c
c     Map reflectivity
c
            IF( lgate_ref_lut(igate) ) THEN

              n_pot_ref(i,j,k) = n_pot_ref(i,j,k) + 1

              ref_value = Reflect(igate,jray)

              IF (abs(ref_value) .lt. REF_MIS_CHECK) THEN

c               grid_ref(i,j,k) =
c    :          grid_ref(i,j,k) + ref_value

                ilut_ref = nint(ref_value * 10.) ! tenths of a dbz
                grid_ref(i,j,k) =
     :          grid_ref(i,j,k) + dbz_to_z_lut(ilut_ref)
                ngrids_ref(i,j,k) = ngrids_ref(i,j,k) + 1

              END IF

            ENDIF ! l_gate_ref(igate) = .true. and we process the reflectivity

          ENDIF ! l_gate(igate) = .true. and we need to process this gate

  180   CONTINUE ! igate
  200 CONTINUE ! jray

      write(6,815,err=816) elevation_deg,n_obs_vel
  815 format(' REMAP_PROCESS > End Ray/Gate Loop: Elev= ',F10.2
     :      ,'  n_obs_vel = ',I9)

  816 I4_elapsed = ishow_timer()

      IF (i_last_scan .eq. 1) THEN
        write(6,820)
  820   format(
     :  ' REMAP_PROCESS > Last Sweep - Dividing velocity & ref arrays')       


        n_vel_grids_prelim = 0
        n_vel_grids_final = 0
        n_ref_grids = 0
        n_ref_grids_qc_fail = 0

c
c     Diagnostic print-out
c
        write(6,825)
  825   format(' REMAP_PROCESS > Prepare reflectivity Output')

        DO 480 k = 1, k_low-1
        DO 480 j = 1, NY_L
        DO 480 i = 1, NX_L
          grid_ref(i,j,k)=r_missing_data
          grid_rvel(i,j,k)=r_missing_data
          grid_nyq(i,j,k)=r_missing_data
  480   CONTINUE

        DO 500 k = k_low,NZ_L

          write(6,826) k
  826     format(' REMAP_PROCESS > Dividing: k = ',i2)

          DO 400 j = 1,NY_L
          DO 400 i = 1,NX_L
c
c     NOTE MIN_VEL_SAMPLES MUST BE GREATER THAN 1
c
            IF(ngrids_vel(i,j,k) .ge. MIN_VEL_SAMPLES) THEN ! Good gates
              vknt=float(ngrids_vel(i,j,k))

              IF (vknt .ge. float(n_pot_vel(i,j,k))*COVERAGE_MIN) THEN

                n_vel_grids_prelim = n_vel_grids_prelim + 1
                variance =(  grid_rvel_sq(i,j,k) - 
     :                      (grid_rvel(i,j,k)*grid_rvel(i,j,k)/vknt) )
     :                     /(vknt-1.)

                IF (variance .lt. RV_VAR_LIM) THEN ! increment good counter

                  n_vel_grids_final = n_vel_grids_final + 1
                  grid_rvel(i,j,k) = grid_rvel(i,j,k)/vknt
                  grid_nyq(i,j,k) = grid_nyq(i,j,k)/vknt

                ELSE ! Failed VEL QC test

                  grid_rvel(i,j,k) = r_missing_data
                  grid_nyq(i,j,k) = r_missing_data
    
                END IF ! VEL QC test

              ELSE ! Insufficient coverage

                grid_rvel(i,j,k) = r_missing_data
                grid_nyq(i,j,k) = r_missing_data

              END IF ! Velocity Coverage check

            ELSE ! Insufficient velocity count

              grid_rvel(i,j,k) = r_missing_data
              grid_nyq(i,j,k) = r_missing_data

            END IF ! First check of velocity count
c
c     Reflectivity data
c
            IF(ngrids_ref(i,j,k) .ge. MIN_REF_SAMPLES) THEN ! Good gates
              rknt=float(ngrids_ref(i,j,k))
              IF (rknt .ge. float(n_pot_ref(i,j,k)) * COVERAGE_MIN) THEN

!               Calculate mean value of Z
                grid_ref(i,j,k) = grid_ref(i,j,k)/rknt

!               Convert from Z to dbZ
                grid_ref(i,j,k) = alog10(grid_ref(i,j,k)) * 10.

                IF (grid_ref(i,j,k) .ge. REF_MIN) THEN

                  n_ref_grids = n_ref_grids + 1
                  IF(n_ref_grids .lt. 200)
     :               write(6,835) i,j,k,grid_ref(i,j,k)
  835                format(' Grid loc: ',3(i4,','),'  Refl: ',f6.1)

                ELSE ! Failed REF QC test
 
                  n_ref_grids_qc_fail = n_ref_grids_qc_fail + 1
                  grid_ref(i,j,k) = r_missing_data

                END IF ! Passed REF QC test

              ELSE ! Insufficent coverage

                grid_ref(i,j,k) = r_missing_data

              END IF   ! coverage check of count

            ELSE ! Insufficent data count

              grid_ref(i,j,k) = r_missing_data

            END IF   ! first check of count

  400     CONTINUE ! i,j
  500   CONTINUE ! k

        I4_elapsed = ishow_timer()
c
c     Call QC routine (Now Disabled)
c
        istatus_qc = 1
c       call radar_qc(NX_L,NY_L,NZ_L,grid_rvel,istatus_qc)
        IF (istatus_qc .ne. 1) THEN
          i_num_finished_products = 0
          write(6,840)
  840     format(' REMAP_PROCESS > Bad data detected, no data written')       
          GO TO 998 ! abnormal return
        END IF

        write(6,842) n_ref_grids_qc_fail,n_ref_grids
  842   format(' REMAP_PROCESS > N_REF_QC_FAIL/N_REF = ',2I12)

        IF (n_ref_grids .lt. REF_GRIDS_CHECK) THEN
          i_num_finished_products = 0
          write(6,845) n_ref_grids,REF_GRIDS_CHECK
  845     format(' REMAP_PROCESS > ',i4,' ref grids < ',i4
     :                                 ,'no data file written...')
          GO TO 999 ! normal return
        END IF

        write(6,851)n_ref_obs_old(1),n_ref_grids,i4time_old(1)
     1                                          ,i_product_i4time

  851   format(' REMAP_PROCESS > Ref Obs: Old/New',2i6
     :        ,' I4time: Old/New',2i11)

        i4time_old(1) = i_product_i4time
        n_ref_obs_old(1) = n_ref_grids
c
c     Determine filename extension
        ext = laps_radar_ext
        write(6,*)' REMAP_PROCESS > laps_ext = ',laps_radar_ext
c
c     Prepare to write out data
c
        I4_elapsed = ishow_timer()

        write(6,865) c4_radarname,ext(1:3)
  865   format(' REMAP_PROCESS > Calling write_laps_data ',a4,2x,a3)       
c
        var_a(1) = 'REF'
        var_a(2) = 'VEL'
        var_a(3) = 'NYQ'
        units_a(1) = 'dBZ'
        units_a(2) = 'M/S'
        units_a(3) = 'M/S'
        comment_a(1) = 'Doppler Reflectivity'
        comment_a(2) = 'Doppler Velocity'
        comment_a(3) = 'Nyquist Velocity'
        nf = 3

        if(.true.)then

            DO 550 k = 1,NZ_L
            DO 550 j = 1,NY_L
            DO 550 i = 1,NX_L
              out_array_4d(i,j,k,1) = grid_ref(i,j,k)
              out_array_4d(i,j,k,2) = grid_rvel(i,j,k)
              out_array_4d(i,j,k,3) = grid_nyq(i,j,k)
  550       CONTINUE

        endif ! .true.
c
c       DO 555 k=7,9
c       print *, 'sample data on level ',k
c       DO 555 j=1,NY_L
c       DO 555 i=60,60
c         print *,i,j,grid_ref(i,j,k),grid_rvel(i,j,k)
c 555   CONTINUE
c

        v_nyquist_vol = -999.
        write(6,875) i_tilt
  875   format(' Determine v_nyquist for the ',i4,' tilt volume')
c
        DO 600 i = 1,i_tilt
          write(6,880) i,v_nyquist_tilt(i)
  880     format(' i_tilt:',I6,'  v_nyquist_tilt:',e12.4)
          IF (v_nyquist_tilt(i) .gt. 0.) THEN
            IF (v_nyquist_vol .gt. 0.) THEN
              IF (v_nyquist_tilt(i) .ne. v_nyquist_vol) THEN
                v_nyquist_vol = r_missing_data
                write(6,886)
  886           format(' Nyquist has changed for the tilt',
     1                 ', set v_nyquist_vol to missing.')
                GO TO 601
              END IF
            ELSE
              v_nyquist_vol = v_nyquist_tilt(i)
            END IF
          END IF
  600   CONTINUE
  601   CONTINUE
c
c     Write out header type info into the comment array
c
        l_unfold=.false.
        write(comment_a(1),888)rlat_radar,rlon_radar,rheight_radar
     1       ,n_ref_grids,c4_radarname
        write(comment_a(2),889)rlat_radar,rlon_radar,rheight_radar
     1       ,n_vel_grids_final,c4_radarname,v_nyquist_vol,l_unfold
        write(comment_a(3),888)rlat_radar,rlon_radar,rheight_radar
     1       ,n_vel_grids_final,c4_radarname

  888   format(2f9.3,f8.0,i7,a4,3x)
  889   format(2f9.3,f8.0,i7,a4,3x,e12.4,l2)

        write(6,890)comment_a(1)(1:80)
        write(6,890)comment_a(2)(1:80)
        write(6,890)comment_a(3)(1:80)
  890   format(a80)

        I4_elapsed = ishow_timer()

        if(laps_radar_ext .ne. 'vrc')then
            call put_laps_multi_3d(i_product_i4time,ext,var_a,units_a,       
     1              comment_a,out_array_4d,NX_L,NY_L,NZ_L,nf,istatus)

        else ! Single level of data (as per WFO)
            call put_remap_vrc(i_product_i4time,comment_a(1)
     1             ,rlat_radar,rlon_radar,rheight_radar
     1             ,out_array_4d(1,1,1,1),NX_L,NY_L,NZ_L
     1             ,c3_radar_subdir,path_to_vrc,r_missing_data,istatus)       

        endif

        I4_elapsed = ishow_timer()

!       go to 900

900     continue

      END IF ! i_last_scan

      go to 999 ! normal return

!     Return section

998   i_status = 0
      write(6,*) ' WARNING: Return from remap_process with 0 status'
      RETURN

999   i_status = 1
      RETURN

      END


        subroutine purge(ext,nfiles,ntime_min,i4time_now)

!       Keeps number of files according to nfiles or time span according to
!       ntime_min, whichever is greater

        integer MAX_FILES
        parameter (MAX_FILES = 1000)

        character*9 asc_tim_9
        character*31 ext
        character*255 c_filespec
        character c_fnames(MAX_FILES)*80

        c_filespec = '../lapsprd/'//ext(1:3)//'/*.'//ext(1:3)//'*'         

        write(6,*)c_filespec

        call    Get_file_names(  c_filespec,
     1			 i_nbr_files_ret,
     1			 c_fnames,MAX_FILES,
     1			 i_status )

        if(i_nbr_files_ret .gt. 0)then
            call get_directory_length(c_fnames(1),lenf)
            write(6,*)i_nbr_files_ret,' file(s) in directory'
        else ! Error Condition
            write(6,*)' No files in directory'
            istatus = 0
            return
        endif

        ntime_sec = ntime_min * 60

10      do i=1,i_nbr_files_ret-nfiles ! Loop through excess versions
            asc_tim_9 = c_fnames(i)(lenf+1:lenf+9)
            call i4time_fname_lp(asc_tim_9,I4time_file,istatus)
            if(i4time_now - i4time_file .gt. ntime_sec)then ! File is too old

!               Delete the file
!               call rm_file(c_fnames(i)(1:lenf+13),istatus)
                call rm_file(c_fnames(i),istatus)


            endif
        enddo

        return
        end


        subroutine rm_file(c_filename,istatus)

        character*(*) c_filename

        integer istatus

        lun = 151

        write(6,*)' rm_file ',c_filename

        open(lun,file=c_filename,status='unknown')

        close(lun,status='delete')

        istatus = 1
 
        return
        end



        subroutine put_remap_vrc(i4time,comment_2d 
     1                         ,rlat_radar,rlon_radar,rheight_radar
     1                         ,field_3d,imax,jmax,kmax,c3_radar_subdir        
     1                         ,path_to_vrc,r_missing_data,istatus)

!       Stuff from 'put_laps_2d' except how do we handle radar subdir?

        character*150 DIRECTORY
        character*150 DIRECTORY1
        character*31 EXT

        character*125 comment_2d
        character*10 units_2d
        character*3 var_2d
        integer*4 LVL_2d
        character*4 LVL_COORD_2d

        real*4 field_3d(imax,jmax,kmax)
        real*4 field_2d(imax,jmax)
        real*4 lat(imax,jmax)
        real*4 lon(imax,jmax)
        real*4 topo(imax,jmax)

        character*9 a9time
        character*8 radar_subdir
        character*3 c3_radar_subdir
        character*(*) path_to_vrc

        call make_fnam_lp(i4time,a9time,istatus)
        if(istatus .ne. 1)return

        write(6,*)' Subroutine put_remap_vrc for ',a9time

        call get_ref_base(ref_base,istatus)
        if(istatus .ne. 1)return

!       Get column max reflectivity (eventually pass in r_missing_data)
        call get_max_reflect(field_3d,imax,jmax,kmax,ref_base ! r_missing_data
     1                      ,field_2d)

        call get_laps_domain(imax,jmax,'nest7grid',lat,lon,topo,istatus)       
        if(istatus .ne. 1)then
            write(6,*)' Error calling get_laps_domain'
            return
        endif

        call ref_fill_horz(field_2d,imax,jmax,1,lat,lon
     1                    ,rlat_radar,rlon_radar,rheight_radar,istatus)       
        if(istatus .ne. 1)then
            write(6,*)' Error calling ref_fill_horz'          
            return
        endif

        ext = 'vrc'
        var_2d = 'REF'
        units_2d = 'DBZ'

        write(6,*)'path_to_vrc = ',path_to_vrc

        if(path_to_vrc .eq. 'rdr')then
            radar_subdir = c3_radar_subdir
            write(6,*)' radar_subdir = ',radar_subdir

            call get_directory('rdr',directory1,len_dir1)

            directory = directory1(1:len_dir1)//radar_subdir(1:3)
     1                                        //'/vrc/'  
            call s_len(directory,len_dir)

        else ! 'lapsprd'
            call get_directory('vrc',directory,len_dir)

        endif            

        write(6,11)directory(1:len_dir),ext(1:5),var_2d
11      format(' Writing 2d ',a,1x,a5,1x,a3)

        lvl_2d = 0
        lvl_coord_2d = 'MSL'

        CALL WRITE_LAPS_DATA(I4TIME,DIRECTORY,EXT,imax,jmax,
     1  1,1,VAR_2D,LVL_2D,LVL_COORD_2D,UNITS_2D,
     1                     COMMENT_2D,field_2d,ISTATUS)

        return
        end
