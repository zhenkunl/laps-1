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
      subroutine draw_county_map(sw,ne,jproj,polat,polon,rrot,jdot
     1                          ,icol_sta,icol_cou,ni,nj)
c
c
      real*4 sw(2),ne(2),pl1(2),pl2(2),pl3(2),pl4(2),
     +       polat,polon,rrot

c
      integer*4 jproj,jjlts,jgrid,jus,jdot,ier
c
      COMMON/SUPMP9/DS,DI,DSRDI

!     DI = 50.
!     polat=90.

!     rrot=0.
      pl1(1)=sw(1)
      pl2(1)=sw(2)
      pl3(1)=ne(1)
      pl4(1)=ne(2)
      jjlts=-2
      jgrid=0
!     jgrid=1 ! Draw lat/lon lines

      call get_grid_spacing(grid_spacing_m,istatus)
      if(istatus .ne. 1)then
          write(6,*)' no grid spacing, stop in draw_county_map'
          stop
      else
          write(6,*)' Subroutine draw_county_map...'
      endif

      domsize = (max(ni,nj)-1.) * grid_spacing_m

!     Plot Counties
      jus=-4

      if(jdot .eq. 1)then
          call gsln(3) ! Dotted
      else
          call gsln(1) ! Solid
      endif

      if(domsize .le. 2500e3)then
          write(6,*)' Plotting Counties'
          call setusv_dum(2HIN,icol_cou)
          call supmap(jproj,polat,polon,rrot,pl1,pl2,pl3,pl4,jjlts,
     +                jgrid,jus,jdot,ier)
          call sflush
      else
          write(6,*)' Large domain, omitting counties'

      endif

      write(6,*)' Plotting States From Counties'
      jus=-8
      call gsln(1)
      call setusv_dum(2HIN,icol_sta)
      call supmap(jproj,polat,polon,rrot,pl1,pl2,pl3,pl4,jjlts,
     +            jgrid,jus,jdot,ier)
      call sflush

      write(6,*)' Plotting Continents'
      jus=-1
      call gsln(1)
      call setusv_dum(2HIN,icol_sta)
      call supmap(jproj,polat,polon,rrot,pl1,pl2,pl3,pl4,jjlts,
     +            jgrid,jus,jdot,ier)
      call sflush

      return
      end
