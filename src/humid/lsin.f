cdis    forecast systems laboratory
cdis    noaa/oar/erl/fsl
cdis    325 broadway
cdis    boulder, co     80303
cdis
cdis    forecast research division
cdis    local analysis and prediction branch
cdis    laps
cdis
cdis    this software and its documentation are in the public domain and
cdis    are furnished "as is."  the united states government, its
cdis    instrumentalities, officers, employees, and agents make no
cdis    warranty, express or implied, as to the usefulness of the software
cdis    and documentation for any purpose.  they assume no responsibility
cdis    (1) for the use of the software and documentation; or (2) to provide
cdis     technical support to users.
cdis
cdis    permission to use, copy, modify, and distribute this software is
cdis    hereby granted, provided that the entire disclaimer notice appears
cdis    in all copies.  all modifications to this software must be clearly
cdis    documented, and are solely the responsibility of the agent making
cdis    the modifications.  if significant modifications or enhancements
cdis    are made to this software, the fsl software policy manager
cdis    (softwaremgr@fsl.noaa.gov) should be notified.
cdis

      subroutine lsin (i4time,plevel,lt1dat,data,cg,tpw,bias_one,
     1     kstart,qs,p,glat,glon,ii,jj,kk,istatus)

c     this routine is the laps surface interface for water vapor
c     its function is to get the relevant boundary layer moisture
c     and insert it properly into the data array.
c     one other function of this routine is to establish the bounds
c     of the bottom of the column
      
c     updated analysis september 21 1993 -- modified the treatment of the
c     surface level.  moved the surface moisture to the immediate laps level
c     above the surface.   this was done because workstation plotting
c     software would not recognize the extra moisture below ground for
c     asthetic reasons.  also the workstation total precipitable water comp-
c     utation did not match the one made in this code for that saem reason
c     
c     the new arrangement of code does the following.
      
c     basically we prepare all for a call to int_tpw
c     we leave the boundary layer mixing process to analq along with
c     radiometer adjustment.
      
c     1 ) puts qs (surface q) at the plevel above ps (surface pressure)
c     2) does not write any data below ground
c     3) maintains an integral from the true surface ps for tpw
c     this might cause some difference between this output and
c     the workstation integrated soundings, but not the error of
c     putting the data below ground.

      implicit none

c     input variables

      integer i4time,istatus,ii,jj,kk
      real plevel (kk)
      real lt1dat (ii,jj,kk)    ! laps 3-d temp field
      real data (ii,jj,kk)
      real cg (ii,jj,kk)
      real tpw (ii,jj)
      real bias_one
      integer kstart (ii,jj)
      real qs (ii,jj)
      real p (ii,jj)            !surface pressure (topo level)
      real glat (ii,jj)
      real glon (ii,jj)
      
c     internal variables with lapsparms.inc dependence
      
      real
     1     t(ii,jj),            !surface temperature k
     1     pu(ii,jj),           !pressure if top of boundary layer
     1     td(ii,jj),           !dew point temperature of surf. k -> c
     1     blsh(ii,jj)          !boundary layer specific humidity
      
c     normal internal variables
      
      integer
     1     i,j,k
      
c     constants
      save r, bad, g
      real
     1     r,                   !the gas constant for dry air
     1     bad,                 !bad data flag
     1     g                    !the acceleration of gravity
      
      data r /287.04/
      data g /9.80665/
      data bad/-1e30/
      
c     function names
      
      real ssh2                 ! type the funciton ssh2
      
c     special notes:   td will be converted to c for call to ssh
c     p will be converted to mb for comparison to vert coord
      
c-------------------------------code-----------------------------
      
c     get required field variables
      
      call glst(i4time,t,ii,jj,istatus)
      if(istatus.ne.1) return

      call check_nan2 (t,ii,jj,istatus)

      if(istatus.ne.1) then
         write(6,*) 'NaN detected in var:t  routine:lsin.f'
         return
      endif
      
      
      call glsp(i4time,p,ii,jj,istatus)
      if(istatus.ne.1) return

      call check_nan2 (p,ii,jj,istatus)

      if(istatus.ne.1) then
         write(6,*) 'NaN detected in var:p  routine:lsin.f'
         return
      endif
      
      
c     convert p to mb
      
      do j = 1,jj
         do i = 1,ii
            p(i,j) = p(i,j)*.01
         enddo
      enddo
      
      call glstd(i4time,td,ii,jj,istatus)
      if(istatus.ne.1) return

      call check_nan2 (td,ii,jj,istatus)

      if(istatus.ne.1) then
         write(6,*) 'NaN detected in var:td  routine:lsin.f'
         return
      endif
      
      
      call ghbry (i4time,plevel,p,lt1dat,pu,ii,jj,kk,
     1     istatus)
      if(istatus.ne.1) return

      call check_nan2(pu,ii,jj,istatus)

      if(istatus.ne.1) then
         write(6,*) 'NaN detected in var:pu  routine:lsin.f'
         return
      endif
      
      
      istatus = 0               ! begin with bad istatus
      
c     convert td to c then compute surface specific h.
      
      do j = 1,jj
         do i = 1,ii
            
            td(i,j) = td(i,j) - 273.15
            t(i,j)  = t(i,j)  - 273.15
            
            qs (i,j) = ssh2 (p(i,j),t(i,j),
     1           td(i,j),0.0)   ! qs is gm/kg
            
            blsh(i,j) = qs(i,j) *1e-3 ! blsh is gm/gm
            
         enddo
      enddo

      call check_nan2 (qs,ii,jj,istatus)

      if(istatus.ne.1) then
         write(6,*) 'NaN detected in var:qs  routine:lsin.f'
         return
      endif
      
      
c     write surface data in at the bottom of the column
c     define kstart (k index of bottom of the column)
      
      do j = 1,jj
         do i = 1,ii
            do k = 1,kk
               
               if (p(i,j).lt. plevel(k)) then ! plevel is underground
                  data(i,j,k) = bad
                  cg(i,j,k)   = 0.0 ! no clouds under ground
               else
                  data(i,j,k) = blsh(i,j) ! assign boundary layer sh (gm/gm)
c     to the bottom level of the column
c     define kstart
                  kstart(i,j) = k
c     jump out of loop
                  go to 2001
               endif
               
            enddo
 2001       continue
         enddo
      enddo

      call check_nan3 (data,ii,jj,kk,istatus)

      if(istatus.ne.1) then
         write(6,*) 'NaN detected in var:data  routine:lsin.f'
         return
      endif

      call check_nan3 (cg,ii,jj,kk,istatus)

      if(istatus.ne.1) then
         write(6,*) 'NaN detected in var:cg  routine:lsin.f'
         write(6,*) 'detected after boundary layer adjust'
         return
      endif

c     compute the total precipitable water and bias correct total 3-d field to
c     radiometer data
      
      print*, 'call routine analq'
      call analq(i4time,plevel,p,t,pu,td,data,cg,tpw,bias_one,kstart,
     1     qs, glat,glon,ii,jj,kk)
      
      print*, 'done with routine analq'
      
      istatus = 1
      
      return
      
      end
