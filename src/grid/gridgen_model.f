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

	Program gridgen_model
C**********************************************************************
c Portions of the following code were taken from the RAMS software and 
c   were used by permission of the *ASTER Division/Mission Research 
c   Corporation. 
C**********************************************************************
C*	This program will be used to map model grids based on the RAMS*
C*  version 2b which uses polar stereographic projections. Other      *
C*  projections have since been added.                                *
c*                                                                    *
C*********************************************************************
        integer n_staggers
        parameter (n_staggers = 3)
        integer NX_L,NY_L

        write(6,*)
        write(6,*)' gridgen_model: start'

	call get_grid_dim_xy(NX_L,NY_L,istatus)
	if (istatus .ne. 1) then
           write (6,*) 'Error getting horizontal domain dimensions'
	   goto999
	endif

        call Gridmap_sub(NX_L,NY_L,n_staggers,istatus)

 999	write(6,*)' gridgen_model finish: istatus = ',istatus
        write(6,*)

        end
       
        subroutine Gridmap_sub(nnxp,nnyp,n_staggers,istatus)

        include 'trigd.inc'

        logical exist,new_DEM

        integer nnxp,nnyp,mode
        integer ngrids
        integer n_staggers

	Real mdlat,mdlon
	Real xmn(nnxp),ymn(nnyp)
	Real xtn(nnxp),ytn(nnyp)
	Real lat(nnxp,nnyp),lon(nnxp,nnyp)
        Real sw(2),nw(2),ne(2),se(2)               ! ,pla,plo
        real  nboundary
        real  adum(nnxp,nnyp)
        real  topt_30(nnxp,nnyp)
        real  topt_30_s(nnxp,nnyp)
        real  topt_10(nnxp,nnyp)
        real  topt_10_s(nnxp,nnyp)
        real  topt_10_ln(nnxp,nnyp)
        real  topt_10_lt(nnxp,nnyp)
        real  topt_30_ln(nnxp,nnyp)
        real  topt_30_lt(nnxp,nnyp)
        real  topt_out(nnxp,nnyp)
        real  topt_out_s(nnxp,nnyp)
        real  topt_out_ln(nnxp,nnyp)
        real  topt_out_lt(nnxp,nnyp)
        real  topt_pctlfn(nnxp,nnyp)
        real  soil(nnxp,nnyp)
        real  static_albedo(nnxp,nnyp)

        real lats(nnxp,nnyp,n_staggers)
        real lons(nnxp,nnyp,n_staggers)

c********************************************************************

c       Declarations for wrt_laps_static
c       integer*4    ni,nj
c       parameter (ni = NX_L)
c       parameter (nj = NY_L)
c
c  either 7 (nest7gird) or 20 (wrfsi) used here but 18 needed in put_laps_static
c
        integer*4    nf
        parameter (nf = 21)
        
        character*3   var(nf)
        character*125 comment(nf)
        character*131 model

        character*200 path_to_topt30s
        character*200 path_to_topt10m
        character*200 path_to_pctl10m
        character*200 path_to_soil2m

        character*255 filename
        character*200 c_dataroot
        character*200 cdl_dir
        character*180 static_dir 
        character*10  c10_grid_fname 
        character*6   c6_maproj
        integer len,lf,lfn
        real*4 coriolis_parms(nnxp,nnyp,2)
        real*4 projrot_grid(nnxp,nnyp,2)
        real*4 r_map_factors(nnxp,nnyp,n_staggers)
        real*4 data(nnxp,nnyp,nf)
c       equivalence(data(1,1,1),lat)
c       equivalence(data(1,1,2),lon)
c       equivalence(data(1,1,3),topt_out)
c       equivalence(data(1,1,4),topt_pctlfn)

C*********************************************************************

        call find_domain_name(c_dataroot,c10_grid_fname,istatus)
        if(istatus .ne. 1)then
            write(6,*) 'Error getting path_to_topt10m'
            return
        endif
        call s_len(c10_grid_fname,lf)

        model = 'MODEL 4 delta x smoothed filter\0'

        icount_10 = 0
        icount_30 = 0
        icount_ramp = 0

        call get_directory('static',static_dir,lens)

c ipltgrid is 1 if you want to plot the grid itself
c iplttopo is 1 if you want to plot the topography
c   the 30s topo covers the continental US
cc        itoptfn_30=static_dir(1:len)//'model/topo_30s/U'
c   the 10m topo covers the world
cc        itoptfn_10=static_dir(1:len)//'model/topo_10m/H'
c   the 10m pctl covers the world
cc        ipctlfn=static_dir(1:len)// 'model/land_10m/L'

        call get_path_to_topo_10m(path_to_topt10m,istatus)
        if(istatus .ne. 1)then
            write(6,*) 'Error getting path_to_topt10m'
            return
        endif

        call get_path_to_topo_30s(path_to_topt30s,istatus)
        if(istatus .ne. 1)then
            write(6,*) 'Error getting path_to_topt30s'
            return
        endif

        call get_path_to_pctl_10m(path_to_pctl10m,istatus)
        if(istatus .ne. 1)then
            write(6,*) 'Error getting path_to_pctl10m'
            return
        endif

        call get_path_to_soil_2m(path_to_soil2m,istatus)
        if(istatus .ne. 1)then
            write(6,*) 'Error getting path_to_soil2m'
            return
        endif

        call s_len(path_to_topt30s,len)
	path_to_topt30s(len+1:len+2)='/U'

        call s_len(path_to_topt10m,len)
	path_to_topt10m(len+1:len+2)='/H'

        call s_len(path_to_pctl10m,len)
	path_to_pctl10m(len+1:len+2)='/L'

        call s_len(path_to_soil2m,len)
	path_to_soil2m(len+1:len+2)='/O'

        call get_topo_parms(silavwt_parm,toptwvl_parm,istatus)
	if (istatus .ne. 1) then
           write (6,*) 'Error getting terrain smoothing parms'
	   return
	endif

        call get_r_missing_data(r_missing_data,istatus)
	if (istatus .ne. 1) then
           write (6,*) 'Error getting r_missing_data'
	   return
	endif

!       Silhouette weighting parameter
        silavwt=silavwt_parm

!       Terrain wavelength for filtering
        toptwvl=toptwvl_parm

        ipltgrid=1
        iplttopo=1

C*********************************************************************
        call get_gridnl(mode) 

