
      subroutine insert_derived_radar_obs(
     1   mode                                       ! Input
     1  ,n_radars,max_radars,idx_radar_a            ! Input
     1  ,imax,jmax,kmax                             ! Input
     1  ,r_missing_data                             ! Input
     1  ,heights_3d                                 ! Input
     1  ,vr_obs_unfltrd                             ! Input
     1  ,thresh_2_radarobs_lvl_unfltrd_in           ! Input
     1  ,thresh_4_radarobs_lvl_unfltrd_in           ! Input
     1  ,thresh_9_radarobs_lvl_unfltrd_in           ! Input
     1  ,i4time                                     ! Input
     1  ,lat,lon                                    ! Input
     1  ,rlat_radar,rlon_radar                      ! Input
     1  ,rheight_radar                              ! Input
     1  ,upass1,vpass1                              ! Input
     1  ,u_laps_bkg,v_laps_bkg                      ! Input
     1  ,weight_radar                               ! Input
     1  ,l_derived_output,l_grid_north              ! Input
     1  ,wt_p_radar                                 ! Input/Output
     1  ,uobs_diff_spread,vobs_diff_spread          ! Input/Output
     1  ,l_analyze,icount_radar_total               ! Output
     1  ,n_radarobs_tot_unfltrd                     ! Input
     1  ,istatus                                    ! Input/Output
     1                                                          )

      real   vr_obs_unfltrd(imax,jmax,kmax,max_radars)             ! Input
      real   rlat_radar(max_radars),rlon_radar(max_radars)         ! Input
      real   rheight_radar(max_radars)                             ! Input
      real   lat(imax,jmax),lon(imax,jmax)                         ! Input

!     First pass analyzed winds (innovation analysis with non-radar data)
      real   upass1(imax,jmax,kmax),vpass1(imax,jmax,kmax)         ! Input

!     Background winds
      real   u_laps_bkg(imax,jmax,kmax),v_laps_bkg(imax,jmax,kmax) ! Input

      real   uobs_diff_spread(imax,jmax,kmax)                      ! I/O
     1        ,vobs_diff_spread(imax,jmax,kmax)
      real   wt_p_radar(imax,jmax,kmax)                            ! I/O
      real   heights_3d(imax,jmax,kmax)                            ! Input

      real   vr_obs_fltrd(imax,jmax,max_radars)                    ! Local
      real   upass1_buf(imax,jmax,kmax)                            ! Local
      real   vpass1_buf(imax,jmax,kmax)                            ! Local

      real   xx(max_radars),yy(max_radars)                         ! Local
      real   xx2(max_radars),yy2(max_radars)                       ! Local
      real   vr(max_radars),ht(max_radars)                         ! Local
      real   x(imax,jmax),y(imax,jmax)                             ! Local

      integer n_radarobs_tot_unfltrd(max_radars)                   ! Input
      integer n_radarobs_tot_fltrd(max_radars)                     ! Local
      integer i_radar_reject(max_radars)                           ! Local
      integer idx_radar_a(max_radars)                              ! Input

!     Number of unfiltered radar obs associated with each filtered one
      integer n_superob(imax,jmax,kmax,max_radars)                 ! Local

      integer thresh_2_radarobs_lvl_unfltrd_in                     ! Input
     1         ,thresh_4_radarobs_lvl_unfltrd_in
     1         ,thresh_9_radarobs_lvl_unfltrd_in

      integer thresh_2_radarobs_lvl_unfltrd                        ! Local
     1         ,thresh_4_radarobs_lvl_unfltrd
     1         ,thresh_9_radarobs_lvl_unfltrd

      logical  l_good_multi_doppler_ob(imax,jmax,kmax)               ! Local
      logical  l_analyze(kmax),l_derived_output,l_grid_north
      logical  l_multi_doppler_new, l_first_call, l_write_dxx        ! Local

      save l_first_call

      data l_multi_doppler_new /.true./ ! Flag for new CWB routine
      data l_first_call /.true./ ! Flag for new CWB routine

      if(l_first_call)then
          l_write_dxx = .true.
          l_first_call = .false.
      else
          l_write_dxx = .false.
      endif

csms$ignore begin
      write(6,*)' Entering insert_derived_radar_obs, mode =',mode

