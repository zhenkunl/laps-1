cdis    Forecast Systems Laboratory
cdis    NOAA/OAR/ERL/FSL
cdis    325 Broadway
cdis    Boulder, CO     80303
cdis
cdis    Forecast Research Division
cdis    Local Analysis and Prediction Branch
cdis    LAPS
cdis
cdis    This software and its documentation are in the public domain and
cdis    are furnished "as is."  The United States government, its
cdis    instrumentalities, officers, employees, and agents make no
cdis    warranty, express or implied, as to the usefulness of the software
cdis    and documentation for any purpose.  They assume no responsibility
cdis    (1) for the use of the software and documentation; or (2) to provide
cdis     technical support to users.
cdis
cdis    Permission to use, copy, modify, and distribute this software is
cdis    hereby granted, provided that the entire disclaimer notice appears
cdis    in all copies.  All modifications to this software must be clearly
cdis    documented, and are solely the responsibility of the agent making
cdis    the modifications.  If significant modifications or enhancements
cdis    are made to this software, the FSL Software Policy Manager
cdis    (softwaremgr@fsl.noaa.gov) should be notified.
cdis
cdis
cdis
cdis
cdis
cdis
cdis
        subroutine insert_sao(i4time,cldcv,cf_modelfg,t_modelfg,cld_hts   ! I
     1          ,default_clear_cover,lat,lon,topo,t_sfc_k,wtcldcv         ! I
     1          ,name_array,l_perimeter,ista_snd,cvr_snd,cld_snd
     1          ,wt_snd,i_snd,j_snd,n_cld_snd,max_cld_snd
     1          ,ni,nj,nk                                                 ! I
     1          ,n_obs_b,lat_sta_ret,lon_sta_ret,c_stations
     1          ,wx,t,td
     1          ,elev
     1          ,istatus
     1          ,maxstns,IX_LOW,IX_HIGH,IY_LOW,IY_HIGH)

!       1995 Steve Albers                         Original Version
!       11-Nov-1995    Steve Albers     Ignore SAOs reporting 'X'
!       12-Nov-1995    Steve Albers     Max cloud cover = 1.0, not 1.01
!       10-Oct-1996    Steve Albers     Max cloud cover = 1.0, not 1.01
!                                           (Completed the change)
!       12-Nov-1996    Steve Albers     Improved logging and cleanup
!        6-Dec-1996    Steve Albers     Filter the obs string
!        1-Aug-1997    Ken Dritz        Added I_PERIMETER and maxstns as dummy
!                                       arguments
!        1-Aug-1997    Ken Dritz        Added maxstns, IX_LOW, IX_HIGH, IY_LOW,
!                                       and IY_HIGH as dummy arguments.
!        1-Aug-1997    Ken Dritz        Removed PARAMETER statements for
!                                       IX_LOW, IX_HIGH, IY_LOW, and IY_HIGH.
!        1-Aug-1997    Ken Dritz        Removed include of lapsparms.for
!        6-Aug-1997    Steve Albers     Removed equivalences.

        character*150 c150_filename,directory
        character*31 ext
        character*13 filename13

!       Arrays for reading in sao cloud data
        character*(*) c_stations(maxstns)
        character*5 c5_outstring

        real*4 lat_sta_ret(maxstns)
        real*4 lon_sta_ret(maxstns)

        logical l_sao_lso
        data l_sao_lso /.true./ ! Do things the new way?
        logical l_perimeter
        character*3 lso_ext
        data lso_ext /'lso'/

        logical l_dry, l_parse

!       Arrays for reading in the SAO data from the LSO files
        Real*4   elev(maxstns),t(maxstns),td(maxstns),dd(maxstns)
     1          ,ff(maxstns),ddg(maxstns)
        real*4   ffg(maxstns),pstn(maxstns),pmsl(maxstns),alt(maxstns)
     1                                          ,ht_base_ret(maxstns,5)
        real*4   ceil(maxstns),lowcld(maxstns),cover_a(maxstns)
     1          ,vis(maxstns),rad(maxstns)
c
        Integer*4   obstime(maxstns),n_cloud_layers_ret(maxstns)
     1                              ,idp3(maxstns)
c
        Character   infile*170,atime*24 
     1             ,obstype(maxstns)*6,atype(maxstns)*6
     1             ,wx(maxstns)*8
        character   store_emv(maxstns,5)*1,amt_ret(maxstns,5)*4

        character*8 c8_project

