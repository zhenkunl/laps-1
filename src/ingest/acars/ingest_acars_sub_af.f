
      subroutine get_acars_afwa(i4time_sys,ilaps_cycle_time
     1                                    ,NX_L,NY_L
     1                                    ,filename,istatus)

      character*(*) filename

!.............................................................................

      character*6 C6_A1ACID
      character*9 a9_timeObs,a9_recptTime 
!     character*7 c7_skycover
      real*4 lat_a(NX_L,NY_L)
      real*4 lon_a(NX_L,NY_L)
      real*4 topo_a(NX_L,NY_L)
      real*4 latitude,longitude

!............................................................................

      open(11,file=filename,status='old')

      call get_domain_perimeter(NX_L,NY_L,'nest7grid',lat_a,lon_a, 
     1            topo_a,1.0,rnorth,south,east,west,istatus)
      if(istatus .ne. 1)then
          write(6,*)' Error in get_laps_perimeter'
          return
      endif
  
      i = 0

      do while (.true.)

          read(11,101,err=890,end=999) !    NAME             UNITS & FACTOR
     1         I_A1CYCC,                       
     1         I_A1TYPE,
     1         I_A1DPD,
     1         I_A1GWC,
     1         I_A1JUL,                ! JULIAN HOUR          HR since 673650000
     1         I_A1MIN,                ! TIME-REPORT-MINUTES
     1         I_A1LAT,                ! LATITUDE             DEG * 100
     1         I_A1LON,                ! LONGITUDE            DEG * -100 
     1         I_A1KIND,
     1         I_A1ALT,                ! FLIGHT-ALT (true)    Meters MSL 
     1         I_A1PLA,
     1         I_A1DVAL,
     1         I_A1HOLM,
     1         I_A1FLTP,               ! TEMPERATURE          KELVINS * 10
     1         I_A1WD,                 ! WIND-DIRECTION       DEG
     1         I_A1WFLS,               ! WIND-SPEED           M/S * 10
     1         C6_A1ACID 
 101      format(16(i9,2x),a6)

          i = i + 1

          write(6,*)
          write(6,*)' acars #',i

          latitude  =  float(I_A1LAT)/100.
          longitude = -float(I_A1LON)/100.
          altitude  =  I_A1ALT

          write(6,*)' location = '
     1             ,latitude,longitude,altitude

          if(latitude  .le. rnorth .and. latitude  .ge. south .and.
     1       longitude .ge. west   .and. longitude .le. east      
     1                                                             )then       
              continue
          else ! Outside lat/lon perimeter - reject
              write(6,*)' lat/lon - reject'       
!    1                 ,latitude,longitude
              goto 900
          endif

          if(altitude .gt. 20000.)then
              write(6,*)' Altitude is suspect - reject',altitude
              goto 900
          endif

!         if(abs(timeObs)      .lt. 3d9       .and.
!    1       abs(timereceived) .lt. 3d9              )then
!             call c_time2fname(nint(timeObs),a9_timeObs)
!             call c_time2fname(nint(timereceived),a9_recptTime)
!         else
!             write(6,*)' Bad observation time - reject'       
!    1                   ,timeObs,timereceived
!             goto 900
!         endif

!         I_A1JUL is number of hours since Dec 31, 1967 at 00z
!         This is converted to i4time, number of sec since Jan 1, 1960 at 00z
          i4time_hr  = I_A1JUL * 3600 + (8*365 - 1 - 2) * 86400
          i4time_min = I_A1MIN*60
          i4time_ob  = i4time_hr + i4time_min

          call make_fnam_lp(i4time_ob,a9_timeObs,istatus)
          if(istatus .ne. 1)goto900

          a9_recptTime = '         '

!         call cv_asc_i4time(a9_timeObs,i4time_ob)

          i4_resid = abs(i4time_ob - i4time_sys)
          if(i4_resid .gt. (ilaps_cycle_time / 2) )then ! outside time window
              write(6,*)' time - reject '
     1           ,a9_timeObs,i4_resid,ilaps_cycle_time / 2
              goto 900        
          endif

          write(6,1)a9_timeObs,a9_recptTime 
          write(11,1)a9_timeObs,a9_recptTime 
 1        format(' Time - prp/rcvd:'/1x,a9,2x,a9) 

          write(6,2)latitude,longitude,altitude
          write(11,2)latitude,longitude,altitude
 2        format(' Lat, lon, altitude'/f8.3,f10.3,f8.0)  

!         Test for bad winds
!         if(char(dataDescriptor) .eq. 'X')then
!           if(char(errorType) .eq. 'W' .or. 
!    1         char(errorType) .eq. 'B'                         )then
!             write(6,*)' QC flag is bad - reject '
!    1                 ,char(dataDescriptor),char(errorType)
!             goto 850
!           endif
!         endif

          windSpeed = float(I_A1WFLS) / 10.
          windDIR = I_A1WD

          if(abs(windSpeed) .gt. 250. .or. windDir .gt. 360.)then
              write(6,*)' wind is suspect - reject',windDir,windSpeed

          else ! write out valid wind
              write(6,3)int(windDir),windSpeed
              write(11,3)int(windDir),windSpeed
 3            format(' Wind:'/' ', i3, ' deg @ ', f6.1, ' m/s')

          endif

          temperature = float(I_A1FLTP)/10.

 850      if(abs(temperature) .lt. 400.)then
              write(6,13)temperature
              write(11,13)temperature
 13           format(' Temp:'/1x,f10.1)
       
          else
              write(6,*)' Temperature is suspect - reject'
     1                , temperature

          endif

!         if(waterVaporMR .ge. 0. .and. 
!    1       waterVaporMR .le. 100.)then
!             write(6,23)waterVaporMR
!             write(11,23)waterVaporMR
!23           format(' MixR:'/1x,f10.3)

!         else
!             write(6,*)' water vapor rejected: ',waterVaporMR
!
!         endif

          go to 900

 890      write(6,*)' Warning: read error'

 900  enddo ! read line of AFWA file

!............................................................................

 999  write(6,*)' End of AFWA file detected'
      istatus = 1
      return
      end