!     Initialize l_good_multi_doppler_ob if mode = 2
      if(mode .eq. 2)then
          l_good_multi_doppler_ob = .false.
          thresh_2_radarobs_lvl_unfltrd = 999999 ! disable filtering
          thresh_4_radarobs_lvl_unfltrd = 999999
          thresh_9_radarobs_lvl_unfltrd = 999999
      else ! do filtering when we have single doppler obs
          thresh_2_radarobs_lvl_unfltrd = 
     1    thresh_2_radarobs_lvl_unfltrd_in     
          thresh_4_radarobs_lvl_unfltrd = 
     1    thresh_4_radarobs_lvl_unfltrd_in     
          thresh_9_radarobs_lvl_unfltrd = 
     1    thresh_9_radarobs_lvl_unfltrd_in     
      endif

      write(6,*)' Filtering thresholds = ',
     1                  thresh_2_radarobs_lvl_unfltrd, 
     1                  thresh_4_radarobs_lvl_unfltrd, 
     1                  thresh_9_radarobs_lvl_unfltrd

!     This routine takes the data from all the radars and adds the derived
!     radar obs into uobs_diff_spread and vobs_diff_spread

      n_radarobs_tot_fltrd = 0
      i_radar_reject = 0
      vr_obs_fltrd = r_missing_data ! initialize array
!     n_superob = 0 ! initialize array

      if(.false.)then ! original radar analysis method
        continue

      else ! call new multi-doppler routine (l_multi_doppler_new = T)
!       Set up x and y arrays
        call get_earth_radius(earth_radius,istatus)

        do j = 1,jmax
        do i = 1,imax
            call latlon_to_xy(lat(i,j),lon(i,j),earth_radius
     1                       ,x(i,j),y(i,j))
        enddo ! i
        enddo ! j

        n_rdrobs_grdtot_unfltrd = 0
        n_rdrobs_grdtot_fltrd = 0
        do k = 1,kmax
          do i_radar = 1,n_radars

!             Filter radar at this level to make the filtered ob array sparser
              call filter_radar_obs(
     1                  imax,jmax,                     ! Input
     1                  vr_obs_unfltrd(1,1,k,i_radar), ! Input
     1                  wt_p_radar(1,1,k),weight_radar,! Input
     1                  thresh_2_radarobs_lvl_unfltrd, ! Input
     1                  thresh_4_radarobs_lvl_unfltrd, ! Input
     1                  thresh_9_radarobs_lvl_unfltrd, ! Input
     1                  r_missing_data,                ! Input
     1                  vr_obs_fltrd(1,1,i_radar),     ! Input/Output
     1                  i_radar_reject(i_radar),       ! Input/Output
     1                  n_superob,                     ! Input/Output
     1                  n_radarobs_lvl_unfltrd,        ! Output
     1                  n_radarobs_lvl_fltrd,          ! Output
     1                  intvl_rad,                     ! Output
     1                  istatus)                       ! Output

              write(6,503)k,i_radar,intvl_rad,n_radarobs_lvl_unfltrd
     1                                       ,n_radarobs_lvl_fltrd
 503          format(1x,'k/rdr#/intvl/unfiltered/filtered',i4,i4,i4,2i6)

              n_radarobs_tot_fltrd(i_radar) =
     1        n_radarobs_tot_fltrd(i_radar) + n_radarobs_lvl_fltrd       

              if(k .eq. kmax)then
                  write(6,*)' # Radar Obs Rejected due to other data = '
     1                     ,i_radar_reject(i_radar)
     1                     ,i_radar,idx_radar_a(i_radar)
                  write(6,502)i_radar,n_radarobs_tot_unfltrd(i_radar)
     1                               ,n_radarobs_tot_fltrd(i_radar)
502               format(1x,
     1                ' # Radar Obs TOTAL UNFILTERED / FILTERED = ',i3
     1                                                            ,2i7)   

                  n_rdrobs_grdtot_unfltrd = n_rdrobs_grdtot_unfltrd 
     1                               + n_radarobs_tot_unfltrd(i_radar)

                  n_rdrobs_grdtot_fltrd = n_rdrobs_grdtot_fltrd 
     1                               + n_radarobs_tot_fltrd(i_radar)

              endif ! k

              call latlon_to_xy(rlat_radar(i_radar),rlon_radar(i_radar)       
     1                         ,earth_radius,xx(i_radar),yy(i_radar))

          enddo ! i_radar

          do j = 1,jmax
          do i = 1,imax

!             Assess the radars that have data at this grid point
              n_illuminated = 0
              do i_radar = 1,n_radars
                  if(vr_obs_fltrd(i,j,i_radar) .ne. r_missing_data
     1                                                             )then       
                      n_illuminated = n_illuminated + 1
                      vr(n_illuminated) = vr_obs_fltrd(i,j,i_radar)
                      ht(n_illuminated) = rheight_radar(i_radar)
                      xx2(n_illuminated) = xx(i_radar)
                      yy2(n_illuminated) = yy(i_radar)

