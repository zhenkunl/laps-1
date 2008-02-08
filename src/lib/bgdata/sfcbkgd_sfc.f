      SUBROUTINE SFCBKGD_SFC(bgmodel,t,q,height,heightsfc
     &,td_sfc,tsfc,tdsfc, ter,p,IMX,JMX,KX,psfc)

c inputs are from laps analyzed 2- 3d fields
C     INPUT       t        ANALYZED TEMPERATURE     3D
C                 q        Analyzed MIXXING RATIO   3D
C                 height   ANALYZED HEIGHT          3D
c                heightsfc ANALYZED HEIGHT          2D
C                 ter      TERRAIN                  2D
C                 IMX      DIMENSION E-W
C                 JMX      DIMENSION N-S
C                 KX       NUMBER OF VERTICAL LEVELS
C                 p        LAPS Pressure levels     1D
C                 tdsfc    LAPS Dew Point Temp      2D
c                 td_sfc   ANALYZED DEW POINT TEMP  2D

c
c J. Smart    09-22-98:	Original Version: This is used to compute
c                       sfc p for lgb when using NOGAPS1.0 deg since
c                       this field currently does not come with the
c                       model grids at AFWA.
c    "        02-01-99: Recompute tdsfc with new psfc and tsfc for
c                       consistency.
c    "        11-18-99: Put psfc,tsfc, and tdsfc comps into subroutine
c KML:  CHANGES MADE APRIL 2004
c this subroutine now reads in heightsfc and td_sfc
c heightsfc and td_sfc are passed into subroutine compute_sfc_bgfields
c KML: END
c
      IMPLICIT NONE

      INTEGER    I
      INTEGER    IMX
      INTEGER    J
      INTEGER    JMX
      INTEGER    K
      INTEGER    KX
      INTEGER    it
      INTEGER    bgmodel

      LOGICAL    lfndz

      REAL       HEIGHT      ( IMX , JMX, KX )
      REAL       HEIGHTSFC   ( IMX, JMX )
      REAL       P           ( KX )
      REAL       PSFC        ( IMX , JMX )
      REAL       TSFC        ( IMX , JMX )
      REAL       Q           ( IMX , JMX , KX )
      REAL       rh3d        ( IMX , JMX , KX )
      REAL       rh2d        ( IMX , JMX )
      REAL       tdsfc       ( imx,  jmx )
      REAL       td_sfc      ( imx,  jmx )
      REAL       T           ( IMX , JMX , KX )
      REAL       esat
      REAL       TER         ( IMX , JMX )
      REAL       make_td
      REAL       make_rh
      REAL       make_ssh
      REAL       t_ref,badflag
c
c if bgmodel = 6 or 8 then tdsfc is indeed td sfc
c if bgmodel = 4      then tdsfc is rh (WFO - RUC)
c if bgmodel = 9      then no surface fields input. Compute all from 3d
c                     fields. q3d used. (NOS - ETA)
c otherwise tdsfc is input with q
c 
      t_ref=-132.0
      if(bgmodel.eq.3.or.bgmodel.eq.9)then
         do k=1,kx
            do j=1,jmx
            do i=1,imx
               rh3d(i,j,k)=make_rh(p(k),t(i,j,k)-273.15,q(i,j,k)*1000.
     +,t_ref)*100.
            enddo
            enddo
         enddo

         badflag=0.
         call interp_to_sfc(ter,rh3d,height,imx,jmx,kx,
     &                      badflag,tdsfc)
         call interp_to_sfc(ter,t,height,imx,jmx,kx,badflag,
     &                      tsfc)
      endif

      do j=1,jmx
      do i=1,imx

         k=0
         lfndz=.false.
         do while(.not.lfndz)
            k=k+1
            if(height(i,j,k).gt.ter(i,j))then
               lfndz=.true.
c
c
c recompute psfc with moisture consideration. snook's orig code.
c              it=tdsfc(i,j)*100.
c              it=min(45000,max(15000,it))
c              xe=esat(it)
c              qsfc=0.622*xe/(p_sfc-xe)
c              qsfc=qsfc/(1.+qsfc)
c --------------------------------------------------

               if(k.gt.0)then
                  call compute_sfc_bgfields_sfc(bgmodel,imx,jmx,kx,i,j,k
     &,ter(i,j),height,heightsfc(i,j),t,p,q,t_ref,psfc(i,j),tsfc(i,j),
     &tdsfc(i,j),td_sfc(i,j))
c              else
c                 tsfc(i,j)=t(i,j,k)
c                 tdsfc(i,j)=make_td(p(k),t(i,j,k)-273.15,q(i,j,k)*1000.
c    &,t_ref)+273.15

               endif

            endif
            if(k.eq.kx)lfndz=.true.
         enddo
      enddo
      enddo 
      
      return
      end