!       Arrays for inserting the cloud data into the LAPS grid
        real*4 cldcv(ni,nj,nk)
        real*4 cf_modelfg(ni,nj,nk)
        real*4 t_modelfg(ni,nj,nk)
        real*4 topo(ni,nj)
        real*4 t_sfc_k(ni,nj)
        real*4 wtcldcv(ni,nj,nk)
        real*4 cld_hts(nk)
        real*4 lat(ni,nj),lon(ni,nj)
        character*1 name_array(ni,nj)

!       Arrays for cloud soundings
        integer*4 ista_snd(max_cld_snd)
        real*4 cld_snd(max_cld_snd,nk)
        real*4 wt_snd(max_cld_snd,nk)
        real*4 cvr_snd(max_cld_snd)
        integer*4 i_snd(max_cld_snd)
        integer*4 j_snd(max_cld_snd)

        logical l_out_of_bounds

!       Initialize ista_snd
        do i = 1,max_cld_snd
            ista_snd(i) = 0
        enddo ! i

        i4time_database = (i4time / 3600) * 3600

!       This section calls a routine 'get_sao' which interfaces with the raw
!       FSL SAO data in order to create an intermediate cloud layer file (.SAO).
!       In the future, this task could be performed elsewhere within LAPS

!       Construct file name for LSO file
        ext = lso_ext
        call get_directory(ext,directory,len_dir) ! Returns directory
        c150_filename = directory(1:len_dir)
     1                            //filename13(i4time_database,lso_ext)

        n_wait_saos = 0   ! (0,2) THIS IS INPUTTED, 10 min per potential wait

10      write(6,*)' Calling SAO ingest routine'

        call cv_i4tim_asc_lp(i4time_database,atime,istatus)

!       Access SAO data from LSO files
        infile = c150_filename
        call read_surface_sa(infile,maxstns,atime,
     1   n_obs_g,n_obs_b,c_stations,obstype,atype,
     1   lat_sta_ret,lon_sta_ret,elev,wx,t,td,dd,ff,ddg,
     1   ffg,pstn,pmsl,alt,n_cloud_layers_ret,ceil,lowcld,cover_a,
     1   rad,idp3,store_emv,       
     1   amt_ret,ht_base_ret,vis,obstime,istatus)

        if(istatus .ne. 1)then
            write(6,*)' Bad status returned from reading SAO data'
            return
        endif

        write(6,*)' # of obs (grid/box) = ',n_obs_g,n_obs_b

        write(6,*)' Now we are looping to insert the stations'

        n_analyzed = 0

        call get_c8_project(c8_project,istatus)
        if(istatus .ne. 1)return

!       Loop through the stations
        do i=1,n_obs_b

          call filter_string(obstype(i))

          if(l_parse(c8_project,'AFGWC'))then
              atype(i)='U'//atype(i)(2:6)
          endif

!         Determine whether we want to analyze cloud layers from this station
          if(obstype(i)(1:4) .eq. 'MESO')goto125
          if(obstype(i)(1:4) .eq. 'CDOT')goto125

          write(6,*)

c place station at proper laps grid point
          call latlon_to_rlapsgrid(lat_sta_ret(i),lon_sta_ret(i)
     1                                  ,lat,lon,ni,nj,ri,rj,istatus)

          ilaps = nint(ri)
          jlaps = nint(rj)

          if(  ilaps .lt. IX_LOW .or. ilaps .gt. IX_HIGH
     1    .or. jlaps .lt. IY_LOW .or. jlaps .gt. IY_HIGH)then
              write(6,*)' Note: out of bounds ',c_stations(i)
              goto 125
          endif


          if(n_cloud_layers_ret(i) .eq. 0)then ! Kick out AMOS stations not
                                               ! reporting clouds this time
              write(6,*)' No cloud layers reported - '
     1          ,'CLR?/MSG?/AMOS? - goto end of loop '       
     1          ,c_stations(i),' ',obstype(i),' ',atype(i)
              goto 125
          endif