!                     pointer for dxx file                     
                      i_illuminated_last = idx_radar_a(i_radar) 

                  endif

              enddo ! i_radar

              u_bkg_full = upass1(i,j,k) + u_laps_bkg(i,j,k)
              v_bkg_full = vpass1(i,j,k) + v_laps_bkg(i,j,k)

              call multiwind_noz(u,v,rms,u_bkg_full,v_bkg_full
     1                          ,x(i,j),y(i,j),heights_3d(i,j,k)
     1                          ,n_illuminated,xx2,yy2,ht,vr,rmsmax,ier)       

              if(ier .eq. 0)then
                  n_radars_used = n_illuminated

!                 Subtract background from radar ob to get difference radar ob
                  uobs_diff_spread(i,j,k) = u - u_laps_bkg(i,j,k)
                  vobs_diff_spread(i,j,k) = v - v_laps_bkg(i,j,k)

                  if(n_illuminated .ge. 1 .and. l_write_dxx)then
                      call uv_to_disp(u,
     1                                v,
     1                                di_wind,
     1                                speed)

                      call open_dxx(i_illuminated_last,i4time,lun_dxx
     1                             ,istatus)
                      write(lun_dxx,321)i-1,j-1,k-1,di_wind,speed
321                   format(1x,3i4,2f6.1,2f6.1)
                  endif

                  wt_p_radar(i,j,k) = weight_radar
                  if(n_radars_used .ge. 2 .and. mode .eq. 2)then
                      l_good_multi_doppler_ob(i,j,k) = .true.
                  endif
              
              else
                  n_radars_used = 0
          
              endif

          enddo ! i
          enddo ! j

        enddo ! k

        write(6,*)' GRAND TOTAL RADAR UNFILTERED / FILTERED = ',
     1            n_rdrobs_grdtot_unfltrd,n_rdrobs_grdtot_fltrd

      endif ! l_multi_doppler_new

      icount_radar_total = 0

!     Use only multiple Doppler obs if mode = 2, use all obs if mode = 1
      do k = 1,kmax
        icount_good_lvl = 0
        if(mode .eq. 1)then ! Use all Doppler obs
            do j = 1,jmax
            do i = 1,imax
                if(wt_p_radar(i,j,k) .eq. weight_radar)then ! Good single or multi ob
                    icount_good_lvl = icount_good_lvl + 1
                endif
            enddo ! i
            enddo ! j
        elseif(mode .eq. 2)then ! Throw out single Doppler obs
            do j = 1,jmax
            do i = 1,imax
                if(wt_p_radar(i,j,k) .eq. weight_radar)then ! Good single or multi ob
                    if(.not. l_good_multi_doppler_ob(i,j,k))then
                        uobs_diff_spread(i,j,k) = r_missing_data
                        vobs_diff_spread(i,j,k) = r_missing_data
                        wt_p_radar(i,j,k) = r_missing_data
                    else
                        icount_good_lvl = icount_good_lvl + 1
                    endif
                endif
            enddo ! i
            enddo ! j
        endif ! mode

        if(icount_good_lvl .gt. 0)l_analyze(k) = .true.

        if(mode .eq. 1)then ! Use all Doppler obs
            write(6,504)k,icount_good_lvl,l_analyze(k)
504         format(' LVL',i3,' # sngl+multi = ',i6,l2)
        elseif(mode .eq. 2)then ! Use only multi Doppler obs
            write(6,505)k,icount_good_lvl,l_analyze(k)
505         format(' LVL',i3,' # multi = ',i6,l2)
        endif

        icount_radar_total = icount_radar_total + icount_good_lvl

      enddo ! k

      write(6,*)
     1     ' Finished insert_derived_radar_obs, icount_radar_total = '
     1    ,icount_radar_total

csms$ignore end
      return
      end



      subroutine filter_radar_obs(
     1                  imax,jmax,                    ! Input
     1                  vr_obs_unfltrd,               ! Input
     1                  wt_p_radar,weight_radar,      ! Input
     1                  thresh_2_radarobs_lvl_unfltrd,! Input
     1                  thresh_4_radarobs_lvl_unfltrd,! Input
     1                  thresh_9_radarobs_lvl_unfltrd,! Input
     1                  r_missing_data,               ! Input
     1                  vr_obs_fltrd,                 ! Input/Output
     1                  i_radar_reject,               ! Input/Output
     1                  n_superob,                    ! Input/Output
     1                  n_radarobs_lvl_unfltrd,       ! Output
     1                  n_radarobs_lvl_fltrd,         ! Output
     1                  intvl_rad,                    ! Output
     1                  istatus)                      ! Output