c
c----------------------------------------------------------------------------
c
      subroutine compute_sfc_bgfields_sfc(bgm,nx,ny,nz,i,j,k,ter,height
     &,heightsfc,t,p,q,t_ref,psfc,tsfc,tdsfc,td_sfc)
c
c J. Smart 11/18/99 put existing code in subroutine for other process use in laps
c
c KML: CHANGES MADE APRIL 2004
c heightsfc (analyzed 2m height) and td_sfc are now read in
c dz is computed as the difference between heightsfc and terrain
c lapse rate adjustment is made to tsfc and td_sfc (2m level)...
c  ...rather than t and td2 (pressure levels)
c KML: END
      implicit none
                                
      integer nx,ny,nz
      integer i,j,k            !I, i,j,k coordinate of point for calculation
      integer bgm              !I, model type {if = 0, then tdsfc input = qsfc}
      integer istatus
                                                      
      real   p(nz)             !I, pressure of levels
      real   ter               !I, Terrain height at i,j
      real   t_ref             !I, reference temp for library moisture conv routines
                                                     
      real   height(nx,ny,nz)  !I, heights of pressure levels 3d
      real   heightsfc         !I, height of surface at i,j
      real   t(nx,ny,nz)       !I, temperatures 3d
      real   q(nx,ny,nz)       !I, specific humidity 3d
      real   psfc              !I/O, input bkgd model sfc p; output recalculated surface pressure, pa
      real   tsfc              !I/O input model T, output recomputed T
      real   tdsfc             !I/O input model Td, output  recomputed Td
      real   td_sfc            !I, model Td
      real   qsfc              !I/O surface spec hum, Input as q or computed internally
                                                           
      real   tbar
      real   td1,td2
      real   G,R
      real   ssh2,make_ssh,make_td
      real   dz,dzp,dtdz
      real   tvsfc,tvk,tbarv
      real   r_missing_data
                                                        
      parameter (G         = 9.8,
     &           R         = 287.04)
c
c if first guess values are missing data then return missing data
c
       call get_r_missing_data(r_missing_data,istatus)
       if(tsfc.lt.500.0.and.t(i,j,k).lt.500.0.and.
     .td_sfc.lt.500.0)then
c
c first guess psfc without moisture consideration
c
                                              
          tbar=(tsfc+t(i,j,k))*0.5
          dz=heightsfc-ter
c         psfc=p(k)*exp(G/(R*tbar)*dz)
          psfc=psfc/100.                                !calcs done in mb
          psfc=psfc*exp(G/(R*tbar)*dz)
                             
          if(bgm.eq.0.or.bgm.eq.6.or.bgm.eq.8)then      !Td
             qsfc=ssh2(psfc,tsfc-273.15
     &                  ,tdsfc-273.15,t_ref)*.001  !kg/kg
          elseif(bgm.eq.3.or.bgm.eq.4.or.bgm.eq.9)then  !RH
             qsfc=make_ssh(psfc,tsfc-273.15
     &                      ,tdsfc/100.,t_ref)*.001  !kg/kg
                                           
          else                              !q
             qsfc=tdsfc
          endif
                                         
c pressure
          tvsfc=tsfc*(1.+0.608*qsfc)
          tvk=t(i,j,k)*(1.+0.608*q(i,j,k))
          tbarv=(tvsfc+tvk)*.5
c         psfc=(p(k)*exp(G/(R*tbarv)*dz))*100.  !return units = pa
          psfc=(psfc*exp(G/(R*tbarv)*dz))*100.  !return units = pa
          if(k.gt.1)then
             dzp=height(i,j,k)-height(i,j,k-1)
c temp
             dtdz=(t(i,j,k-1)-t(i,j,k))/dzp
             tsfc=tsfc+dtdz*dz
c dew point temp
             td2=make_td(p(k),t(i,j,k)-273.15,q(i,j,k)*1000.,t_ref)
             td1=make_td(p(k-1),t(i,j,k-1)-273.15,q(i,j,k-1)*1000.
     .,t_ref)
             tdsfc=td_sfc+((td1-td2)/dzp)*dz
c
          else
             dzp=height(i,j,k+1)-height(i,j,k)
             td2=make_td(p(k+1),t(i,j,k+1)-273.15
     &,q(i,j,k+1)*1000.,t_ref)+273.15
             td1=make_td(p(k),t(i,j,k)-273.15
     &,q(i,j,k)*1000.,t_ref)+273.15
             dtdz=(t(i,j,k)-t(i,j,k+1))/dzp
             tsfc=tsfc+dtdz*dz
             tbar=(tsfc+t(i,j,k))*0.5
c            psfc=p(k)*exp(G/(R*tbar)*dz)
             psfc=psfc*exp(G/(R*tbar)*dz)
             tdsfc=td_sfc+((td1-td2)/dzp)*dz
                                   
          endif
       else
          psfc =r_missing_data
          tsfc =r_missing_data
          tdsfc=r_missing_data
       endif
       return
       end
