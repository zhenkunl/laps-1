
      subroutine get_raob_data(
     1                         i4time_sys,ilaps_cycle_time,NX_L,NY_L
     1                        ,i4time_raob_earliest,i4time_raob_latest       
     1                        ,filename
     1                        ,istatus)

      character*170 filename

!.............................................................................

      include 'netcdf.inc'
      integer mTropNum, mWndNum, manLevel, recNum, sigTLevel,
     +     sigWLevel,staNameLen, nf_fid, nf_vid, nf_status,
     +     nlvl_out

C
C  Open netcdf File for reading
C
      nf_status = NF_OPEN(filename,NF_NOWRITE,nf_fid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'NF_OPEN ',filename
      endif
C
C  Fill all dimension values
C
C
C Get size of mTropNum
C
      nf_status = NF_INQ_DIMID(nf_fid,'mTropNum',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim mTropNum'
      endif
      nf_status = NF_INQ_DIMLEN(nf_fid,nf_vid,mTropNum)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim mTropNum'
      endif
C
C Get size of mWndNum
C
      nf_status = NF_INQ_DIMID(nf_fid,'mWndNum',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim mWndNum'
      endif
      nf_status = NF_INQ_DIMLEN(nf_fid,nf_vid,mWndNum)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim mWndNum'
      endif
C
C Get size of manLevel
C
      nf_status = NF_INQ_DIMID(nf_fid,'manLevel',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim manLevel'
      endif
      nf_status = NF_INQ_DIMLEN(nf_fid,nf_vid,manLevel)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim manLevel'
      endif
C
C Get size of recNum
C
      nf_status = NF_INQ_DIMID(nf_fid,'recNum',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim recNum'
      endif
      nf_status = NF_INQ_DIMLEN(nf_fid,nf_vid,recNum)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim recNum'
      endif
C
C Get size of sigTLevel
C
      nf_status = NF_INQ_DIMID(nf_fid,'sigTLevel',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim sigTLevel'
      endif
      nf_status = NF_INQ_DIMLEN(nf_fid,nf_vid,sigTLevel)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim sigTLevel'
      endif
C
C Get size of sigWLevel
C
      nf_status = NF_INQ_DIMID(nf_fid,'sigWLevel',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim sigWLevel'
      endif
      nf_status = NF_INQ_DIMLEN(nf_fid,nf_vid,sigWLevel)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim sigWLevel'
      endif
C
C Get size of staNameLen
C
      nf_status = NF_INQ_DIMID(nf_fid,'staNameLen',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim staNameLen'
      endif
      nf_status = NF_INQ_DIMLEN(nf_fid,nf_vid,staNameLen)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'dim staNameLen'
      endif

      nlvl_out = manLevel + sigTLevel + sigWLevel
      call main_sub(nf_fid, mTropNum, mWndNum, manLevel, recNum,
     +     sigTLevel, sigWLevel, staNameLen, nlvl_out
!.............................................................................
     1                        ,i4time_sys,ilaps_cycle_time,NX_L,NY_L
     1                        ,i4time_raob_earliest,i4time_raob_latest       
     1                        ,istatus)


      return
!.............................................................................
      end
C
C
      subroutine main_sub(nf_fid, mTropNum, mWndNum, manLevel, recNum,
     +     sigTLevel, sigWLevel, staNameLen, nlvl_out
!.............................................................................
     1                        ,i4time_sys,ilaps_cycle_time,NX_L,NY_L
     1                        ,i4time_raob_earliest,i4time_raob_latest       
     1                        ,istatus)
!.............................................................................

      include 'netcdf.inc'
      integer mTropNum, mWndNum, manLevel, recNum, sigTLevel,
     +     sigWLevel,staNameLen, nlvl_out, nf_fid, nf_vid, nf_status
      integer numMand(recNum), numMwnd(recNum), numSigT(recNum),
     +     numSigW(recNum), numTrop(recNum), sondTyp(recNum),
     +     wmoStaNum(recNum)
      real htMan( manLevel, recNum), htSigW( sigWLevel, recNum),
     +     prMan( manLevel, recNum), prMaxW( mWndNum, recNum),
     +     prSigT( sigTLevel, recNum), prTrop( mTropNum, recNum),
     +     staElev(recNum), staLat(recNum), staLon(recNum), tdMan(
     +     manLevel, recNum), tdSigT( sigTLevel, recNum), tdTrop(
     +     mTropNum, recNum), tpMan( manLevel, recNum), tpSigT(
     +     sigTLevel, recNum), tpTrop( mTropNum, recNum), wdMan(
     +     manLevel, recNum), wdMaxW( mWndNum, recNum), wdSigW(
     +     sigWLevel, recNum), wdTrop( mTropNum, recNum), wsMan(
     +     manLevel, recNum), wsMaxW( mWndNum, recNum), wsSigW(
     +     sigWLevel, recNum), wsTrop( mTropNum, recNum)
      double precision relTime(recNum), synTime(recNum)
      character*6 staName(recNum)
      character   staNameFile(staNameLen,recNum)
!..............................................................................

      real*4 lat_a(NX_L,NY_L)
      real*4 lon_a(NX_L,NY_L)
      real*4 topo_a(NX_L,NY_L)

      character*9 a9time_syn, a9time_release, a9time_raob, a9time_sys

      call get_r_missing_data(r_missing_data,istatus)
      if (istatus .ne. 1) then
          write (6,*) 'Error getting r_missing_data'
          return
      endif
      call get_domain_perimeter(NX_L,NY_L,'nest7grid',lat_a,lon_a,  
     1            topo_a,1.0,rnorth,south,east,west,istatus)
      if(istatus .ne. 1)then
          write(6,*)' Error in get_domain_perimeter'
          return
      endif

!.............................................................................


      call read_netcdf(nf_fid, mTropNum, mWndNum, manLevel, recNum, 
     +     sigTLevel, sigWLevel, staNameLen, numMand, numMwnd, numSigT, 
     +     numSigW, 
     +     numTrop, sondTyp, wmoStaNum, htMan, htSigW, prMan, prMaxW, 
     +     prSigT, prTrop, staElev, staLat, staLon, tdMan, tdSigT, 
     +     tdTrop, tpMan, tpSigT, tpTrop, wdMan, wdMaxW, wdSigW, 
     +     wdTrop, wsMan, wsMaxW, wsSigW, wsTrop, relTime, synTime, 
     +     staNameFile, staName)
C
C The netcdf variables are filled - your code goes here
C
!     Write All Raobs to LAPS SND file

      r_nc_missing_data = 1e20

      n_snd = recNum

      do isnd = 1,n_snd

!         QC and write out the sounding
          i4time_raob = 0

          if(abs(syntime(isnd)) .lt. 1e10 .and.
     1       abs(syntime(isnd)) .gt.    0.      )then
              i4time_syn  = idint(syntime(isnd))+315619200
              i4time_raob = i4time_syn
          else
              i4time_syn = 0
          endif

          if(abs(reltime(isnd)) .lt. 1e10 .and.
     1       abs(reltime(isnd)) .gt.    0.      )then
              i4time_release = idint(reltime(isnd))+315619200

              i4time_diff = i4time_release - i4time_sys

              if(abs(i4time_diff) .gt. 20000)then
                  write(6,*)' Warning: i4time_release is not '
     1                     ,'consistent with i4time_diff'
     1                     ,i4time_release,i4time_sys
              endif

!             Correction for balloon rise time to mid-troposphere
              i4time_raob = i4time_release + 1800

          else
              i4time_release = 0
              i4time_diff = 0

          endif

          write(6,*)
          write(6,*)' Raob #',isnd,i4time_sys,i4time_release,i4time_diff       
     1                         ,i4time_syn

          call make_fnam_lp(i4time_sys    , a9time_sys    , istatus)
          call make_fnam_lp(i4time_release, a9time_release, istatus)
          call make_fnam_lp(i4time_syn    , a9time_syn    , istatus)
          call make_fnam_lp(i4time_raob   , a9time_raob   , istatus)

          write(6,*)' times - sys/release/syn/raob: '
     1             ,a9time_sys,' ',a9time_release,' '
     1             ,a9time_syn,' ',a9time_raob

          if(stalat(isnd) .ge. r_nc_missing_data)then
              write(6,*)' Missing first latitude',isnd
              goto 999
          endif

          if(stalon(isnd) .ge. r_nc_missing_data)then
              write(6,*)' Missing first longitude',isnd
              goto 999
          endif

          if(stalat(isnd) .le. rnorth .and. stalat(isnd) .ge. south 
     1                                .AND.      
     1       stalon(isnd) .ge. west   .and. stalon(isnd) .le. east      
     1                                                            )then       

!         if(.true.)then      ! for testing

              write(6,*)' Raob is inside domain lat/lon perimeter'
          else
              write(6,*)
     1            ' Outside domain lat/lon perimeter - reject'
              goto 999
          endif

          if(i4time_raob .ne. 0)then ! test window
              if(i4time_raob .ge. i4time_raob_earliest .and.
     1           i4time_raob .le. i4time_raob_latest)then
                  write(6,*)' Inside time window'
              else
                  write(6,*)' Outside time window - reject'
                  goto 999
              endif
          endif

          call sort_and_write(i4time_sys
     1                       ,recNum,isnd,r_missing_data,a9time_raob
     1                       ,wmostanum,staname,stalat,stalon,staelev
     1                       ,nummand,htman,prman,tpman,tdman      
     1                       ,wdman,wsman
     1                       ,numsigt,prsigt,tpsigt,tdsigt
     1                       ,numsigw,htsigw,wdsigw,wssigw,nlvl_out 
     1                       ,manLevel,sigTLevel,sigWLevel,istatus)

          go to 999

 998      write(6,*)' Error writing out RAOB'

 999      continue

      enddo ! i

      return
      end


      subroutine sort_and_write(i4time_sys
     1                       ,NREC,isnd,r_missing_data,a9time_raob
     1                       ,wmostanum,staname,stalat,stalon,staelev
     1                       ,nummand,htman,prman,tpman,tdman      
     1                       ,wdman,wsman
     1                       ,numsigt,prsigt,tpsigt,tdsigt
     1                       ,numsigw,htsigw,wdsigw,wssigw,nlvl_out
     1                       ,manLevel,sigTLevel,sigWLevel,istatus)

      integer     NLVL_OUT
      integer     manLevel
      integer     sigTLevel
      integer     sigWLevel
      INTEGER*4   wmoStaNum                      (NREC)
      CHARACTER*1 staName                        (6,NREC)
      REAL*4      staLat                         (NREC)
      REAL*4      staLon                         (NREC)
      REAL*4      staElev                        (NREC)

      INTEGER*4   numMand                        (NREC)
      REAL*4      prMan                          (manLevel ,NREC)
      REAL*4      htMan                          (manLevel ,NREC)
      REAL*4      tpMan                          (manLevel ,NREC)
      REAL*4      tdMan                          (manLevel ,NREC) ! Dwpt Dprs
      REAL*4      wdMan                          (manLevel ,NREC)
      REAL*4      wsMan                          (manLevel ,NREC)

      REAL*4      prMan_good                     (manLevel)
      REAL*4      htMan_good                     (manLevel)
      REAL*4      tpMan_good                     (manLevel)
      REAL*4      tdMan_good                     (manLevel)       ! Dwpt Dprs
      REAL*4      wdMan_good                     (manLevel)
      REAL*4      wsMan_good                     (manLevel)

      INTEGER*4   numsigt                        (NREC)
      REAL*4      prSigT                         (sigTLevel,NREC)
      REAL*4      tpSigT                         (sigTLevel,NREC)
      REAL*4      tdSigT                         (sigTLevel,NREC) ! Dwpt Dprs

      INTEGER*4   numsigw                        (NREC)
      REAL*4      htSigW                         (sigWLevel,NREC)
      REAL*4      wdSigW                         (sigWLevel,NREC)
      REAL*4      wsSigW                         (sigWLevel,NREC)

      integer*4   indx(NLVL_OUT)  
      character*9 a9time_out_sort                (NLVL_OUT)
      REAL*4      latout_sort                    (NLVL_OUT)
      REAL*4      lonout_sort                    (NLVL_OUT)
      REAL*4      prout                          (NLVL_OUT)
      REAL*4      prout_sort                     (NLVL_OUT)
      REAL*4      htout                          (NLVL_OUT)
      REAL*4      htout_sort                     (NLVL_OUT)
      REAL*4      tpout                          (NLVL_OUT)
      REAL*4      tpout_sort_c                   (NLVL_OUT)
      REAL*4      tpout_c_z                      (NLVL_OUT)
      REAL*4      tdout                          (NLVL_OUT)  ! Dewpoint Depress
      REAL*4      tdout_sort_c                   (NLVL_OUT)  ! Dewpoint Deg C
      REAL*4      tdout_c_z                      (NLVL_OUT)  ! Dewpoint Deg C
      REAL*4      wdout                          (NLVL_OUT)
      REAL*4      wdout_sort                     (NLVL_OUT)
      REAL*4      wsout                          (NLVL_OUT)
      REAL*4      wsout_sort                     (NLVL_OUT)

      real*4 k_to_c

      character*9 a9time_raob
      character*8 c8_obstype
      character*132 c_line

!     Generate info for Sorting/QC, write original mandatory data to log file
      write(6,*)
      n_good_levels = 0

      c8_obstype = 'RAOB'

      write(6,*)' Subroutine sort_and_write - initial mandatory data'       
      if(nummand(isnd) .le. manLevel)then
        do ilevel = 1,nummand(isnd)
          if(htman(ilevel,isnd) .lt. 90000. .and.
     1       htman(ilevel,isnd) .ge. staelev(isnd) )then ! valid height AGL
              n_good_levels = n_good_levels + 1
              write(6,*) htman(ilevel,isnd),prman(ilevel,isnd)
     1                  ,tpman(ilevel,isnd),tdman(ilevel,isnd)
     1                  ,wdman(ilevel,isnd),wsman(ilevel,isnd)

              htman_good(n_good_levels) = htman(ilevel,isnd)
              prman_good(n_good_levels) = prman(ilevel,isnd)
              tpman_good(n_good_levels) = tpman(ilevel,isnd)
              tdman_good(n_good_levels) = tdman(ilevel,isnd)
              wdman_good(n_good_levels) = wdman(ilevel,isnd)
              wsman_good(n_good_levels) = wsman(ilevel,isnd)
              indx(n_good_levels) = n_good_levels
          endif
        enddo
      else
        write(6,*)' Note: nummand(isnd) > manLevel'
     1                   ,nummand(isnd),manLevel      
      endif

      n_good_man = n_good_levels

!     Bubble sort the mandatory levels by height 
!     (this may not be all that essential given that underground 
!     levels have been filtered out)

 300  iswitch = 0
      do i = 2,n_good_man
          if(htman_good(indx(i)) .lt. htman_good(indx(i-1)))then
              izz = indx(i-1)
              indx(i-1) = indx(i)
              indx(i) = izz
              iswitch = 1
          endif
      enddo

      if(iswitch .eq. 1)go to 300

      do i = 1,n_good_man
          ilevel = indx(i)
          htout(i) = htman_good(ilevel)
          prout(i) = prman_good(ilevel)
          tpout(i) = tpman_good(ilevel)
          tdout(i) = tdman_good(ilevel)
          wdout(i) = wdman_good(ilevel)
          wsout(i) = wsman_good(ilevel)
      enddo

!     Generate best current sounding for subsequent use in height integration
      n_good_z = 0
      tdout_ref = 10.
      do i = 1,n_good_man
          if(abs(tpout(i)) .le. 500.)then ! good t value
              tpout_c_z(i) = k_to_c(tpout(i))
              n_good_z = n_good_z + 1

              if(abs(tdout(i)) .le. 500.)then ! good td value
                  tdout_c_z(i) = tpout_c_z(i) - tdout(i)
!                 tdout_c_z(i) = k_to_c(tdout(i))

                  tdout_ref = tdout(i)

              else ! generate approximate moisture value for height integration
                  tdout_c_z(i) = tpout_c_z(i) - 10.
!                 tdout_c_z(i) = tpout_c_z(i) - tdout_ref

              endif ! good td value
          endif ! good t value
      enddo ! i

      write(6,*)' Subroutine sort_and_write - sig wind data'       
      if(numsigw(isnd) .le. sigWLevel)then
        do ilevel = 1,numsigw(isnd)
          if(htsigw(ilevel,isnd) .lt. 90000. .and.
     1       htsigw(ilevel,isnd) .ne. 0.            )then
              n_good_levels = n_good_levels + 1
              write(6,*) htsigw(ilevel,isnd),r_missing_data
     1                  ,r_missing_data,r_missing_data
     1                  ,wdsigw(ilevel,isnd),wssigw(ilevel,isnd)

              indx(n_good_levels) = n_good_levels
              htout(n_good_levels) = htsigw(ilevel,isnd)
              prout(n_good_levels) = r_missing_data
              tpout(n_good_levels) = r_missing_data
              tdout(n_good_levels) = r_missing_data
              wdout(n_good_levels) = wdsigw(ilevel,isnd)
              wsout(n_good_levels) = wssigw(ilevel,isnd)
          endif
        enddo
      else
        write(6,*)' Note: numsigw(isnd) > sigWLevel'
     1                   ,numsigw(isnd),sigWLevel      
      endif

      write(6,*)' Subroutine sort_and_write - sig T data'       
      if(numsigt(isnd) .le. sigTLevel)then
        do ilevel = 1,numsigt(isnd)
          if(prsigt(ilevel,isnd) .lt. 2000. .and.
     1       prsigt(ilevel,isnd) .gt. 0.            )then

!           Attempt to calculate height based on good mandatory level data
            if(n_good_z .gt. 0)then
                ht_calc = z(prsigt(ilevel,isnd)
     1                     ,prout,tpout_c_z,tdout_c_z,n_good_z)

                if(nanf(ht_calc) .eq. 1)then
                    ht_calc = -1.0        ! flag value for invalid height
                endif

                if(ht_calc .ne. -1.0)then ! valid height returned
                    ht_calc = ht_calc + htout(1)

                    n_good_levels = n_good_levels + 1
                    write(6,*) ht_calc,prsigt(ilevel,isnd)
     1                        ,tpsigt(ilevel,isnd),tdsigt(ilevel,isnd)
     1                        ,r_missing_data,r_missing_data

                    indx(n_good_levels) = n_good_levels
                    htout(n_good_levels) = ht_calc
                    prout(n_good_levels) = prsigt(ilevel,isnd)
                    tpout(n_good_levels) = tpsigt(ilevel,isnd)
                    tdout(n_good_levels) = tdsigt(ilevel,isnd)
                    wdout(n_good_levels) = r_missing_data
                    wsout(n_good_levels) = r_missing_data
                endif
            endif
          endif
        enddo
      else
        write(6,*)' Note: numsigt(isnd) > sigTLevel'
     1                   ,numsigt(isnd),sigTLevel      
      endif

!     Bubble sort all the levels by height
      do i = 1,n_good_levels
          indx(i) = i
      enddo ! i

 400  iswitch = 0
      do i = 2,n_good_levels
          if(htout(indx(i)) .lt. htout(indx(i-1)))then
              izz = indx(i-1)
              indx(i-1) = indx(i)
              indx(i) = izz
              iswitch = 1
          endif
      enddo

      if(iswitch .eq. 1)go to 400
      
!     Detect and remove duplicate levels
      i = 2
      do while(i .le. n_good_levels)
          idupe = 0
          if(htout(indx(i)) .eq. htout(indx(i-1)))then          
              idupe = i
              write(6,*)' Remove duplicate ht level '
     1                  ,idupe,htout(indx(idupe))

          elseif( prout(indx(i)) .eq. prout(indx(i-1))
     1     .and.  prout(indx(i)) .ne. r_missing_data    )then          
              idupe_pr = 0

!             We would like to retain the mandatory report that also has winds
              if(wdout(indx(i)) .ne. r_missing_data)then
                  idupe_pr = i-1 ! Previous Sig T level can be removed
              elseif(wdout(indx(i-1)) .ne. r_missing_data)then
                  idupe_pr = i   ! Previous Sig T level can be removed
              endif
            
              write(6,*)' Duplicate pr level detected'
     1                  ,i,idupe_pr,prout(indx(i))

!             idupe = idupe_pr

          endif ! duplicate level

          if(idupe .gt. 0)then
              do j = idupe,n_good_levels-1
                htout(indx(j)) = htout(indx(j+1))
                prout(indx(j)) = prout(indx(j+1))
                tpout(indx(j)) = tpout(indx(j+1))
                tdout(indx(j)) = tdout(indx(j+1))
                wdout(indx(j)) = wdout(indx(j+1))
                wsout(indx(j)) = wsout(indx(j+1))
              enddo ! j
              n_good_levels = n_good_levels - 1
          endif
          i = i+1
      enddo ! i

      call open_ext(11,i4time_sys,'snd',istatus)

!     QC and convert units, T and Td are converted to deg C
      do i = 1,n_good_levels
          ilevel = indx(i)

          htout_sort(i) = htout(ilevel)
          prout_sort(i) = prout(ilevel)

          if(tpout(ilevel) .eq. 99999. .or.
     1       tpout(ilevel) .eq. r_missing_data     )then
              tpout_sort_c(i) = r_missing_data
          else
              tpout_sort_c(i) = k_to_c(tpout(ilevel))
          endif

          if(tdout(ilevel)   .eq. 99999. .or. 
     1       tpout_sort_c(i) .eq. r_missing_data)then       
              tdout_sort_c(i) = r_missing_data
          else
              tdout_sort_c(i) = k_to_c(tpout(ilevel)) 
     1                        - tdout(ilevel)      
          endif

          if(abs(wdout(ilevel)) .ge. 99999. .or.
     1       abs(wsout(ilevel)) .ge. 99999.)then
              wdout(ilevel) = r_missing_data
              wsout(ilevel) = r_missing_data
          endif

          wdout_sort(i) = wdout(ilevel)
          wsout_sort(i) = wsout(ilevel)

      enddo ! i

      latout_sort = stalat(isnd)      ! assign entire array for this sounding
      lonout_sort = stalon(isnd)      ! assign entire array for this sounding
      a9time_out_sort = a9time_raob   ! assign entire array for this sounding

      call write_snd  (11                                         ! I
     1                ,1,maxlvl,1                                 ! I
     1                ,wmostanum(isnd)                            ! I
     1                ,latout_sort,lonout_sort,staelev(isnd)      ! I
     1                ,staname(1,isnd),a9time_out_sort,c8_obstype ! I
     1                ,n_good_levels                              ! I
     1                ,htout_sort                                 ! I
     1                ,prout_sort                                 ! I
     1                ,tpout_sort_c                               ! I
     1                ,tdout_sort_c                               ! I
     1                ,wdout_sort                                 ! I
     1                ,wsout_sort                                 ! I
     1                ,istatus)                                   ! O

      return
      end

!.............................................................................
C
C  Subroutine to read the file "RAOB data : selected by ob time : time range from 887191200 to 887202000" 
C
      subroutine read_netcdf(nf_fid, mTropNum, mWndNum, manLevel, 
     +     recNum, sigTLevel, sigWLevel, staNameLen, numMand, numMwnd, 
     +     numSigT, numSigW, 
     +     numTrop, sondTyp, wmoStaNum, htMan, htSigW, 
     +     prMan, prMaxW, prSigT, prTrop, staElev, staLat, staLon, 
     +     tdMan, tdSigT, tdTrop, tpMan, tpSigT, tpTrop, wdMan, 
     +     wdMaxW, wdSigW, wdTrop, wsMan, wsMaxW, wsSigW, wsTrop, 
     +     relTime, synTime, staNameFile, staName)
C
      include 'netcdf.inc'
      integer mTropNum, mWndNum, manLevel, recNum, sigTLevel, 
     +     sigWLevel,staNameLen, nf_fid, nf_vid, nf_status
      integer numMand(recNum), numMwnd(recNum), numSigT(recNum),
     +     numSigW(recNum), numTrop(recNum), sondTyp(recNum),
     +     wmoStaNum(recNum)
      real htMan( manLevel, recNum), htSigW( sigWLevel, recNum),
     +     prMan( manLevel, recNum), prMaxW( mWndNum, recNum),
     +     prSigT( sigTLevel, recNum), prTrop( mTropNum, recNum),
     +     staElev(recNum), staLat(recNum), staLon(recNum), tdMan(
     +     manLevel, recNum), tdSigT( sigTLevel, recNum), tdTrop(
     +     mTropNum, recNum), tpMan( manLevel, recNum), tpSigT(
     +     sigTLevel, recNum), tpTrop( mTropNum, recNum), wdMan(
     +     manLevel, recNum), wdMaxW( mWndNum, recNum), wdSigW(
     +     sigWLevel, recNum), wdTrop( mTropNum, recNum), wsMan(
     +     manLevel, recNum), wsMaxW( mWndNum, recNum), wsSigW(
     +     sigWLevel, recNum), wsTrop( mTropNum, recNum)
      double precision relTime(recNum), synTime(recNum)
      character*6 staName(recNum), name
      character   staNameFile(staNameLen,recNum)


C   Variables of type REAL
C
C     Variable        NETCDF Long Name
C      htMan        "Geopotential - Mandatory level"
C
        nf_status = NF_INQ_VARID(nf_fid,'htMan',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var htMan'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,htMan)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var htMan'
      endif
C
C     Variable        NETCDF Long Name
C      htSigW       "Geopotential - Significant level wrt W"
C
        nf_status = NF_INQ_VARID(nf_fid,'htSigW',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var htSigW'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,htSigW)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var htSigW'
      endif
C
C     Variable        NETCDF Long Name
C      prMan        "Pressure - Mandatory level"
C
        nf_status = NF_INQ_VARID(nf_fid,'prMan',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var prMan'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,prMan)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var prMan'
      endif
C
C     Variable        NETCDF Long Name
C      prMaxW       "Pressure - Maximum wind level"
C
        nf_status = NF_INQ_VARID(nf_fid,'prMaxW',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var prMaxW'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,prMaxW)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var prMaxW'
      endif
C
C     Variable        NETCDF Long Name
C      prSigT       "Pressure - Significant level wrt T"
C
        nf_status = NF_INQ_VARID(nf_fid,'prSigT',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var prSigT'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,prSigT)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var prSigT'
      endif
C
C     Variable        NETCDF Long Name
C      prTrop       "Pressure - Tropopause level"
C
        nf_status = NF_INQ_VARID(nf_fid,'prTrop',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var prTrop'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,prTrop)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var prTrop'
      endif
C
C     Variable        NETCDF Long Name
C      staElev      "Station Elevation"
C
        nf_status = NF_INQ_VARID(nf_fid,'staElev',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var staElev'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,staElev)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var staElev'
      endif
C
C     Variable        NETCDF Long Name
C      staLat       "Station Latitude"
C
        nf_status = NF_INQ_VARID(nf_fid,'staLat',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var staLat'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,staLat)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var staLat'
      endif
C
C     Variable        NETCDF Long Name
C      staLon       "Station Longitude"
C
        nf_status = NF_INQ_VARID(nf_fid,'staLon',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var staLon'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,staLon)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var staLon'
      endif
C
C     Variable        NETCDF Long Name
C      tdMan        "Dew Point Depression - Mandatory level"
C
        nf_status = NF_INQ_VARID(nf_fid,'tdMan',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var tdMan'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,tdMan)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var tdMan'
      endif
C
C     Variable        NETCDF Long Name
C      tdSigT       "Dew Point Depression - Significant level wrt T"
C
        nf_status = NF_INQ_VARID(nf_fid,'tdSigT',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var tdSigT'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,tdSigT)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var tdSigT'
      endif
C
C     Variable        NETCDF Long Name
C      tdTrop       "Dew Point Depression - Tropopause level"
C
        nf_status = NF_INQ_VARID(nf_fid,'tdTrop',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var tdTrop'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,tdTrop)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var tdTrop'
      endif
C
C     Variable        NETCDF Long Name
C      tpMan        "Temperature - Mandatory level"
C
        nf_status = NF_INQ_VARID(nf_fid,'tpMan',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var tpMan'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,tpMan)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var tpMan'
      endif
C
C     Variable        NETCDF Long Name
C      tpSigT       "Temperature - Significant level wrt T"
C
        nf_status = NF_INQ_VARID(nf_fid,'tpSigT',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var tpSigT'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,tpSigT)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var tpSigT'
      endif
C
C     Variable        NETCDF Long Name
C      tpTrop       "Temperature - Tropopause level"
C
        nf_status = NF_INQ_VARID(nf_fid,'tpTrop',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var tpTrop'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,tpTrop)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var tpTrop'
      endif
C
C     Variable        NETCDF Long Name
C      wdMan        "Wind Direction - Mandatory level"
C
        nf_status = NF_INQ_VARID(nf_fid,'wdMan',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wdMan'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,wdMan)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wdMan'
      endif
C
C     Variable        NETCDF Long Name
C      wdMaxW       "Wind Direction - Maximum wind level"
C
        nf_status = NF_INQ_VARID(nf_fid,'wdMaxW',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wdMaxW'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,wdMaxW)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wdMaxW'
      endif
C
C     Variable        NETCDF Long Name
C      wdSigW       "Wind Direction - Significant level wrt W"
C
        nf_status = NF_INQ_VARID(nf_fid,'wdSigW',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wdSigW'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,wdSigW)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wdSigW'
      endif
C
C     Variable        NETCDF Long Name
C      wdTrop       "Wind Direction - Tropopause level"
C
        nf_status = NF_INQ_VARID(nf_fid,'wdTrop',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wdTrop'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,wdTrop)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wdTrop'
      endif
C
C     Variable        NETCDF Long Name
C      wsMan        "Wind Speed - Mandatory level"
C
        nf_status = NF_INQ_VARID(nf_fid,'wsMan',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wsMan'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,wsMan)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wsMan'
      endif
C
C     Variable        NETCDF Long Name
C      wsMaxW       "Wind Speed - Maximum wind level"
C
        nf_status = NF_INQ_VARID(nf_fid,'wsMaxW',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wsMaxW'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,wsMaxW)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wsMaxW'
      endif
C
C     Variable        NETCDF Long Name
C      wsSigW       "Wind Speed - Significant level wrt W"
C
        nf_status = NF_INQ_VARID(nf_fid,'wsSigW',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wsSigW'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,wsSigW)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wsSigW'
      endif
C
C     Variable        NETCDF Long Name
C      wsTrop       "Wind Speed - Tropopause level"
C
        nf_status = NF_INQ_VARID(nf_fid,'wsTrop',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wsTrop'
      endif
        nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,wsTrop)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wsTrop'
      endif

C   Variables of type INT
C
C
C     Variable        NETCDF Long Name
C      numMand      "Number of Mandatory Levels"
C
        nf_status = NF_INQ_VARID(nf_fid,'numMand',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var numMand'
      endif
        nf_status = NF_GET_VAR_INT(nf_fid,nf_vid,numMand)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var numMand'
      endif
C
C     Variable        NETCDF Long Name
C      numMwnd      "Number of Maximum Wind Levels"
C
        nf_status = NF_INQ_VARID(nf_fid,'numMwnd',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var numMwnd'
      endif
        nf_status = NF_GET_VAR_INT(nf_fid,nf_vid,numMwnd)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var numMwnd'
      endif
C
C     Variable        NETCDF Long Name
C      numSigT      "Number of Significant Levels wrt T"
C
        nf_status = NF_INQ_VARID(nf_fid,'numSigT',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var numSigT'
      endif
        nf_status = NF_GET_VAR_INT(nf_fid,nf_vid,numSigT)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var numSigT'
      endif
C
C     Variable        NETCDF Long Name
C      numSigW      "Number of Significant Levels wrt W"
C
        nf_status = NF_INQ_VARID(nf_fid,'numSigW',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var numSigW'
      endif
        nf_status = NF_GET_VAR_INT(nf_fid,nf_vid,numSigW)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var numSigW'
      endif
C
C     Variable        NETCDF Long Name
C      numTrop      "Number of Tropopause Levels"
C
        nf_status = NF_INQ_VARID(nf_fid,'numTrop',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var numTrop'
      endif
        nf_status = NF_GET_VAR_INT(nf_fid,nf_vid,numTrop)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var numTrop'
      endif
C
C     Variable        NETCDF Long Name
C      sondTyp      "Instrument Type"
C
        nf_status = NF_INQ_VARID(nf_fid,'sondTyp',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var sondTyp'
      endif
        nf_status = NF_GET_VAR_INT(nf_fid,nf_vid,sondTyp)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var sondTyp'
      endif
C
C     Variable        NETCDF Long Name
C      wmoStaNum    "WMO Station Number"
C
        nf_status = NF_INQ_VARID(nf_fid,'wmoStaNum',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wmoStaNum'
      endif
        nf_status = NF_GET_VAR_INT(nf_fid,nf_vid,wmoStaNum)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var wmoStaNum'
      endif

C   Variables of type DOUBLE
C
C
C     Variable        NETCDF Long Name
C      relTime      "Sounding Release Time"
C
        nf_status = NF_INQ_VARID(nf_fid,'relTime',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var relTime'
      endif
        nf_status = NF_GET_VAR_DOUBLE(nf_fid,nf_vid,relTime)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var relTime'
      endif
C
C     Variable        NETCDF Long Name
C      synTime      "Synoptic Time"
C
        nf_status = NF_INQ_VARID(nf_fid,'synTime',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var synTime'
      endif
        nf_status = NF_GET_VAR_DOUBLE(nf_fid,nf_vid,synTime)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var synTime'
      endif


C   Variables of type CHAR
C
C     Variable        NETCDF Long Name
C      staName      "Station Identifier"
C
      nf_status = NF_INQ_VARID(nf_fid,'staName',nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var staName'
      endif

      if (staNameLen .eq. 6) then  !read directly into staName variable
        nf_status = NF_GET_VAR_TEXT(nf_fid,nf_vid,staName)
        if(nf_status.ne.NF_NOERR) then
          print *, NF_STRERROR(nf_status)
          print *,'in var staName'
        endif
      else
        nf_status = NF_GET_VAR_TEXT(nf_fid,nf_vid,staNameFile)
        if(nf_status.ne.NF_NOERR) then
          print *, NF_STRERROR(nf_status)
          print *,'in var staName'
        endif

        do i = 1, recNum
          do j = 1, 6
            name(j:j) = staNameFile(j,i)
          enddo
          call filter_string(name)
          staName(i) = name
        enddo
      endif

      nf_status = nf_close(nf_fid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'nf_close'
      endif

      return
      end