!       Filter to make the filtered ob array more sparse

        implicit none

!       Threshold number of radar obs on a given level
        integer thresh_2_radarobs_lvl_unfltrd
     1           ,thresh_4_radarobs_lvl_unfltrd
     1           ,thresh_9_radarobs_lvl_unfltrd
!       parameter (thresh_2_radarobs_lvl_unfltrd = 300)
!       parameter (thresh_4_radarobs_lvl_unfltrd = 600)
!       parameter (thresh_9_radarobs_lvl_unfltrd = 900)

        integer n_radarobs_lvl_unfltrd, intvl_rad, imax, jmax
        integer n_krn, n_krn_i_m1, n_krn_j_m1, n_krn_i, n_krn_j
        integer n_superob(imax,jmax),n_superob_tot
        integer istatus

        real vr_obs_unfltrd(imax,jmax)
        real wt_p_radar(imax,jmax)
        real vr_obs_fltrd(imax,jmax)
        real r_missing_data, weight_radar

        logical l_found_one, l_imax_odd, l_jmax_odd
        integer i,j,ii,jj,i_radar_reject,n_radarobs_lvl_fltrd

csms$ignore begin
        n_superob = 0 ! initialize array

!       Count number of unfiltered obs after rejecting obs having non-radar data
        n_radarobs_lvl_unfltrd = 0
        do j=1,jmax
        do i=1,imax
          if(vr_obs_unfltrd(i,j) .ne. r_missing_data)then       
            if(wt_p_radar(i,j) .ne. weight_radar .and.
     1         wt_p_radar(i,j) .ne. r_missing_data)then ! Non-radar ob
                vr_obs_unfltrd(i,j) = r_missing_data
                i_radar_reject = i_radar_reject + 1
            else
                n_radarobs_lvl_unfltrd = n_radarobs_lvl_unfltrd + 1
            endif
          endif
        enddo ! i
        enddo ! j

        l_imax_odd = 1 .eq. mod(imax,2)
        l_jmax_odd = 1 .eq. mod(jmax,2)

!       Test against threshold for number of radar obs on a given level
!       This logic is supposed to select a sparse subset of the radial
!       velocities yet retain grid boxes that are isolated

        if(n_radarobs_lvl_unfltrd .gt. thresh_9_radarobs_lvl_unfltrd
     1                                                         )then
           n_krn_i = 5
           n_krn_j = 5

        elseif(n_radarobs_lvl_unfltrd .gt. thresh_4_radarobs_lvl_unfltrd
     1                                                         )then
           n_krn_i = 2
           n_krn_j = 2

        elseif(n_radarobs_lvl_unfltrd .gt.
     1         thresh_2_radarobs_lvl_unfltrd)then
           n_krn_i = 2
           n_krn_j = 1

        endif

        if(n_radarobs_lvl_unfltrd .gt. thresh_9_radarobs_lvl_unfltrd
     1                                                         )then
           ! Keep only every 25th ob.  Keep one ob out of every 25.
           vr_obs_fltrd = r_missing_data
           n_krn_i = 5
           n_krn_j = 5
           n_krn_i_m1 = n_krn_i - 1
           n_krn_j_m1 = n_krn_j - 1
           intvl_rad = n_krn_i*n_krn_j

           do j=1,jmax-n_krn_i_m1,n_krn_i
           do i=1,imax-n_krn_j_m1,n_krn_j

!             Perform initial RMS check

