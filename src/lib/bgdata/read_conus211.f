      subroutine get_sbn_model_id(filename,model,ivaltimes,mtbg)
      implicit none
      include 'netcdf.inc'
      character*(*) model
      character*(*) filename
      integer ivaltimes(*)
      integer nf_fid, nf_vid, nf_status, ntbg, mtbg
      common /conus211/ ntbg
C
C  Open netcdf File for reading
C
      nf_status = NF_OPEN(filename,NF_NOWRITE,nf_fid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'NF_OPEN ', filename
      endif

      nf_status=NF_INQ_UNLIMDIM(nf_fid,nf_vid)

      if(nf_status.ne.NF_NOERR) then
         print *, NF_STRERROR(nf_status)
      endif

      nf_status=NF_INQ_DIMLEN(nf_fid,nf_vid,ntbg)

      if(nf_status.ne.NF_NOERR) then
         print *, NF_STRERROR(nf_status)
      endif
      mtbg=ntbg

      nf_status = NF_INQ_VARID(nf_fid,'model',nf_vid)
      if(nf_status.ne.NF_NOERR) then
         print *, NF_STRERROR(nf_status)
         print *,'in var model'
      endif
      nf_status = NF_GET_VAR_TEXT(nf_fid,nf_vid,model)
      if(nf_status.ne.NF_NOERR) then
         print *, NF_STRERROR(nf_status)
         print *,'in NF_GET_VAR_ model '
      endif
      nf_status=NF_INQ_VARID(nf_fid,'valtimeMINUSreftime',nf_vid)
      if(nf_status.ne.NF_NOERR) then
         print *, NF_STRERROR(nf_status)
         print *,'in NF_GET_VAR_ model '
      endif
      nf_status=NF_GET_VARA_INT(nf_fid,nf_vid,1,ntbg,ivaltimes)
      if(nf_status.ne.NF_NOERR) then
         print *, NF_STRERROR(nf_status)
         print *,'in NF_GET_VAR_ model '
      endif
      
      

      nf_status = nf_close(nf_fid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'nf_close'
      endif

      return
      end

      subroutine get_sbn_dims(path,fname,nxbg,nybg,nzbg,mtbg)
      implicit none
      include 'netcdf.inc'
      integer slen, nf_status,nf_fid, i, istat
      character*(*) path, fname
      character*100 cdfname
      integer ncid,nxbg,nybg,nzbg(5),ntbg , mtbg
      integer ntp, nvdim, nvs, lenstr, ndsize
      character*31 dummy
      integer id_fields(5), vdims(10)
      data id_fields/1,4,7,10,13/
      common /conus211/ntbg
      character*13 fname9_to_wfo_fname13, fname13
C
C  Fill all dimension values
C
C
C  Open netcdf File for reading
C
C
C  Open netcdf File for reading
C
      fname13=fname9_to_wfo_fname13(fname)

      call s_len(path,slen)
      cdfname=path(1:slen)//'/'//fname13



      nf_status = NF_OPEN(cdfname,NF_NOWRITE,nf_fid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'NF_OPEN rucsbn'
      endif

      mtbg=ntbg

cc      istat=NF_INQ_VARID(ncid,'valtimeMINUSreftime            ',i)
cc      istat=NF_GET_VARA_INT(ncid,i,1,ntbg,ivaltimes)
cc      print *, ivaltimes
      do i=1,5
        call NCVINQ(nf_fid,id_fields(i),dummy,ntp,nvdim,vdims,nvs,istat)

        call NCDINQ(nf_fid,vdims(1),dummy,nxbg,nf_status)
c        print *,'ndsize = ', ndsize
        call NCDINQ(nf_fid,vdims(2),dummy,nybg,nf_status)
c        print *,'ndsize = ', ndsize
        call NCDINQ(nf_fid,vdims(3),dummy,nzbg(i),nf_status)
c        print *,'ndsize = ', ndsize
cc        call ncdinq(nf_fid,vdims(4),dummy,ntbg,nf_status)
c        print *,'ndsize = ', ndsize
        
c        print*, 'ntp = ',ntp
c        print*, 'nvdim = ',nvdim
c        print*, 'vdims = ',vdims
c        print*, 'nvs = ',nvs
      enddo
c      stop
      nf_status = nf_close(nf_fid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'nf_close'
      endif
      return 

      end
C
C
      subroutine read_conus_211(path,fname,af,nx,ny,nz,
     .     nxbg,nybg,nzbg,ntbg,pr,ht,tp,sh,uw,vw,
     .     pr_sfc,uw_sfc,vw_sfc,sh_sfc,tp_sfc,mslp
     .     ,gproj,istatus)

c
      implicit none
c
      include 'netcdf.inc'
      include 'bgdata.inc'

      integer ncid, lenstr, ntp, nvdim, nvs, ndsize
c
      integer nx,ny,nz
      integer nxbg,nybg,nzbg(5),ntbg
      
c
      integer rcode,ivaltimes(ntbg)
c
c *** Netcdf arrays.
c
      integer nzbg1,nzbg2
      parameter(nzbg1=19,nzbg2=20)

      

      real*4 htn(nxbg,nybg,nzbg1),
     .       rhn(nxbg,nybg,nzbg2),
     .       tpn(nxbg,nybg,nzbg2),
     .       uwn(nxbg,nybg,nzbg2),
     .       vwn(nxbg,nybg,nzbg2), 
     .       mslpn(nxbg,nybg),
     .       pr_sfcn(nxbg,nybg)

      real   pr_sfc(nx,ny),uw_sfc(nx,ny),vw_sfc(nx,ny)
     +     ,sh_sfc(nx,ny),tp_sfc(nx,ny),mslp(nx,ny)

c
      real prn(19)
      data prn/1000.,950.,900.,850.,800.,750.,700.,650.,600.,550.,
     .               500.,450.,400.,350.,300.,250.,200.,150.,100./
c
c *** Output arrays.
c
      real*4 pr(nx,ny,nz),
     .       ht(nx,ny,nz),
     .       tp(nx,ny,nz),
     .       sh(nx,ny,nz),
     .       uw(nx,ny,nz),
     .       vw(nx,ny,nz)
c
      real*4 lci(nx,ny),lcj(nx,ny),
     .       lat(nx,ny),lon(nx,ny),
     .       angle(nx,ny)
c
      integer start(10),count(10)
      integer vdims(10) 
      character*31 dummy
c
      integer i,j,k,n,ip,jp,ii,jj,kp1,it,istatus,slen
c
      character*(*) path
      character*9   fname,oldfname,model
      character*13  fname13,fname9_to_wfo_fname13
      character*4   af
      character*2   gproj
      character*200 cdfname
c
c
      real*4 xe,esat,mrsat
      common /estab/esat(15000:45000)
c
c *** Common block variables for Lambert-conformal grid.
c
      integer nx_lc,ny_lc,nz_lc  !No. of LC domain grid points
      real*4 lat1,lat2,lon0,       !Lambert-conformal std lat1, lat, lon
     .       sw(2),ne(2)           !SW lat, lon, NE lat, lon
      common /lcgrid/nx_lc,ny_lc,nz_lc,lat1,lat2,lon0,sw,ne
      integer nf_vid,nn
c
ccc      save htn,tpn,rhn,uwn,vwn,prn,oldfname
c_______________________________________________________________________________
c
c *** Open the netcdf file.
c
ccc      if (fname .ne. oldfname) then
      if(nxbg.lt.nx.and.nybg.lt.ny) then
         model='RUC'
      else
         model='ETA'
      endif


      istatus=0
      fname13=fname9_to_wfo_fname13(fname)

      call s_len(path,slen)
      cdfname=path(1:slen)//'/'//fname13
      
      rcode = NF_OPEN(cdfname,NF_NOWRITE,ncid)
      if(rcode.ne.NF_NOERR) then
         print *, NF_STRERROR(rcode)
         print *,'NF_OPEN ',cdfname
      endif

      read(af,'(i4)') nn

      rcode=NF_INQ_VARID(ncid,'valtimeMINUSreftime',nf_vid)
      if(rcode.ne.NF_NOERR) then
         print *, NF_STRERROR(rcode)
         print *,'in NF_GET_VAR_ model '
      endif
      rcode=NF_GET_VARA_INT(ncid,nf_vid,1,ntbg,ivaltimes)
      if(rcode.ne.NF_NOERR) then
         print *, NF_STRERROR(rcode)
         print *,'in NF_GET_VAR_ model '
      endif

      n=1
      do while(n.lt.ntbg.and.ivaltimes(n)/3600.ne. nn)
         n=n+1
      enddo
      if(ivaltimes(n)/3600.ne.nn) then
         print*,'ERROR: No record valid at time ',nn,af
         rcode= NF_CLOSE(ncid)
         goto 999
      endif
       

c
c ****** Read netcdf data.
c ****** Statements to fill htn.
c

      start(1)=1
      count(1)=nxbg
      start(2)=1
      count(2)=nybg
      start(3)=1
      count(3)=nzbg1
      start(4)=n
      count(4)=1

      call read_netcdf_real(ncid,'gh',nxbg*nybg*count(3),htn,start
     +     ,count,rcode)

c
c ****** Statements to fill rhn.                           
c

         start(1)=1
         count(1)=nxbg
         start(2)=1
         count(2)=nybg
         start(3)=1
         count(3)=nzbg2
         start(4)=n
         count(4)=1

         call read_netcdf_real(ncid,'rh',nxbg*nybg*count(3),rhn,start
     +     ,count,rcode)


c
c ****** Statements to fill tpn.                              
c
         start(1)=1
         count(1)=nxbg
         start(2)=1
         count(2)=nybg
         start(3)=1
         count(3)=nzbg2
         start(4)=n
         count(4)=1

         call read_netcdf_real(ncid,'t',nxbg*nybg*count(3),tpn,start
     +     ,count,rcode)


c
c ****** Statements to fill uwn.                           
c
         start(1)=1
         count(1)=nxbg
         start(2)=1
         count(2)=nybg
         start(3)=1
         count(3)=nzbg2
         start(4)=n
         count(4)=1

         call read_netcdf_real(ncid,'uw',nxbg*nybg*count(3),uwn,start
     +     ,count,rcode)


c
c ****** Statements to fill vwn.                           
c
         start(1)=1
         count(1)=nxbg
         start(2)=1
         count(2)=nybg
         start(3)=1
         count(3)=nzbg2
         start(4)=n
         count(4)=1

         call read_netcdf_real(ncid,'vw',nxbg*nybg*count(3),vwn,start
     +     ,count,rcode)
c
c get sfc pressure field
c
         start(1)=1
         count(1)=nxbg
         start(2)=1
         count(2)=nybg
         start(3)=1
         count(3)=1
         start(4)=n
         count(4)=1
      
         call read_netcdf_real(ncid,'p',nxbg*nybg,pr_sfcn,start
     +     ,count,rcode)

c
c get mslp (this field name differs from one model to the other)
c
         if(model.eq.'ETA') then
            call read_netcdf_real(ncid,'emsp',nxbg*nybg,mslpn
     +           ,start,count,rcode)
         else
            call read_netcdf_real(ncid,'mmsp',nxbg*nybg,mslpn
     +           ,start,count,rcode)
         endif



c
c *** Close netcdf file.
c
      rcode= NF_CLOSE(ncid)
c
ccc      endif

c
c *** Fill ouput arrays.
c *** Convert rh to sh.
c
      do k=1,nz
      do j=1,ny
      do i=1,nx
         pr(i,j,k)=prn(k)
         ht(i,j,k)=missingflag
         tp(i,j,k)=missingflag
         sh(i,j,k)=missingflag
         uw(i,j,k)=missingflag
         vw(i,j,k)=missingflag
      enddo
      enddo
      enddo
c         
c  For ruc the actual domain is smaller than the conus 211 projection
c  so nxbg and nybg are smaller than nx and ny
c
      if(model.eq.'RUC') then
         ip=13
         jp=4 
      else
         ip=0
         jp=0
      endif

      n=1
      istatus=0
      do k=1,19
         do j=1,nybg
            do i=1,nxbg
               ii=i+ip
               jj=j+jp
               kp1=k+1
               if (htn(i,j,k) .gt. -1000. .and. 
     .              htn(i,j,k) .lt. 99999. .and.
     .              tpn(i,j,k) .gt. 0. .and.
     .              tpn(i,j,k) .lt. missingflag .and. 
     .              rhn(i,j,k) .lt. 200 .and.
     .              uwn(i,j,k) .lt. 500 .and.
     .              vwn(i,j,k) .lt. 500) then
                  ht(ii,jj,k)=htn(i,j,k)
                  tp(ii,jj,k)=tpn(i,j,kp1)
                  sh(ii,jj,k)=rhn(i,j,kp1)
                  it=tp(ii,jj,k)*100
                  it=min(45000,max(15000,it))
                  xe=esat(it)
                  mrsat=0.00622*xe/(prn(k)-xe)
                  sh(ii,jj,k)=sh(ii,jj,k)*mrsat
                  sh(ii,jj,k)=sh(ii,jj,k)/(1.+sh(ii,jj,k))
                  uw(ii,jj,k)=uwn(i,j,kp1)
                  vw(ii,jj,k)=vwn(i,j,kp1)
                  istatus = 1
               endif
            enddo
         enddo
      enddo

     


      if(istatus .eq. 0) then
        print*, 'No valid data found for',fname, af
      else

         do j=1,nybg
            do i=1,nxbg
               ii=i+ip
               jj=j+jp
               if(tpn(i,j,1).lt.missingflag) then
                  tp_sfc(ii,jj)=tpn(i,j,1)
                  sh_sfc(ii,jj)=rhn(i,j,1)
                  it=int(tp_sfc(ii,jj)*100)
                  it=min(45000,max(15000,it))
                  xe=esat(it)
                  mrsat=0.00622*xe/(pr_sfcn(i,j)*0.01-xe)
                  sh_sfc(ii,jj)=sh_sfc(ii,jj)*mrsat
                  sh_sfc(ii,jj)=sh_sfc(ii,jj)/(1.+sh_sfc(ii,jj))
                  uw_sfc(ii,jj)=uwn(i,j,1)
                  vw_sfc(ii,jj)=vwn(i,j,1)
                  mslp(ii,jj)=mslpn(i,j)
                  pr_sfc(ii,jj)=pr_sfcn(i,j)
                  
                  istatus = 1
               endif
            enddo
         enddo
      endif


c
c *** Fill Lambert-conformal common block variables.
c
      gproj='LC'
      nx_lc=nx
      ny_lc=ny
      lat1=25.0
      lat2=25.0
      lon0=-95.0
      sw(1)=12.19
      sw(2)=-133.459
      ne(1)=57.29
      ne(2)=-49.3849
c
c *** Convert ruc winds from grid north to true north.
c
cc      do j=1,ny
cc      do i=1,nx
cc         lci(i,j)=float(i)
cc         lcj(i,j)=float(j)
cc      enddo
cc      enddo
cc      call lcij_2_latlon(nx*ny,lci,lcj,lat,lon)
c
cc      call uvgrid_to_uvtrue_a(uw,vw,lon,lon0,nx,ny,nz,angle)
c
cc      oldfname=fname
      if(0.eq.1) then
 900     print*,'ERROR: bad dimension specified in netcdf file'
         print*, (count(i),i=1,4)
         istatus=-1
      endif
 999  return
      end