c calculate delta x and delta y using grid and map projection parameters
        call get_standard_latitudes(std_lat,std_lat2,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error calling laps routine'
            return
        endif
        write(6,*)' standard_lats = ',std_lat,std_lat2

        call get_grid_spacing(grid_spacing_m,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error calling laps routine'
            return
        endif
        write(6,*)' grid_spacing = ',grid_spacing_m

        call get_grid_center(mdlat,mdlon,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error calling laps routine'
            return
        endif
        write(6,*)' grid_center = ',mdlat,mdlon

        call get_c6_maproj(c6_maproj,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error calling laps routine'
            return
        endif
        write(6,*)' c6_maproj = ',c6_maproj

        call get_standard_longitude(std_lon,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error calling laps routine'
            return
        endif
        write(6,*)' std_lon = ',std_lon

        call get_earth_radius(erad,istatus)
        if(istatus .ne. 1)then
            write(6,*)' Error calling laps routine'
            return
        endif
        write(6,*)' Earth Radius = ',erad

        if(c6_maproj .eq. 'plrstr')then
            call get_ps_parms(std_lat,std_lat2,grid_spacing_m,phi0
     1                       ,grid_spacing_proj_m)

            deltax = grid_spacing_proj_m

            if(phi0 .eq. 90.)then
                write(6,*)' Projection is tangent to earths surface'
            else
                write(6,*)' Projection is secant to earths surface'
            endif

            if(std_lat2 .eq. +90.)then
                write(6,*)' Note, grid spacing will equal '
     1                    ,grid_spacing_m,' at a latitude of ',std_lat
!               write(6,*)' deltax, deltay ',deltax,deltay
!    1                   ,' at the north pole'

            elseif(std_lat2 .eq. -90.)then
                write(6,*)' Note, grid spacing will equal '
     1                    ,grid_spacing_m,' at a latitude of ',std_lat       
!               write(6,*)' deltax, deltay ',deltax,deltay
!    1                   ,' at the south pole'

            else ! abs(std_lat2) .ne. 90. (local stereographic)
                write(6,*)' The standard latitude ',std_lat,' is'
     1                   ,' relative to where the pole'
                write(6,*)' of the map projection is: lat/lon '
     1                   ,std_lat2,std_lon
!               write(6,*)' deltax, deltay ',deltax,deltay
!    1                   ,' at the projection pole'
                if(std_lat .ne. +90.)then
                    write(6,*)' Note: std_lat should usually be set'
     1                       ,' to +90. for local stereographic'
                endif

            endif

        else ! c6_maproj .ne. 'plrstr'
            deltax = grid_spacing_m

        endif ! c6_maproj .eq. 'plrstr'

        deltay = deltax
        write(6,*)' deltax, deltay (in projection plane) '
     1             ,deltax,deltay
 
c*********************************************************************
c in arrays lats/lons, the first stagger is actually not staggered
c but is the usual lat/lon values at non-staggered grid points.

        call compute_latlon(nnxp,nnyp,n_staggers
     + ,deltax,xtn,ytn,lats,lons,istatus)
        if(istatus.ne.1)then
           print*,'Error returned: compute_stagger_ll'
           return
        endif

        do j=1,nnyp
        do i=1,nnxp
           lat(i,j)=lats(i,j,1)
           lon(i,j)=lons(i,j,1)
        enddo
        enddo

C*****************************************************************

        write(6,*)
        write(6,*)'Corner points...'
        write(6,701,err=702)1,1,      lat(1,1),      lon(1,1)
        write(6,701,err=702)nnxp,1,   lat(nnxp,1),   lon(nnxp,1)   
        write(6,701,err=702)1,nnyp,   lat(1,nnyp),   lon(1,nnyp)   
        write(6,701,err=702)nnxp,nnyp,lat(nnxp,nnyp),lon(nnxp,nnyp)   
 701    format(' lat/lon at ',i5,',',i5,' =',2f12.5)
 702    continue

        call check_domain(lat,lon,nnxp,nnyp,grid_spacing_m,1
     + ,istat_chk)  
        if(istat_chk.ne.1)then
           print*,'Error returned from check_domain'
           istatus = istat_chk
           return
        endif

! We will end at this step given the showgrid or max/min lat lon
! options.
        if(mode.eq.2) then
	   call showgrid(lat,lon,nnxp,nnyp,grid_spacing_m,
     1	             c6_maproj,std_lat,std_lat2,std_lon,mdlat,mdlon)
           return

        elseif(mode.eq.3)then
           print*,'get perimeter of grid'
           call get_domain_perimeter_grid(nnxp,nnyp,c10_grid_fname
     1                  ,lat,lon
     1                  ,1.0,rnorth,south,east,west,istatus)
           print*,'static dir = ',static_dir(1:lens)
           open(10,file=static_dir(1:lens)//'/llbounds.dat'
     +         ,status='unknown')

           print*,'write llbounds.dat'
           write(10,*)rnorth,south,east,west
           close(10)
	   return
	endif

        write(6,*)'deltax = ',deltax

        write(6,*)'check_domain:status = ',istat_chk

c
C*****************************************************************
c calculate topography
c
       if(iplttopo.eq.1)then

           if(.false.)then
               write(6,*)
               write(6,*)' Processing 2m soil type data....'
               CALL GEODAT(nnxp,nnyp,erad,90.,std_lon,xtn,ytn
     +  ,deltax,deltay,soil,adum,adum,adum,PATH_TO_SOIL2M,1.,0.       
     +  ,new_DEM,istatus)

               if(istatus .ne. 1)then
                   write(6,*)' Warning: '
     1                      ,'File(s) missing for 2m soil type data'       
                   write(6,*)' Static file not created.......ERROR'
                   return
               endif

           else
               call constant(soil,r_missing_data,nnxp,nnyp)

           endif ! .false.

           write(6,*)
           write(6,*)' Processing 30s topo data....'
           CALL GEODAT(nnxp,nnyp,erad,90.,std_lon,xtn,ytn
     +,deltax,deltay,TOPT_30,TOPT_30_S,TOPT_30_LN,TOPT_30_LT
     + ,PATH_TO_TOPT30S,TOPTWVL,SILAVWT,new_DEM,istatus)

           if (.not.new_DEM) then
             write(6,*)
             write(6,*)' Processing 10m topo data....'
             CALL GEODAT(nnxp,nnyp,erad,90.,std_lon,xtn,ytn
     +,deltax,deltay,TOPT_10,TOPT_10_S,TOPT_10_LN,TOPT_10_LT
     + ,PATH_TO_TOPT10M,TOPTWVL,SILAVWT,new_DEM,istatus)
           endif

           write(6,*)
           write(6,*)' Processing 10m land data....'
           CALL GEODAT(nnxp,nnyp,erad,90.,std_lon,xtn,ytn
     +       ,deltax,deltay,TOPT_PCTLFN,adum,adum,adum
     +        ,PATH_TO_PCTL10M,1.,0.
     +         ,new_DEM,istatus)

           if(istatus .ne. 1)then
               write(6,*)' File(s) missing for 10m land data'
               write(6,*)' Static file not created.......ERROR'
               return
           endif

           if (.not.new_DEM) then ! Blend 30" and 10' topo data
             do i = 1,nnxp
             do j = 1,nnyp

!              Select 30s or 10m topo data for this grid point (or a blend)

!              Check whether 30s data is missing or zero
               if(topt_30(i,j) .eq. 1e30 .or. topt_30(i,j) .eq. 0.
!    1                              .or.
!                  Are we in the Pittsburgh data hole?
!    1            (lat(i,j) .gt. 39.7 .and. lat(i,j) .lt. 41.3 .and.
!    1             lon(i,j) .gt.-79.3 .and. lon(i,j) .lt.-77.7)
     1                                                          )then 

!                  Use 10 min data
                   topt_out(i,j) = topt_10(i,j)
                   topt_out_s(i,j)=topt_10_s(i,j)
                   topt_out_ln(i,j)=topt_10_ln(i,j)
                   topt_out_lt(i,j)=topt_10_lt(i,j)
                   icount_10 = icount_10 + 1

               else ! Use 30s data, except ramp to 10m if near data boundary

!                  Determine the northern boundary of the 30s data at this lon
                   if    (lon(i,j).ge.-129..and.lon(i,j).le.-121.)then       
                       nboundary = 51.
                   elseif(lon(i,j).ge.-121..and.lon(i,j).le.-120.)then     
                       nboundary = 51. - lon(i,j) - (-121.)
                   elseif(lon(i,j).ge.-120..and.lon(i,j).le.-118.)then     
                       nboundary = 50.
                   elseif(lon(i,j).ge.-118..and.lon(i,j).le.-117.)then     
                       nboundary = 50. + lon(i,j) - (-118.)
                   elseif(lon(i,j).ge.-117..and.lon(i,j).le. -89.)then     
                       nboundary = 51.
                   elseif(lon(i,j).ge. -89..and.lon(i,j).le. -85.)then     
                       nboundary = 50.
                   elseif(lon(i,j).ge. -85..and.lon(i,j).le. -83.)then     
                       nboundary = 49.
                   elseif(lon(i,j).ge. -83..and.lon(i,j).le. -81.)then     
                       nboundary = 48.
                   elseif(lon(i,j).ge. -81..and.lon(i,j).le. -73.)then     
                       nboundary = 46.
                   elseif(lon(i,j).ge. -73..and.lon(i,j).le. -67.)then     
                       nboundary = 47.
                   elseif(lon(i,j).ge. -67.                      )then     
                       nboundary = 46.
                   else
                       nboundary = 51.
                   endif

                   alat1n = nboundary - 0.3
                   alat2n = nboundary - 0.1

!                  Determine the southern boundary of the 30s data at this lon
                   if(lon(i,j) .le. -103.)then         !        lon < -103
                       sboundary = 28. 
                   elseif(lon(i,j).ge.-103. .and. lon(i,j).le.-102.)then       
                       sboundary = 25. +  (-102. - lon(i,j)) * 3.
                   elseif(lon(i,j).ge.-102. .and. lon(i,j).le. -99.)then       
                       sboundary = 25.
                   elseif(lon(i,j).ge.-99.  .and. lon(i,j).le. -98.)then       
                       sboundary = 24. +  ( -98. - lon(i,j))
                   elseif(lon(i,j).ge.-98.                         )then       
                       sboundary = 24.
                   endif

                   alat1s = sboundary + 0.3
                   alat2s = sboundary + 0.1

!                  Decide whether to use 30s or 10m data (or a blend)

                   if  (  lat(i,j) .ge. alat2n)then    ! Use 10m data
                       topt_out(i,j) = topt_10(i,j)
                       topt_out_s(i,j)=topt_10_s(i,j)
                       topt_out_ln(i,j)=topt_10_ln(i,j)
                       topt_out_lt(i,j)=topt_10_lt(i,j)
                       icount_10 = icount_10 + 1

                   elseif(lat(i,j) .ge. alat1n .and. 
     1                    lat(i,j) .le. alat2n)then

!                      Between alat1n and alat2n,        Use weighted average

                       width = alat2n - alat1n
                       frac10 = (lat(i,j) - alat1n) / width
                       topt_out(i,j) = topt_10(i,j) * frac10 
     1                               + topt_30(i,j) * (1. - frac10)
                       topt_out_s(i,j) = topt_10_s(i,j) * frac10
     1                               + topt_30_s(i,j) * (1. - frac10)
                       topt_out_ln(i,j) = topt_10_ln(i,j) * frac10
     1                               + topt_30_ln(i,j) * (1. - frac10)
                       topt_out_lt(i,j) = topt_10_lt(i,j) * frac10
     1                               + topt_30_lt(i,j) * (1. - frac10)
                       icount_ramp = icount_ramp + 1

                       if(icount_ramp .eq. (icount_ramp/5) * 5 )then       
                           write(6,*)
                           write(6,*)'In blending zone, nboundary = '
     1                                       ,nboundary,alat1n,alat2n       
                           write(6,*)'lat/lon/frac =',lat(i,j),lon(i,j)
     1                                               ,frac10
                           write(6,*)'topt_30      =',topt_30(i,j)
                           write(6,*)'topt_10      =',topt_10(i,j)
                           write(6,*)'topt_out     =',topt_out(i,j)
                       endif

                   elseif(lat(i,j) .ge. alat1s .and. 
     1                    lat(i,j) .le. alat1n)then
                       topt_out(i,j) = topt_30(i,j)
                       topt_out_s(i,j)=topt_30_s(i,j)
                       topt_out_ln(i,j)=topt_30_ln(i,j)
                       topt_out_lt(i,j)=topt_30_lt(i,j)
                       icount_30 = icount_30 + 1       ! Use 30s data

                   elseif(lat(i,j) .ge. alat2s .and. 
     1                    lat(i,j) .le. alat1s)then

!                      Between alat1s and alat2s,        Use weighted average

                       width = alat1s - alat2s
                       frac10 = (alat1s - lat(i,j)) / width
                       topt_out(i,j) = topt_10(i,j) * frac10
     1                               + topt_30(i,j) * (1. - frac10)
                       topt_out_s(i,j) = topt_10_s(i,j) * frac10 
     1                               + topt_30_s(i,j) * (1. - frac10)
                       topt_out_ln(i,j) = topt_10_ln(i,j) * frac10
     1                               + topt_30_ln(i,j) * (1. - frac10)
                       topt_out_lt(i,j) = topt_10_lt(i,j) * frac10
     1                               + topt_30_lt(i,j) * (1. - frac10)
                       icount_ramp = icount_ramp + 1

                       if(icount_ramp .eq. (icount_ramp/5) * 5 )then       
                           write(6,*)
                           write(6,*)'In blending zone, sboundary = '
     1                                       ,sboundary,alat1s,alat2s       
                           write(6,*)'lat/lon/frac =',lat(i,j),lon(i,j)
     1                                               ,frac10
                           write(6,*)'topt_30      =',topt_30(i,j)
                           write(6,*)'topt_10      =',topt_10(i,j)
                           write(6,*)'topt_out     =',topt_out(i,j)
                       endif

                   elseif(lat(i,j) .le. alat2s)then    
                       topt_out(i,j) = topt_10(i,j)    ! Use 10m data
                       topt_out_s(i,j)=topt_10_s(i,j)
                       topt_out_ln(i,j)=topt_10_ln(i,j)
                       topt_out_lt(i,j)=topt_10_lt(i,j)
                       icount_10 = icount_10 + 1

                   else
                       write(6,*)' Software error in gridgen_model.f'
                       write(6,*)' lat/lon = ',lat(i,j),lon(i,j)
                       stop

                   endif ! Test to see if we blend the data

               endif ! 30s data check

             enddo ! j
             enddo ! i

           else ! new_DEM, go with 30s topo data
             do j=1,nnyp
             do i=1,nnxp
               topt_out(i,j)=topt_30(i,j)
               topt_out_s(i,j)=topt_30_s(i,j)
               topt_out_ln(i,j)=topt_30_ln(i,j)
               topt_out_lt(i,j)=topt_30_lt(i,j)
             enddo
             enddo
             icount_30=nnyp*nnxp

           endif ! new_DEM

       endif ! iplttopo = 1

       write(6,*)
       print *,'topt_30    =',topt_30(1,1),topt_30(nnxp,nnyp)
       print *,'topt_10    =',topt_10(1,1),topt_10(nnxp,nnyp)
       print *,'topt_out   =',topt_out(1,1),topt_out(nnxp,nnyp)
       print *,'topt_pctlfn=',topt_pctlfn(1,1),topt_pctlfn(nnxp,nnyp)       
       print *,'# of grid pts using 30 sec data =  ',icount_30
       print *,'# of grid pts using 10 min data =  ',icount_10
       print *,'# of grid pts using blended data = ',icount_ramp
C
C*****************************************************************
c now make plot
c rbord is extra border width around grid to make plot look nice
c
	   rbord = 0.0
	   sw(1) = lat(1,1) - rbord
	   sw(2) = lon(1,1) - rbord
	   nw(1) = lat(1,nnyp) + rbord
	   nw(2) = lon(1,nnyp) - rbord
	   ne(1) = lat(nnxp,nnyp) + rbord
	   ne(2) = lon(nnxp,nnyp) + rbord
	   se(1) = lat(nnxp,1) - rbord
	   se(2) = lon(nnxp,1) + rbord

!	   Call opngks
!          Call Map(90.,std_lon,sw,nw,ne,se)
!          print *,'ipltgrid=',ipltgrid
!          if(ipltgrid.eq.1)then
!          print *,'ipltgrid=',ipltgrid
!          Call Grid(nnxp,nnyp,lat,lon)
!          endif
!          if(iplttopo.eq.1)then
!            cinc=100.
!            call conrec(topt_out,nnxp,nnxp,nnyp,
!    +          0.,0.,cinc,-1,0,0)
!           endif
c           call getset(a1,a2,a3,a4,b1,b2,b3,b4,c)
c           call set(a1,a2,a3,a4,b1,b2,b3,b4,c)
c           print *,a1,a2,a3,a4
c           print *,b1,b2,b3,b4
c           print *,c
c           call wtstr(0.2,0.2,'XXXXXXX=',20,0,-1)
c            call pwritx(800,800,'SILAVWT=',8,20,0,-1)
C

!          if(.true.)then
!            call frame
!            cinc=5.
!            call conrec(topt_pctlfn,nnxp,nnxp,nnyp,
!    +          0.,0.,cinc,-1,0,0)
!          endif

!          Call frame
!	   Call clsgks

        call s_len(static_dir,len)
        open(10,file=static_dir(1:len)//'latlon.dat'
     +         ,status='unknown',form='unformatted')
        open(11,file=static_dir(1:len)//'topo.dat'
     +         ,status='unknown',form='unformatted')
        open(15,file=static_dir(1:len)//'corners.dat'
     +         ,status='unknown')
        write(10)lat,lon
        write(11)topt_out
cc
cc  Is this just a legacy of some bygone days?  
cc  I don't think 12,13,14,and 16 are used - jim
cc
c        write(12,*)topt_30
c        write(13,*)topt_10
c        write(14,*)topt_out
        write(15,*)lat(1,1),lon(1,1)
        write(15,*)lat(1,nnyp),lon(1,nnyp)
        write(15,*)lat(nnxp,1),lon(nnxp,1)
        write(15,*)lat(nnxp,nnyp),lon(nnxp,nnyp)
c        write(16,*)topt_pctlfn
        close(10)
        close(11)
        close(15)

c SG97  topography.dat is written to be displayed with gnuplot
c SG97  this will make an elevated view from the SW direction over the domain
c SG97  start gnuplot and type in the following commands:
c SG97  set data style lines
c SG97  set view 30,330
c SG97  splot 'topography.dat'

	open(666,file=static_dir(1:len)//'topography.dat')
        do j=1,nnyp
	  do i=1,nnxp
	    write(666,*) topt_out(i,j)
          enddo
            write(666,'()')
        enddo
        close(666)
c
c retrieve climatological albedo. Currently this is a fixed water albedo
c that is a namelist value (nest7grid.parms - water_albedo_cmn)
c
        call get_static_albedo(nnxp,nnyp,lat,lon,topt_pctlfn
     +,static_albedo,istatus)

        if(c10_grid_fname(1:lf).eq.'wrfsi')then

           call move(lat,data(1,1,1),nnxp,nnyp)            ! KWD
           call move(lon,data(1,1,2),nnxp,nnyp)            ! KWD
           call move(lats(1,1,2),data(1,1,3),nnxp,nnyp)    ! JS
           call move(lons(1,1,2),data(1,1,4),nnxp,nnyp)    ! JS
           call move(lats(1,1,3),data(1,1,5),nnxp,nnyp)    ! JS
           call move(lons(1,1,3),data(1,1,6),nnxp,nnyp)    ! JS
           call move(topt_out,data(1,1,7),nnxp,nnyp)       ! KWD
           call move(topt_pctlfn,data(1,1,8),nnxp,nnyp)    ! KWD
           call move(soil,data(1,1,9),nnxp,nnyp)           ! SA
c
           call get_projrot_grid(nnxp,nnyp,lat,lon
     +,projrot_grid,istatus)
           call move(projrot_grid(1,1,1),data(1,1,10)
     +,nnxp,nnyp)
           call move(projrot_grid(1,1,2),data(1,1,11)
     +,nnxp,nnyp)
c
           call get_map_factor_grid(nnxp,nnyp,n_staggers
     +,lats,lons ,r_map_factors,istatus)
           if(istatus.ne.1)then
              print*,'Error returned: get_maps_factor_grid'
              return
           endif
           call move(r_map_factors(1,1,1),data(1,1,12)
     +,nnxp,nnyp)
           call move(r_map_factors(1,1,2),data(1,1,13)
     +,nnxp,nnyp)
           call move(r_map_factors(1,1,3),data(1,1,14)
     +,nnxp,nnyp)
c           
           call get_coriolis_components(nnxp,nnyp,lat
     +,coriolis_parms)
           call move(coriolis_parms(1,1,1),data(1,1,15)
     +,nnxp,nnyp)
           call move(coriolis_parms(1,1,2),data(1,1,16)
     +,nnxp,nnyp)

           call move(static_albedo,data(1,1,17),nnxp,nnyp)
           call move(topt_out_s,data(1,1,18),nnxp,nnyp)
           call move(topt_out_ln,data(1,1,19),nnxp,nnyp)
           call move(topt_out_lt,data(1,1,20),nnxp,nnyp)

           ngrids=21
           call get_gridgen_var(nf,ngrids,var,comment)

        else

           call move(lat,data(1,1,1),nnxp,nnyp)            ! KWD
           call move(lon,data(1,1,2),nnxp,nnyp)            ! KWD
           call move(topt_out,data(1,1,3),nnxp,nnyp)       ! KWD
           call move(topt_pctlfn,data(1,1,4),nnxp,nnyp)    ! KWD
           call move(soil,data(1,1,5),nnxp,nnyp)           ! SA
           call move(static_albedo,data(1,1,6),nnxp,nnyp)  ! JS
           call move(topt_out_s,data(1,1,7),nnxp,nnyp)     ! JS
           call move(topt_out_ln,data(1,1,8),nnxp,nnyp)    ! JS
           call move(topt_out_lt,data(1,1,9),nnxp,nnyp)    ! JS 
           ngrids=10
           call get_gridgen_var(nf,ngrids,var,comment)
 
        endif

        filename = c10_grid_fname(1:lf)//'.cdl'
        call s_len(filename,lfn)
        call get_directory('cdl',cdl_dir,lcdl)

        INQUIRE(FILE=cdl_dir(1:lcdl)//filename(1:lfn),EXIST=exist)

        if(.not.exist) then
           print*,'Error: Could not find file '
     +           ,cdl_dir(1:len)//filename(1:lfn)
           print*,'c10_grid_fname: ',c10_grid_fname(1:lf)
           istatus = 0
           return
        endif

        call check_domain(lat,lon,nnxp,nnyp,grid_spacing_m,1,istat_chk)

        write(6,*)'deltax = ',deltax

        if(istat_chk .eq. 1)then
            write(6,*)'check_domain: status = ',istat_chk
        else
            write(6,*)'ERROR in check_domain: status = ',istat_chk       
        endif

        call put_laps_static(grid_spacing_m,model,comment,var
     1       ,data,nnxp,nnyp,nf,ngrids,std_lat,std_lat2,std_lon
     1       ,c6_maproj,deltax,deltay)

        istatus = istat_chk
	return
	End

      SUBROUTINE GEODAT(n2,n3,erad,rlat,wlon1,xt,yt,deltax,deltay
     1 ,DATR,DATS,DATLN,DATLT,OFN,WVLN,SILWT,which_data
     1 ,istat_files)
      include 'trigd.inc'
      implicit none
      integer n2,n3,n23,lb,mof,np,niq,njq,nx,ny,isbego,iwbego,
     1  iblksizo,no,iodim,istat_files
      parameter (n23=20000)
      real vt3da(500)
      real vctr1(n23),
     1 vctr21(n23),erad,rlat,wlon1,deltax,deltay,wvln,silwt
      real DATR(N2,N3)
      real DATS(N2,N3)
      real DATLN(N2,N3)
      real DATLT(N2,N3)
c      PARAMETER(IODIM=59000)
c SG97 iodim increased, to be able to read larger blocks of data
      PARAMETER(IODIM=5800000)
      real DATO(IODIM)
      real xt(N2),YT(N3),deltallo,deltaxq,deltayq,
     1  deltaxp,deltayp
      real std_lon
      integer istatus
      CHARACTER*(*) OFN
      character*180 TITLE
      logical which_data
C
c *********************
      nx=n2-1
      ny=n3-1
c ****************************
      LB=INDEX(OFN,' ')-1
      TITLE=OFN(1:LB)//'HEADER'
      LB=INDEX(TITLE,' ')-1
      CALL JCLGET(29,TITLE(1:LB),'FORMATTED',1,istatus)
      if(istatus .ne. 1)then
          write(6,*)' Error in gridgen_model opening HEADER: check '
     1             ,'geog paths and HEADER file'
          stop
      endif

      READ(29,2)IBLKSIZO,NO,ISBEGO,IWBEGO
 2    FORMAT(4I5)
      print *,'title=',title
      print *,'isbego,iwbego=',isbego,iwbego
      print *,'iblksizo,no=',iblksizo,no
      CLOSE(29)
      DELTALLO=FLOAT(IBLKSIZO)/FLOAT(NO-1)
      MOF=IODIM/(NO*NO)
c SG97 MOF determines the number of files held in buffer while reading
c SG97 DEM data; it saves some time when buffer data can be used instead
c SG97 of reading DEM file again. Originally MOF was 4.
      if (MOF.gt.10) MOF=5
      DELTAXQ=0.5*WVLN*DELTAX
      DELTAYQ=0.5*WVLN*DELTAY
      print *,'deltaxq,deltayq=',deltaxq,deltayq
      NP=MIN(10,MAX(1,INT(DELTAXQ/(DELTALLO*111000.))))
      print *,' np=',np
      DELTAXP=DELTAXQ/FLOAT(NP)
      DELTAYP=DELTAYQ/FLOAT(NP)
      NIQ=INT(FLOAT(NX)*DELTAX/DELTAXQ)+4
      NJQ=INT(FLOAT(NY)*DELTAY/DELTAYQ)+4
C
      call get_standard_longitude(std_lon,istatus)
      if(istatus .ne. 1)then
          write(6,*)' Error calling laps routine'
          stop 
      endif
      CALL SFCOPQR(NO,MOF,NP,NIQ,NJQ,N2,N3,XT,YT,90.,std_lon,ERAD
     +            ,DELTALLO,DELTAXP,DELTAYP,DELTAXQ,DELTAYQ,IBLKSIZO
     +            ,ISBEGO,IWBEGO,DATO,VT3DA,DATR,DATS,DATLN,DATLT
     +            ,VCTR1,VCTR21,OFN,WVLN,SILWT,which_data,istat_files)       
      RETURN
      END


C
C     ******************************************************************
C
      SUBROUTINE SFCOPQR(NO,MOF,NP,NIQ,NJQ,N2,N3,XT,YT,RLAT,WLON1,ERAD
     +          ,DELTALLO,DELTAXP,DELTAYP,DELTAXQ,DELTAYQ,IBLKSIZO
     +          ,ISBEGO,IWBEGO,DATO,DATP,DATR,DATS,DATLN,DATLT,ISO,IWO
     +          ,OFN,WVLN,SILWT,dem_data,istat_files)
      real dato(no,no,mof)
      real DATP(NP,NP),DATQ(NIQ,NJQ),DATR(N2,N3),DATQS(NIQ,NJQ),
     +     DATSM(NIQ,NJQ),DATSMX(NIQ,NJQ),
     +     DATS(N2,N3),DATSLN(NIQ,NJQ),DATSLT(NIQ,NJQ),
     +     DATLN(N2,N3),DATLT(N2,N3)
      real ISO(MOF),IWO(MOF),XT(N2),YT(N3),rlat,wlon1,
     +     erad,deltallo,deltaxp,deltayp,deltaxq,deltayq,
     +     wvln,silwt,xq,yq,xp,yp,xcentr,ycentr,glatp,               ! pla,plo,
     +     glonp,rio,rjo,wio2,wio1,wjo2,wjo1,xq1,yq1
      real xr,yr,rval,sh,sha,rh,rha,rhn,rht,shn,sht
      real shln,shlt,rhln,rhlt
      real delta_ln(niq,njq),delta_lt(niq,njq)
      CHARACTER*180 OFN,TITLE3,TITLE3_last_read,TITLE3_last_inquire
      CHARACTER*3 TITLE1
      CHARACTER*4 TITLE2
      LOGICAL L1,L2,dem_data,l_string_contains
      data icnt/0/
      save icnt
C
      print *,'no,mof,np,niq,njq=',no,mof,np,niq,njq
c      stop

      istat_files = 1

      NONO=NO*NO
      XCENTR=0.5*(XT(1)+XT(N2))
      YCENTR=0.5*(YT(1)+YT(N3))
      print *,xt(1),xt(n2),xcentr
      print *,'deltaxp=',deltaxp
      NOFR=0
      DO 11 IOF=1,MOF
         ISO(IOF)=0
         IWO(IOF)=0
  11  continue

      TITLE3_last_read    = '/dev/null'
      TITLE3_last_inquire = '/dev/null'

      DO 15 JQ=1,NJQ
         print *,'jq,njq,niq=',jq,njq,niq
         DO 16 IQ=1,NIQ
            XQ=(FLOAT(IQ)-0.5*FLOAT(NIQ+1))*DELTAXQ+XCENTR
            YQ=(FLOAT(JQ)-0.5*FLOAT(NJQ+1))*DELTAYQ+YCENTR
            DO 17 JP=1,NP
               DO 18 IP=1,NP
                  XP=XQ+(FLOAT(IP)-0.5*FLOAT(NP+1))*DELTAXP
                  YP=YQ+(FLOAT(JP)-0.5*FLOAT(NP+1))*DELTAYP
!                 CALL XYTOPS(XP,YP,PLA,PLO,ERAD)
!                 CALL PSTOGE(PLA,PLO,GLATP,GLONP,rlat,wlon1)

c                 call xy_to_latlon(XP,YP,erad,rlat,wlon1,GLATP,GLONP) 
                  call xy_to_latlon(XP,YP,erad,GLATP,GLONP) 

c                 print *,'rlat,wlon1=',rlat,wlon1
                  ISOC=(INT((GLATP-FLOAT(ISBEGO))/FLOAT(IBLKSIZO)+200.)
     +                -200)*IBLKSIZO+ISBEGO
                  IWOC=(INT((GLONP-FLOAT(IWBEGO))/FLOAT(IBLKSIZO)+400.)
     +                -400)*IBLKSIZO+IWBEGO
                  DO 19 IOFR=1,NOFR
                     JOFR=IOFR
                     IF(ISO(IOFR).EQ.ISOC.AND.IWO(IOFR).EQ.IWOC)GO TO 10
 19                 continue
                  ISOCPT=ABS(ISOC)/10
                  ISOCPO=ABS(ISOC)-ISOCPT*10
                  IWOCPH=ABS(IWOC)/100
                  IWOCPT=(ABS(IWOC)-IWOCPH*100)/10
                  IWOCPO=ABS(IWOC)-IWOCPH*100-IWOCPT*10
                  IF(ISOC.GE.0)THEN
                     WRITE(TITLE1,'(2I1,A1)')ISOCPT,ISOCPO,'N'
                  ELSE
                     WRITE(TITLE1,'(2I1,A1)')ISOCPT,ISOCPO,'S'
                  ENDIF

                  IF(IWOC.GE.0 
     1               .and. IWOC .ne. 180                    ! 1998 Steve Albers
     1                                      )THEN
                     WRITE(TITLE2,'(3I1,A1)')IWOCPH,IWOCPT,IWOCPO,'E'
                  ELSE
                     WRITE(TITLE2,'(3I1,A1)')IWOCPH,IWOCPT,IWOCPO,'W'
                  ENDIF

                  LB=INDEX(OFN,' ')-1
                  TITLE3=OFN(1:LB)//TITLE1//TITLE2
                  LB=INDEX(TITLE3,' ')-1

                  if(TITLE3 .ne. TITLE3_last_inquire)then
                     INQUIRE(FILE=TITLE3(1:LB),EXIST=L1,OPENED=L2)
                     TITLE3_last_inquire = TITLE3
                  endif

                  IF(.NOT.L1)THEN
                     iwrite = 0

                     if(icnt .le. 100)then ! Reduce the output
                         iwrite=1

                     elseif(icnt .le. 1000)then
                         if(icnt .eq. (icnt/100)*100)iwrite=1

                     elseif(icnt .le. 10000)then
                         if(icnt .eq. (icnt/1000)*1000)iwrite=1

                     elseif(icnt .le. 100000)then
                         if(icnt .eq. (icnt/10000)*10000)iwrite=1

                     else
                         if(icnt .eq. (icnt/100000)*100000)iwrite=1

                     endif

                     if(iwrite .eq. 1)then
                        if(l_string_contains(TITLE3(1:LB),
     1                                       'world_topo_30s',
     1                                       istatus)             )then       
                           PRINT*, ' ERROR: ',TITLE3(1:LB)
     1                            ,' DOES NOT EXIST ',icnt

                        elseif(l_string_contains(TITLE3(1:LB),
     1                                           'topo_30s',
     1                                       istatus)             )then       
                           PRINT*, ' topo_30s file ',TITLE3(1:LB)
     1                            ,' does not exist, using topo_10m '
     1                            ,icnt

                        else ! Generic warning message
                           PRINT*, ' WARNING: ',TITLE3(1:LB)
     1                            ,' DOES NOT EXIST ',icnt

                        endif

                     endif ! iwrite

                     icnt = icnt + 1
                     DATP(IP,JP) = 0. ! set to missing?
                     istat_files = 0
                     GO TO 20
                  ENDIF

                  IF(NOFR.GE.MOF)THEN
                     DO 21 IOF=1,MOF
                        ISO(IOF)=0
                        IWO(IOF)=0
21                    continue
                     NOFR=0
                  ENDIF
                  NOFR=NOFR+1
                  JOFR=NOFR
                  len=index(ofn,' ')

!                 Read the tile
                  if(TITLE3 .ne. TITLE3_last_read)then
                    if( (ofn(len-1:len).eq.'U').and.(no.eq.1200) )then
                      CALL READ_DEM(29,TITLE3(1:LB),no,no,2,4, ! world topo_30s
     .                              DATO(1,1,NOFR))
                      dem_data=.true.
                    elseif( (ofn(len-1:len).eq.'O') )then      ! soil
                      CALL READ_DEM(29,TITLE3(1:LB),no,no,1,4,
     .                              DATO(1,1,NOFR))
                      dem_data=.true.
                    else                                       ! other
                      CALL JCLGET(29,TITLE3(1:LB),'FORMATTED',0,istatus)      
                      CALL VFIREC(29,DATO(1,1,NOFR),NONO,'LIN')
                      if ((ofn(len-1:len).eq.'U').and.(no.eq.121)) then
                        dem_data=.false.                       ! topo_30s
                      endif
                    endif

                    TITLE3_last_read = TITLE3

c                   print *,'nofr,dato=',nofr,dato(1,1,nofr)
                    CLOSE(29)

                  else
                    write(6,*)' We have made the code more efficient'

                  endif ! Is this a new file we haven't read yet?

                  ISO(NOFR)=ISOC
                  IWO(NOFR)=IWOC
10		  continue
                  RIO=(GLONP-FLOAT(IWOC))/DELTALLO+1.
                  RJO=(GLATP-FLOAT(ISOC))/DELTALLO+1.
!                 Prevent Bounds Error (Steve Albers)
                  if(RIO .lt. 1.0)then
                      if(RIO .gt. 0.98)then
                          write(6,*)' Reset RIO for Machine Epsilon'      
                          RIO = 1.0
                      else
                          write(6,*)' ERROR: RIO out of bounds',RIO
                          stop
                      endif
                  endif

                  if(RJO .lt. 1.0)then
                      if(RJO .gt. 0.98)then
                          write(6,*)' Reset RJO for Machine Epsilon'      
                          write(6,*)JQ,IQ,
     1                          IP,JP,IO1,JO1,JOFR,RIO,RJO,GLATP,ISOC
                          RJO = 1.0
                      else
                          write(6,*)' ERROR: RJO out of bounds',RJO
                          write(6,*)JQ,IQ,
     1                          IP,JP,IO1,JO1,JOFR,RIO,RJO,GLATP,ISOC
                          stop
                      endif
                  endif

C
                  IO1=INT(RIO)
                  JO1=INT(RJO)
                  IO2=IO1+1
                  JO2=JO1+1
                  WIO2=RIO-FLOAT(IO1)
                  WJO2=RJO-FLOAT(JO1)
                  WIO1=1.0-WIO2
                  WJO1=1.0-WJO2
                  DATP(IP,JP)=WIO1*(WJO1*DATO(IO1,JO1,JOFR)
     +                             +WJO2*DATO(IO1,JO2,JOFR))
     +                       +WIO2*(WJO1*DATO(IO2,JO1,JOFR)
     +                             +WJO2*DATO(IO2,JO2,JOFR))

!S & W-facing slopes > 0.
                  DELTA_LN(IP,JP)=
     .           ((DATO(IO2,JO1,JOFR)-DATO(IO1,JO1,JOFR))+
     .            (DATO(IO2,JO2,JOFR)-DATO(IO1,JO2,JOFR)))*.5

                  DELTA_LT(IP,JP)=
     .           ((DATO(IO1,JO2,JOFR)-DATO(IO1,JO1,JOFR))+
     .            (DATO(IO2,JO2,JOFR)-DATO(IO2,JO1,JOFR)))*.5

20               CONTINUE
18             continue ! IP
17           continue ! JP

!           Calculate average and silhouette terrain, then apply SILWT weight
            SHA=0.
            RHA=0.
            RHLN=0.
            RHLT=0.
            shmax=0.

            DO 22 JP=1,NP
               SH=0.
               RH=0.
               RHN=0.
               RHT=0.
               DO 23 IP=1,NP
!                 Test for missing - then go to 16?
                  SH=max(SH,DATP(IP,JP)) 
                  RH=RH+DATP(IP,JP)
                  RHN=RHN+DELTA_LN(IP,JP)
                  RHT=RHT+DELTA_LT(IP,JP)
23             continue ! IP

               SHA=SHA+SH/(2.*FLOAT(NP))
               RHA=RHA+RH
               RHLN=RHLN+RHN
               RHLT=RHLT+RHT
               SHMAX=max(SHMAX,SH)
22          continue ! JP
 
            RHA=RHA/FLOAT(NP*NP)
            RMS=0.0
            DO 24 IP=1,NP ! The reason for this second SHA loop is unclear
c              SH=0.      ! It is now used for std dev of terrain
               DO 25 JP=1,NP
c                 SH=max(SH,DATP(IP,JP))
                  RMS=RMS+((DATP(IP,JP)-RHA)*(DATP(IP,JP)-RHA))
25             continue ! JP

c              SHA=SHA+SH/(2.*FLOAT(NP))

24          continue ! IP

            DATQS(IQ,JQ)=SQRT(RMS/FLOAT(NP*NP))
            DATQ(IQ,JQ)=SHA*SILWT+RHA*(1.-SILWT)
            DATSM(IQ,JQ)=RHA                           !mean value of points used for IQ,JQ
            DATSMX(IQ,JQ)=SHMAX                        !max value from points used for IQ,JQ
            DATSLN(IQ,JQ)=RHLN/FLOAT(NP*NP)/DELTAXP
            DATSLT(IQ,JQ)=RHLT/FLOAT(NP*NP)/DELTAYP

c           print *,'datq=',datq(iq,jq)

16      continue ! IQ
15    continue ! JQ

      print *,'after 15'
c     stop
 
      XQ1=(1.-0.5*FLOAT(NIQ+1))*DELTAXQ+XCENTR
      YQ1=(1.-0.5*FLOAT(NJQ+1))*DELTAYQ+YCENTR
      print*
      print*,'Before GDTOST2'
      print*,'--------------'
      print*,'datq(1,1)/(niq,njq)= ',datq(1,1),datq(niq,njq)
      print*,'datqs(1,1)/(niq,njq)= ',datqs(1,1),datqs(niq,njq)
      print*,'datsln(1,1)/(niq,njq)= ',datsln(1,1),datsln(niq,njq)
      print*,'datslt(1,1)/(niq,njq)= ',datslt(1,1),datslt(niq,njq)
      print*,'Mean/Max topo at IQ,JQ (1,1)/(niq,njq): '
     +,datsm(1,1),datsmx(1,1),datsm(niq,njq),datsmx(niq,njq)

      DO 28 JR=1,N3
         DO 29 IR=1,N2

            XR=(XT(IR)-XQ1)/DELTAXQ+1.
            YR=(YT(JR)-YQ1)/DELTAYQ+1.
            CALL GDTOST2(DATQ,NIQ,NJQ,XR,YR,RVAL)
            DATR(IR,JR)=max(0.,RVAL)
            if( DATR(IR,JR).gt.30000. )then
                print*,'Warning: value out of bounds'
            endif    

            CALL GDTOST2(DATQS,NIQ,NJQ,XR,YR,RVAL)
            DATS(IR,JR)=max(0.,RVAL)

            CALL GDTOST2(DATSLN,NIQ,NJQ,XR,YR,RVAL)
            DATLN(IR,JR)=RVAL
            CALL GDTOST2(DATSLT,NIQ,NJQ,XR,YR,RVAL)
            DATLT(IR,JR)=RVAL

 29      CONTINUE
 28   CONTINUE

      print*,'After GDTOST2'
      print*,'-------------'
      print*,'datr(1,1)/(n2,n3)= ',datr(1,1),datr(N2,N3)
      print*,'dats(1,1)/(n2,n3)= ',dats(1,1),dats(n2,n3)
      print*,'datln(1,1)/(n2,n3)= ',datln(1,1),datln(n2,n3)
      print*,'datlt(1,1)/(n2,n3)= ',datlt(1,1),datlt(n2,n3)

      RETURN
      END

      SUBROUTINE GDTOST2(A,IX,IY,STAX,STAY,STAVAL)
*  SUBROUTINE TO RETURN STATIONS BACK-INTERPOLATED VALUES(STAVAL)
*  FROM UNIFORM GRID POINTS USING OVERLAPPING-QUADRATICS.
*  GRIDDED VALUES OF INPUT ARRAY A DIMENSIONED A(IX,IY),WHERE
*  IX=GRID POINTS IN X, IY = GRID POINTS IN Y .  STATION
*  LOCATION GIVEN IN TERMS OF GRID RELATIVE STATION X (STAX)
*  AND STATION COLUMN.
*  VALUES GREATER THAN 1.0E30 INDICATE MISSING DATA.
*
      real A(IX,IY),R(4),SCR(4),stax,stay,staval
     +  ,fixm2,fiym2,yy,xx
      IY1=INT(STAY)-1
      IY2=IY1+3
      IX1=INT(STAX)-1
      IX2=IX1+3
      STAVAL=1E30
      FIYM2=FLOAT(IY1)-1
      FIXM2=FLOAT(IX1)-1
      II=0
      DO 100 I=IX1,IX2
      II=II+1
      IF(I.GE.1.AND.I.LE.IX) GO TO 101
      SCR(II)=1E30
      GO TO 100
101   JJ=0
      DO 111 J=IY1,IY2
      JJ=JJ+1
      IF(J.GE.1.AND.J.LE.IY) GO TO 112
      R(JJ)=1E30
      GO TO 111
112   R(JJ)=A(I,J)
111   CONTINUE
      YY=STAY-FIYM2
      CALL BINOM(1.,2.,3.,4.,R(1),R(2),R(3),R(4),YY,SCR(II))
100   CONTINUE
      XX=STAX-FIXM2
      CALL BINOM(1.,2.,3.,4.,SCR(1),SCR(2),SCR(3),SCR(4),XX,STAVAL)
      RETURN
      END

       SUBROUTINE POLAR_GP(LAT,LON,X,Y,DX,DY,NX,NY)
C
      include 'trigd.inc'
       REAL*4 LAT,LON,X,Y,DX,DY,
     1        ERAD,TLAT,TLON                                      ! ,PLAT,PLON,
     1        XDIF,YDIF
C
       INTEGER*4 NX,NY
C
       RAD=3.141592654/180.

       call get_earth_radius(erad,istatus)
       if(istatus .ne. 1)then
           write(6,*)' Error calling get_earth_radius'
           stop
       endif

       TLAT=90.0
       call get_standard_longitude(std_lon,istatus)
       if(istatus .ne. 1)then
           write(6,*)' Error calling laps routine'
           stop 
       endif
       TLON=std_lon
C
C      CALL GETOPS(PLAT,PLON,LAT,LON,TLAT,TLON)
C      CALL PSTOXY(XDIF,YDIF,PLAT,PLON,ERAD)

C      call latlon_to_xy(LAT,LON,TLAT,TLON,ERAD,XDIF,YDIF)
       call latlon_to_xy(LAT,LON,ERAD,XDIF,YDIF)

C
       X=XDIF+(1.-FLOAT(NX)/2.)*DX
       Y=YDIF+(1.-FLOAT(NY)/2.)*DY
C
       RETURN
C
       END
C +------------------------------------------------------------------+
      SUBROUTINE JCL
      CHARACTER*(*) FILENM,FORMT

C     -------------------------------------------------------
      ENTRY JCLGET(IUNIT,FILENM,FORMT,IPRNT,istatus)
C
C         This routine access an existing file with the file name of
C           FILENM and assigns it unit number IUNIT.
C
      IF(IPRNT.EQ.1) THEN
      PRINT*,' Opening input unit ',IUNIT,' file name ',FILENM
      PRINT*,'         format  ',FORMT
      ENDIF

      OPEN(IUNIT,STATUS='OLD',FILE=FILENM,FORM=FORMT,ERR=1)

      istatus=1
      RETURN

 1    istatus = 0
      return

      END
c--------------------------------------------------------               
      subroutinevfirec(iunit,a,n,type)                                  
      character*1vc                                                     
      character*(*)type                                                 
      common/vform/vc(0:63)                                             
      characterline*80,cs*1                                             
      dimensiona(*)                                                     
                                                                        
      if(vc(0).ne.'0')callvfinit                                        
                                                                        
      ich0=ichar('0')                                                   
      ich9=ichar('9')                                                   
      ichcz=ichar('Z')                                                  
      ichlz=ichar('z')                                                  
      ichca=ichar('A')                                                  
      ichla=ichar('a')                                                  
                                                                        
      read(iunit,10)nn,nbits,bias,fact                                  
 10   format(2i8,2e20.10)                                               
      if(nn.ne.n)then                                                   
      print*,' Word count mismatch on vfirec record '                   
      print*,' Words on record - ',nn                                   
      print*,' Words expected  - ',n                                    
      stop'vfirec'                                                      
      endif                                                             
                                                                        
      nvalline=(78*6)/nbits                                             
      nchs=nbits/6                                                      
      do20i=1,n,nvalline                                                
      read(iunit,'(a78)', end=15)line                                          
      go to 16

 15   write(6,*)' Warning, incomplete terrain file detected'
      
 16   ic=0                                                              
      do30ii=i,i+nvalline-1                                             
      isval=0                                                           
      if(ii.gt.n)goto20                                                 
      do40iii=1,nchs                                                    
      ic=ic+1                                                           
      cs=line(ic:ic)                                                    
      ics=ichar(cs)                                                     
      if(ics.le.ich9)then                                               
      nc=ics-ich0                                                       
      elseif(ics.le.ichcz)then                                          
      nc=ics-ichca+10                                                   
      else                                                              
      nc=ics-ichla+36                                                   
      endif                                                             
      isval=intor(intlshft(nc,6*(nchs-iii)),isval)                      
 40   continue                                                          
      a(ii)=isval                                                       
 30   continue                                                          
 20   continue                                                          
                                                                        
      facti=1./fact                                                     
      if(type.eq.'LIN')then                                             
      do48i=1,n                                                         
      a(i)=a(i)*facti-bias                                              
 48   continue                                                          
      elseif(type.eq.'LOG')then                                         
      scfct=2.**(nbits-1)                                               
      do55i=1,n                                                         
      a(i)=sign(1.,a(i)-scfct)                                          
     +*(10.**(abs(20.*(a(i)/scfct-1.))-10.))                            
 55   continue                                                          
      endif                                                             
      return                                                  
      end                            

      subroutinevfinit                                                  
      character*1vc,vcscr(0:63)                                         
      common/vform/vc(0:63)                                             
      datavcscr/'0','1','2','3','4','5','6','7','8','9'                 
     +,'A','B','C','D','E','F','G','H','I','J'                          
     +,'K','L','M','N','O','P','Q','R','S','T'                          
     +,'U','V','W','X','Y','Z','a','b','c','d'                          
     +,'e','f','g','h','i','j','k','l','m','n'                          
     +,'o','p','q','r','s','t','u','v','w','x'                          
     +,'y','z','{','|'/                                                 
                                                                        
      do10n=0,63                                                        
      vc(n)=vcscr(n)                                                    
  10  continue                                                          
                                                                        
      return                                                            
      end

c ********************************************************************

      subroutine read_dem(unit_no,unit_name,nn1,nn2,i1,i2,data)
      implicit none
      integer countx,county,unit_no,nn1,nn2
      real data(nn1,nn2)
      integer idata(nn1,nn2), len, i1, i2
      logical l1,l2
      character*(*) unit_name

C      open(unit_no,file=unit_name,status='old',access='direct',
C     . recl=nn2*nn1*2)
C      inquire(unit_no,exist=l1,opened=l2)
C      read(unit_no,rec=1) idata

      call s_len(unit_name,len) 

      call read_binary_field(idata,i1,i2,nn1*nn2,unit_name,len)

      do county=1,nn2
        do countx=1,nn1
          if (idata(countx,county).eq.-9999) idata(countx,county)=0
           data(countx,county)=float(idata(countx,nn2-county+1))
c SG97 initial data (DEM format) starts in the lower-left corner;
c SG97 this format is wrapped around to have upper-left corner as its start.
        enddo
      enddo
ccc      close(unit_no)
      return
      end

C +------------------------------------------------------------------+
      FUNCTION INTLSHFT(IWORD,NSHFT)
C
C       This function shifts IWORD to the left NSHFT bits in a
C         circular manner.
C
      INTLSHFT=ISHFT(IWORD,NSHFT)
      RETURN
      END
C +------------------------------------------------------------------+
      FUNCTION INTOR(IWORD1,IWORD2)
C
C       This function performs a bit-by-bit OR between IWORD1 and
C         IWORD2.
C
      INTOR=IOR(IWORD1,IWORD2)
      RETURN
      END


      SUBROUTINE BINOM2(X1,X2,X3,X4,Y1,Y2,Y3,Y4,XXX,YYY)
      implicit none
      real x1,x2,x3,x4,y1,y2,y3,y4,xxx,yyy,
     +   wt1,wt2,yz22,yz23,yz24,yz11,yz12,yz13,yoo
      integer istend
c      COMMON/BIN/ITYPP,I0X,I1X,I2X,YOO
       YYY=1E30
       IF(X2.GT.1.E19.OR.X3.GT.1.E19.OR.
     +   Y2.GT.1.E19.OR.Y3.GT.1.E19)RETURN
      WT1=(XXX-X3)/(X2-X3)
      WT2=1.0-WT1
      ISTEND=0
      IF(Y4.LT.1.E19.AND.X4.LT.1.E19) GO TO 410
      YZ22=WT1
      YZ23=WT2
      YZ24=0.0
      ISTEND= 1
410   IF(Y1.LT.1.E19.AND.X1.LT.1.E19) GO TO 430
      YZ11=0.0
      YZ12=WT1
      YZ13=WT2
      IF(ISTEND.EQ.1)GO TO 480
      GO TO 450
430   YZ11=(XXX-X2)*(XXX-X3)/((X1-X2)*(X1-X3))
      YZ12=(XXX-X1)*(XXX-X3)/((X2-X1)*(X2-X3))
      YZ13=(XXX-X1)*(XXX-X2)/((X3-X1)*(X3-X2))
      IF(ISTEND.EQ.  1    ) GO TO 470
450   YZ22=(XXX-X3)*(XXX-X4)/((X2-X3)*(X2-X4))
      YZ23=(XXX-X2)*(XXX-X4)/((X3-X2)*(X3-X4))
      YZ24=(XXX-X2)*(XXX-X3)/((X4-X2)*(X4-X3))
470   YYY=WT1*(YZ11*Y1+YZ12*Y2+YZ13*Y3)+WT2*(YZ22*Y2+YZ23*Y3+YZ24*Y4)
       GO TO 490
480      YYY=WT1*Y2+WT2*Y3
490   YOO=YYY
      RETURN
      END