!         What is the height limit of the cloud observation? Is obstype valid?
          if(      obstype(i)(1:5) .eq. 'METAR'
     1        .or. obstype(i)(1:5) .eq. 'TESTM' 
     1        .or. obstype(i)(1:5) .eq. 'SPECI' 
     1        .or. obstype(i)(1:5) .eq. 'TESTS' 
     1        .or. obstype(i)(1:5) .eq. 'SYNOP' )then  ! New LSO file format

              if(  atype(i)(1:1) .eq. 'A'
     1        .or. atype(i)(1:1) .eq. 'U' )then      ! use 12000' limit

                  if(atype(i)(1:1) .eq. 'A')then     ! Automated station
                      i_auto = 1                       
                  else                                 ! Indeterminate
                      i_auto = 0
                  endif

                  ht_defined = elev(i) + 12000./3.281

              else                                     ! Non-Automated
                  i_auto = -1
                  ht_defined = 99999.

              endif ! Automated station

          else                                         ! Non-sanctioned cld type
              write(6,*)' WARNING, questionable obstype having '
     1                 ,'cloud layers - reject: ',obstype(i)
     1                 ,' ',c_stations(i)

              goto 125                                 ! Loop to next station

!             if(obstype(i)(5:5) .ne. ' ' .and.
!    1           obstype(i)(4:7) .ne. 'AMOS')then      ! Automated Station 
!                                                      ! (12000' limit)
!                 ht_defined = elev(i) + 12000./3.281
!             else                                     ! Non-Automated
!                 ht_defined = 99999.
!             endif

          endif ! Sanctioned obstype for reporting cloud layers

          n_analyzed = n_analyzed + 1
          n_cld_snd = n_cld_snd + 1
          ista_snd(n_cld_snd) = i

          c5_outstring = c_stations(i)

          write(6,1,err=110)c5_outstring,lat_sta_ret(i)
     1         ,lon_sta_ret(i),n_cloud_layers_ret(i)
     1         ,ilaps,jlaps,obstype(i),atype(i),ht_defined ! ,obstime(i)
1         format(1x,a5,2f8.2,i3,2i4,1x,a8,1x,a6,f8.0,i5)

110       do l = 1,n_cloud_layers_ret(i)
              write(6,2,err=3)amt_ret(i,l),ht_base_ret(i,l)
2             format(1x,a4,f8.0)
3             continue
          enddo ! l

          if(  ilaps .lt. 1 .or. ilaps .gt. ni
     1    .or. jlaps .lt. 1 .or. jlaps .gt. nj)then
              l_out_of_bounds = .true.
          else
              l_out_of_bounds = .false.
              name_array(ilaps,jlaps)=c_stations(i)(1:1)
          endif

          cvr_snd(n_cld_snd) = 0.

!         Initialize summation layer calculation for this ob
          call get_layer_cover(0.,cover,istatus)

          do l=1,n_cloud_layers_ret(i)

              cover = 0.

              ht_base=ht_base_ret(i,l)

              if(ht_base .gt. ht_defined+1.)then

                if( (.not. l_parse(amt_ret(i,l),'CLR') ) .AND.
     1              (.not. l_parse(amt_ret(i,l),'SKC') )      )then ! Clouds

                  if(.true.)then ! Allow a redefinition of ht_defined
                    write(6,*)' WARNING, inconsistent SAO data,'
     1              //' cloud base is'       
     1              //' reported to be too high for this sensor type'       

                    write(6,*)ht_base,ht_defined,' ',obstype(i)
     1                                          ,' ',atype(i)

                    write(6,*)' Please check cloud layer heights in the'       
     1              //' LSO file to see that they are compatable with'     
     1              //' the types of sensors used.'

                    write(6,*)' Assume human augmented ob, raising '
     1                       ,'ht_defined'
                    ht_defined = ht_base

                  else ! Flag QC error if ht_defined is exceeded by cloud layer
                    write(6,*)
     1                ' Error, inconsistent SAO data, cloud base is'      
     1              //' reported to be too high for this sensor type'       

                    write(6,*)ht_base,ht_defined,' ',obstype(i)
     1                                          ,' ',atype(i)
                    write(6,*)
     1                ' Please check cloud layer heights in the LSO'
     1              //' file to see that they are compatable with the'       
     1              //' types of sensors used.'

                    istatus = 0
                    return

                  endif

                else ! CLR
                  write(6,*)' WARNING, CLR sky cloud base does not'
     1            //' reflect this sensor type'
                  write(6,*)ht_base,ht_defined,' ',obstype(i)
     1                                        ,' ',atype(i)

                endif ! Clouds

              endif ! ht_base > ht_defined

C CLOUDS ARE NOW IN MSL
!             Fill in clear for entire column for METAR or up to ht_base for 
!             AWOS or up to ht_base for VV.
              if(l_parse(amt_ret(i,l),'CLR')    .or.
     1           l_parse(amt_ret(i,l),'SKC')    .or.
     1           l_parse(amt_ret(i,l),'VV')         )then

                  cover=default_clear_cover
                  if(istatus .ne. 1)goto125 ! go to next station

                  do k=1,nk
                      if(     cld_hts(k).le.ht_base
     1                  .and. cld_hts(k).le.ht_defined      )then
                          call spread2(
     1                           cld_snd,wt_snd,i_snd,j_snd,n_cld_snd
     1                          ,max_cld_snd,nk,ilaps,jlaps,k,cover,1.)
                      endif
                  enddo

                  write(6,*)' Filled in ',amt_ret(i,l),' from bottom'
     1                     ,' of domain up to '
     1                     ,nint(min(ht_base,ht_defined)),' meters'     

                  if(.true.)then                               ! SKC is now used
                      if(l_parse(amt_ret(i,l),'CLR') .and. 
     1                                            i_auto .eq. -1)then       
                          write(6,*)' WARNING: CLR reported for '
     1                             ,'non-automated station'

                      elseif(l_parse(amt_ret(i,l),'SKC') .and. ! Converse
     1                                            i_auto .eq. +1)then
                          write(6,*)' WARNING: SKC reported for '
     1                             ,'automated station'

                      endif ! CLR/SKC test

                  endif ! .true.

                  if(n_cloud_layers_ret(i) .gt. 1)then
                      write(6,*)' WARNING: CLR/SKC/VV in ob that'
     1                         ,' has more than one layer'
                  endif
!                 go to 125 ! Loop to next station

              endif


!             If this station has obscured (but not thin obscured),
!             leave the entire cloud sounding to say "missing data".
!             Thin obscured simply drops through as an ignored cloud layer
              do nc = 1,4 ! Parse the cloud amount string
                  if(amt_ret(i,l)(nc:nc) .eq. 'X')then ! Obscured or Thin Obsc
                      if(nc .eq. 1)then
                          write(6,*)' Obscured sky detected'
                          goto 125
                      else ! search for "thin" designation
                          if(amt_ret(i,l)(nc-1:nc-1) .ne. '-')then
                              write(6,*)' Obscured sky detected'
                              goto 125
                          endif
                      endif
                  endif
              enddo

              if(l_parse(amt_ret(i,l),'FEW'))then
                  summation_cover=.125
                  call get_layer_cover(summation_cover,cover,istatus)      
                  if(istatus .ne. 1)goto125 ! go to next station

                  ht_top=ht_base+1000.
                  do k=1,nk

                      if(cld_hts(k).ge.ht_base .and. 
     1                   cld_hts(k).le.ht_top        )then

!                         Search for model d(cldcv)/dz within cloud layer
                          call modify_sounding(
     1                         cld_snd,n_cld_snd,max_cld_snd
     1                        ,cf_modelfg,t_modelfg,topo,t_sfc_k
     1                        ,ilaps,jlaps,k,ni,nj,nk,cld_hts
     1                        ,ht_base,ht_top,0,l_dry)

                          if(.not. l_dry)then
                              call spread2(
     1                           cld_snd,wt_snd,i_snd,j_snd,n_cld_snd
     1                          ,max_cld_snd,nk,ilaps,jlaps,k,cover,1.)
                          endif

                      else
!                         Initialize the modify sounding routine
                          call modify_sounding(
     1                         cld_snd,n_cld_snd,max_cld_snd
     1                        ,cf_modelfg,t_modelfg,topo,t_sfc_k
     1                        ,ilaps,jlaps,k,ni,nj,nk,cld_hts
     1                        ,ht_base,ht_top,1,l_dry)

                      endif
                  enddo
              endif

              if(l_parse(amt_ret(i,l),'SCT'))then
                  summation_cover=.44
                  call get_layer_cover(summation_cover,cover,istatus)      
                  if(istatus .ne. 1)goto125 ! go to next station

                  ht_top=ht_base+1000.
                  do k=1,nk

                      if(cld_hts(k).ge.ht_base .and. 
     1                   cld_hts(k).le.ht_top        )then

!                         Search for model d(cldcv)/dz within cloud layer
                          call modify_sounding(
     1                         cld_snd,n_cld_snd,max_cld_snd
     1                        ,cf_modelfg,t_modelfg,topo,t_sfc_k
     1                        ,ilaps,jlaps,k,ni,nj,nk,cld_hts
     1                        ,ht_base,ht_top,0,l_dry)

                          if(.not. l_dry)then
                              call spread2(
     1                           cld_snd,wt_snd,i_snd,j_snd,n_cld_snd
     1                          ,max_cld_snd,nk,ilaps,jlaps,k,cover,1.)
                          endif

                      else
!                         Initialize the modify sounding routine
                          call modify_sounding(
     1                         cld_snd,n_cld_snd,max_cld_snd
     1                        ,cf_modelfg,t_modelfg,topo,t_sfc_k
     1                        ,ilaps,jlaps,k,ni,nj,nk,cld_hts
     1                        ,ht_base,ht_top,1,l_dry)

                      endif
                  enddo
              endif

              if(l_parse(amt_ret(i,l),'-BKN'))then
                  summation_cover=.4 ! .5
                  call get_layer_cover(summation_cover,cover,istatus)      
                  if(istatus .ne. 1)goto125 ! go to next station

                  ht_top=ht_base+1000.
                  do k=1,nk

                      if(cld_hts(k).ge.ht_base .and. 
     1                   cld_hts(k).le.ht_top        )then

!                         Search for model d(cldcv)/dz within cloud layer
                          call modify_sounding(
     1                         cld_snd,n_cld_snd,max_cld_snd
     1                        ,cf_modelfg,t_modelfg,topo,t_sfc_k
     1                        ,ilaps,jlaps,k,ni,nj,nk,cld_hts
     1                        ,ht_base,ht_top,0,l_dry)

                          if(.not. l_dry)then
                              call spread2(
     1                           cld_snd,wt_snd,i_snd,j_snd,n_cld_snd
     1                          ,max_cld_snd,nk,ilaps,jlaps,k,cover,1.)
                          endif

                      else
!                         Initialize the modify sounding routine
                          call modify_sounding(
     1                         cld_snd,n_cld_snd,max_cld_snd
     1                        ,cf_modelfg,t_modelfg,topo,t_sfc_k
     1                        ,ilaps,jlaps,k,ni,nj,nk,cld_hts
     1                        ,ht_base,ht_top,1,l_dry)

                      endif
                  enddo
              ENDIF

              if(l_parse(amt_ret(i,l),'BKN'))then
                  summation_cover=.75
                  call get_layer_cover(summation_cover,cover,istatus)      
                  if(istatus .ne. 1)goto125 ! go to next station

                  ht_top=ht_base+cld_thk(ht_base) ! 1500.

                  do k=1,nk

                      if(cld_hts(k).ge.ht_base .and. 
     1                   cld_hts(k).le.ht_top        )then

!                         Search for model d(cldcv)/dz within cloud layer
                          call modify_sounding(
     1                         cld_snd,n_cld_snd,max_cld_snd
     1                        ,cf_modelfg,t_modelfg,topo,t_sfc_k
     1                        ,ilaps,jlaps,k,ni,nj,nk,cld_hts
     1                        ,ht_base,ht_top,0,l_dry)

                          if(.not. l_dry)then
                              call spread2(
     1                           cld_snd,wt_snd,i_snd,j_snd,n_cld_snd
     1                          ,max_cld_snd,nk,ilaps,jlaps,k,cover,1.)
                          endif

                      else
!                         Initialize the modify sounding routine
                          call modify_sounding(
     1                         cld_snd,n_cld_snd,max_cld_snd
     1                        ,cf_modelfg,t_modelfg,topo,t_sfc_k
     1                        ,ilaps,jlaps,k,ni,nj,nk,cld_hts
     1                        ,ht_base,ht_top,1,l_dry)

                      endif
                  enddo
              endif

              if(l_parse(amt_ret(i,l),'-OVC'))then
                  summation_cover=.6 ! .9
                  call get_layer_cover(summation_cover,cover,istatus)      
                  if(istatus .ne. 1)goto125 ! go to next station

                  ht_top=ht_base+1000.
                  do k=1,nk

                      if(cld_hts(k).ge.ht_base .and. 
     1                   cld_hts(k).le.ht_top        )then

!                         Search for model d(cldcv)/dz within cloud layer
                          call modify_sounding(
     1                         cld_snd,n_cld_snd,max_cld_snd
     1                        ,cf_modelfg,t_modelfg,topo,t_sfc_k
     1                        ,ilaps,jlaps,k,ni,nj,nk,cld_hts
     1                        ,ht_base,ht_top,0,l_dry)

                          if(.not. l_dry)then
                              call spread2(
     1                           cld_snd,wt_snd,i_snd,j_snd,n_cld_snd
     1                          ,max_cld_snd,nk,ilaps,jlaps,k,cover,1.)
                          endif

                      else
!                         Initialize the modify sounding routine
                          call modify_sounding(
     1                         cld_snd,n_cld_snd,max_cld_snd
     1                        ,cf_modelfg,t_modelfg,topo,t_sfc_k
     1                        ,ilaps,jlaps,k,ni,nj,nk,cld_hts
     1                        ,ht_base,ht_top,1,l_dry)

                      endif
                  enddo
              ENDIF

              if(l_parse(amt_ret(i,l),'OVC'))then
                  summation_cover=1.00 
                  call get_layer_cover(summation_cover,cover,istatus)      
                  if(istatus .ne. 1)goto125 ! go to next station

                  ht_top=ht_base+cld_thk(ht_base) ! 1500.

                  do k=1,nk
                      if(cld_hts(k).ge.ht_base .and. 
     1                   cld_hts(k).le.ht_top        )then

!                         Search for model d(cldcv)/dz within cloud layer
                          call modify_sounding(
     1                         cld_snd,n_cld_snd,max_cld_snd
     1                        ,cf_modelfg,t_modelfg,topo,t_sfc_k
     1                        ,ilaps,jlaps,k,ni,nj,nk,cld_hts
     1                        ,ht_base,ht_top,0,l_dry)

                          if(.not. l_dry)then
                              call spread2(
     1                           cld_snd,wt_snd,i_snd,j_snd,n_cld_snd
     1                          ,max_cld_snd,nk,ilaps,jlaps,k,cover,1.)
                          endif

                      else
!                         Initialize the modify sounding routine
                          call modify_sounding(
     1                         cld_snd,n_cld_snd,max_cld_snd
     1                        ,cf_modelfg,t_modelfg,topo,t_sfc_k
     1                        ,ilaps,jlaps,k,ni,nj,nk,cld_hts
     1                        ,ht_base,ht_top,1,l_dry)

                      endif
                  enddo
              endif


!             We should not hit this anymore
              if(l_parse(amt_ret(i,l),'X'))then
                  write(6,*)' Error: insertsao - stop X'
                  if(.true.)stop

!                 summation_cover=1.00 
!                 call get_layer_cover(summation_cover,cover,istatus)      
!                 if(istatus .ne. 1)goto125 ! go to next station

!                 ht_top=ht_base+cld_thk(ht_base) ! 1500.

!                 do k=1,nk
!                     if(cld_hts(k).ge.ht_base .and. 
!    1                   cld_hts(k).le.ht_top        )then

!                         Search for model d(cldcv)/dz within cloud layer
!                         call modify_sounding(
!    1                         cld_snd,n_cld_snd,max_cld_snd
!    1                        ,cf_modelfg,t_modelfg,topo,t_sfc_k
!    1                        ,ilaps,jlaps,k,ni,nj,nk,cld_hts
!    1                        ,ht_base,ht_top,0,l_dry)

!                         if(.not. l_dry)then
!                             call spread2(
!    1                           cld_snd,wt_snd,i_snd,j_snd,n_cld_snd
!    1                          ,max_cld_snd,nk,ilaps,jlaps,k,cover,1.)
!                         endif

!                     else
!                         Initialize the modify sounding routine
!                         call modify_sounding(
!    1                         cld_snd,n_cld_snd,max_cld_snd
!    1                        ,cf_modelfg,t_modelfg,topo,t_sfc_k
!    1                        ,ilaps,jlaps,k,ni,nj,nk,cld_hts
!    1                        ,ht_base,ht_top,1,l_dry)

!                     endif
!                 enddo
              endif ! amt_ret

!             Calculate summation cover assuming obs are in layer cover
!             cvr_snd(n_cld_snd) = 1. - ((1. - cvr_snd(n_cld_snd)) 
!    1                           * cover)

!             Obtain summation cover directly from obs
              cvr_snd(n_cld_snd) = summation_cover

        enddo ! l (Cloud layer)


!       Locate the highest ceiling
        k_ceil = nk
        if(l_perimeter)then
            do k=nk,1,-1
                if(wt_snd(n_cld_snd,k) .eq. 1.00 .and.
     1           cld_snd(n_cld_snd,k) .gt. 0.5          )then
                    k_ceil = k
                    goto 1001
                endif
            enddo
        else
            do k=nk,1,-1
                if(wtcldcv(ilaps,jlaps,k) .eq. 1.00 .and.
     1           cldcv(ilaps,jlaps,k) .gt. 0.5          )then
                    k_ceil = k
                    goto 1001
                endif
            enddo
        endif


!       Fill in other clear layers outside of clouds, below the ceiling,
!                        and within defined height range of sensor.
1001    cover = default_clear_cover

        ht_fill = min(ht_defined,cld_hts(k_ceil))

        write(6,*)' K_ceil/ht_ceil/ht_defined/ht_fill = ',k_ceil
     1           ,nint(cld_hts(k_ceil)),nint(ht_defined),nint(ht_fill)

        if(l_perimeter)then
          do k=1,k_ceil
            if(     wt_snd(n_cld_snd,k) .ne.  1.00
     1        .and. cld_hts(k)          .le.  ht_defined          )then
                call spread2(cld_snd,wt_snd,i_snd,j_snd,n_cld_snd
     1                          ,max_cld_snd,nk,ilaps,jlaps,k,cover,1.)
            endif
          enddo
        else
          do k=1,k_ceil
            if(     wtcldcv(ilaps,jlaps,k) .ne.  1.00
     1          .and. cld_hts(k)           .le.  ht_defined       )then
                call spread2(cld_snd,wt_snd,i_snd,j_snd,n_cld_snd
     1                          ,max_cld_snd,nk,ilaps,jlaps,k,cover,1.)
            endif
          enddo
        endif

125     continue
        enddo ! i

        write(6,*)
        write(6,*)' Num stations analyzed/cloud soundings = '
     1                          ,n_analyzed,n_cld_snd

999     continue

        istatus = 1

        return
        end

        subroutine modify_sounding(cld_snd,n_cld_snd,max_cld_snd
     1          ,cf_modelfg,t_modelfg,topo,t_sfc_k
     1          ,i_in,j_in,k,ni,nj,nk,cld_hts
     1          ,ht_base,ht_top,init,l_dry)

        real*4 cld_snd(max_cld_snd,nk)
        real*4 cf_modelfg(ni,nj,nk)
        real*4 t_modelfg(ni,nj,nk)
        real*4 topo(ni,nj)
        real*4 t_sfc_k(ni,nj)
        real*4 cld_hts(nk)

        logical l_wait_for_base,l_dry,l_cf,l_inversion
        save l_wait_for_base,cf_model_base,t_model_base,l_inversion,t_su
     1bcloud

        l_dry = .false.
        l_cf = .false.

!       Find LAPS grid point nearest the SAO if it is out of bounds
        i = max(min(i_in,ni),1)
        j = max(min(j_in,nj),1)

        if(init .eq. 1)then ! (below base )
                            ! reset to wait for the beginning of the layer
            l_wait_for_base = .true.
            l_inversion = .false.
            t_subcloud = t_modelfg(i,j,k)
            return

        else ! init = 0 (inside cloud layer)
            if(l_wait_for_base)then ! Set reference (just within cloud base)
                l_wait_for_base = .false.
                cf_model_base = cf_modelfg(i,j,k)
                t_model_base = t_modelfg(i,j,k)

                write(6,21)t_subcloud
21              format(' modify_sounding.....          '
     1         ,'cf     t    dlt th r i   i   j kcld h-msl'
     1         /' model    T    subcloud   = ',7x,f7.2)

!               write(6,1)cf_model_base,t_modelfg(i,j,k),l_cf
!       1                               ,l_inversion,i,j,k,nint(cld_hts(k))
1               format(' model RH/T at cloud base = ',2f7.2,2l2,3i4,i6)

            endif

            if(.true.)then ! determine if cloud should be cleared out

!               Set inversion strength flag
                t_dry_adiabat = t_sfc_k(i,j)
     1                     -.0098 * (cld_hts(k) - topo(i,j))
                t_inversion_strength = t_modelfg(i,j,k) - t_dry_adiabat

                if(
     1     (    (t_modelfg(i,j,k) .gt. t_model_base)
     1                                .OR.
     1            (t_modelfg(i,j,k) .gt. t_subcloud .and. k .ge. 2) )
     1                         .AND.
     1                (t_modelfg(i,j,k) .gt. 283.15)       ! temp check
     1                         .AND.
     1                (t_inversion_strength .gt. 4.)       ! delta theta chk
     1                                              )then  ! inversion search
                    l_inversion = .true.
                    write(6,2)cf_modelfg(i,j,k),t_modelfg(i,j,k)
     1               ,t_inversion_strength,l_cf,l_inversion
     1                       ,i,j,k,nint(cld_hts(k))
2                   format(' Inversion detected       = '
     1                                       ,3f7.2,2l2,3i4,i6)
                elseif(cf_modelfg(i,j,k) .lt. cf_model_base - 0.3   ! cf search
     1            .and.    cld_hts(k) - ht_base .ge. 500.)then
                    l_cf = .true.
                    write(6,3)cf_modelfg(i,j,k),t_modelfg(i,j,k)
     1               ,t_inversion_strength,l_cf,l_inversion
     1                       ,i,j,k,nint(cld_hts(k))
3                   format(' Dry layer detected       = '
     1                                       ,3f7.2,2l2,3i4,i6)
                else                                        ! not newly flagged
                    write(6,4)cf_modelfg(i,j,k),t_modelfg(i,j,k)
     1               ,t_inversion_strength,l_cf,l_inversion
     1                       ,i,j,k,nint(cld_hts(k))
4                   format(' model RH/T in cloud      = ',3f7.2,2l2,3i4,
     1i6)
                endif

                if(l_cf .or. l_inversion)then
!               if(l_cf)then
                    l_dry = .true.
                endif

            endif
        endif

        return
        end

        function cld_thk(ht_base)

        if(ht_base .gt. 7000.)then
            cld_thk = 1500.
        else
            cld_thk = 1000.
        endif

        return
        end


        subroutine get_layer_cover(summation_cover,layer_cover,istatus)        
!                                         I             O         O

        real layer_cover

        save summation_cover_last

!       Null the changes for testing
!       layer_cover = summation_cover 
!       istatus = 1
!       return

        if(summation_cover .eq. 0.)then ! Initializing a new cloud ob
            goto900
        endif

        if(summation_cover_last .ge. 1.)then
            write(6,*)' ob ERROR, previous summation cover already OVC'       
            write(6,*)summation_cover_last
            istatus = 0
            return
        endif

        layer_cover = (summation_cover - summation_cover_last)
     1              / (1. - summation_cover_last)

        if(layer_cover .le. 0.)then
            if(layer_cover .lt. 0.)then
                write(6,*)' WARNING: layer_cover < 0, decrease '
     1                   ,'observed in summation cover: '
     1                   ,summation_cover_last,summation_cover
            endif

            layer_cover = .125
            write(6,*)' Setting layer_cover to minimum value of '
     1               ,layer_cover 

        endif

        write(6,1)summation_cover,layer_cover
 1      format(' get_layer_cover: summation/layer ',2f8.3)

 900    summation_cover_last = summation_cover

        istatus = 1
        return
        end

        function l_parse(string1,string2)

!       Determine whether string1 contains string2 as a subset

        logical l_parse

        character*(*) string1,string2

!       integer slen1,slen2

        len1 = len(string1)
        len2 = len(string2)

!       call s_len(string1,slen1)
!       call s_len(string2,slen2)

        l_parse = .false.

        if(len2 .gt. len1)return

        i_offset_max = len1-len2

        do i = 0,i_offset_max
            if(string1(i+1:i+len2) .eq. string2(1:len2))then
                l_parse = .true.
            endif ! match is found
        enddo ! i             

        return
        end        