!             If RMS scatter is small then proceed with filtering

              l_found_one = .false.
              do jj = j,j+n_krn_i_m1
              do ii = i,i+n_krn_j_m1
                 if  ( l_found_one ) then
                    if ( vr_obs_unfltrd(ii,jj) .ne. r_missing_data)then
                       n_superob(i,j) = n_superob(i,j) + 1
                    endif

                 elseif (vr_obs_unfltrd(ii,jj) .ne. r_missing_data
     1                                                            )then
                    vr_obs_fltrd(ii,jj) = vr_obs_unfltrd(ii,jj)
                    l_found_one = .true.
                    n_superob(i,j) = 1

                 else ! all missing in the kernel so far
                    continue

                 endif
              enddo ! ii
              enddo ! jj
           enddo ! i
           enddo ! j

        elseif(n_radarobs_lvl_unfltrd .gt. thresh_4_radarobs_lvl_unfltrd
     1                                                         )then
           ! Keep only every fourth ob.  Keep one ob out of every `quad'.
           intvl_rad = 4
           do j=1,jmax-1,2
           do i=1,imax-1,2
              l_found_one = .false.
              do jj = j,j+1
              do ii = i,i+1
                 if  ( l_found_one ) then
                    vr_obs_fltrd(ii,jj) = r_missing_data
                    if ( vr_obs_unfltrd(ii,jj) .ne. r_missing_data)then
                       n_superob(i,j) = n_superob(i,j) + 1
                    endif

                 elseif ( vr_obs_unfltrd(ii,jj) .ne. r_missing_data
     1                                                            )then
                    vr_obs_fltrd(ii,jj) = vr_obs_unfltrd(ii,jj)
                    l_found_one = .true.
                    n_superob(i,j) = 1

                 else
                    vr_obs_fltrd(ii,jj) = r_missing_data

                 endif
              enddo ! ii
              enddo ! jj
           enddo ! i

           if ( l_imax_odd ) then
              vr_obs_fltrd(imax,j) = r_missing_data
              vr_obs_fltrd(imax,j+1) = r_missing_data
           endif

           enddo ! j

           if ( l_imax_odd ) then
              do i=1,imax
                 vr_obs_fltrd(i,jmax) = r_missing_data
              enddo
           endif

        elseif(n_radarobs_lvl_unfltrd .gt.
     1         thresh_2_radarobs_lvl_unfltrd)then
           ! Keep every other ob.  Keep one ob out of every `pair'.
           intvl_rad = 2
           do j=1,jmax
           do i=1,imax
             vr_obs_fltrd(i,j) = r_missing_data
             if((i+j) .eq. ((i+j)/2)*2 .and. i .lt. imax)then ! Sum is even
               l_found_one = .false.
               do ii = i,i+1
                 if (vr_obs_unfltrd(ii,j) .ne. r_missing_data) then
                   if(.not. l_found_one)then
                      vr_obs_fltrd(ii,j) = vr_obs_unfltrd(ii,j)
                      l_found_one = .true.
                      n_superob(i,j) = 1
                   else ! already found one
                      n_superob(i,j) = n_superob(i,j) + 1
                   endif
                 endif
               enddo ! ii
             endif ! On checkerboard
           enddo ! i
           enddo ! j

        else
           ! Keep every ob
           intvl_rad = 1
           do j=1,jmax
           do i=1,imax
              vr_obs_fltrd(i,j) = vr_obs_unfltrd(i,j)
              if(vr_obs_fltrd(i,j) .ne. r_missing_data)then
                n_superob(i,j) = 1
              endif
           enddo
           enddo
        endif

!       Count number of filtered obs
        n_radarobs_lvl_fltrd = 0
        n_superob_tot = 0
        do j=1,jmax
        do i=1,imax
          if(vr_obs_fltrd(i,j) .ne. r_missing_data)then
            n_radarobs_lvl_fltrd = n_radarobs_lvl_fltrd + 1
          endif
          n_superob_tot = n_superob_tot + n_superob(i,j)
        enddo ! i
        enddo ! j

        if(n_radarobs_lvl_unfltrd .gt. 0)then
            write(6,*)'     Superob check ',n_radarobs_lvl_unfltrd
     1                                     ,n_superob_tot
        endif

        if(n_radarobs_lvl_unfltrd .ne. n_superob_tot)then
            write(6,*)
     1         ' NOTE: superob check is inconsistent - edge effects?'
            istatus = 0
            return
        endif

csms$ignore end
        istatus = 1
        return
        end

      subroutine open_dxx(idx_radar,i4time,lun_dxx,istatus)

      integer i_open(200)

      save i_open
      data i_open /200*0/

      character*31 ext

      lun_dxx = 60 + idx_radar

      if(i_open(idx_radar) .eq. 0)then
          if(idx_radar .le. 99)then
              write(ext,531)idx_radar 
 531          format('d',i2.2)
          else
              write(ext,532)idx_radar 
 532          format('d',i3.3)
          endif
          
          write(6,*)' Open dxx file for ',ext(1:4)
          call open_lapsprd_file(lun_dxx,i4time,ext,istatus)

          if(istatus .eq. 1)then
              i_open(idx_radar) = 1
          endif
      endif

      return
      end
