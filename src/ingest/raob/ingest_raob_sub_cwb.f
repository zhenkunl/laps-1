      subroutine get_raob_data_cwb ( i4time_sys, ilaps_cycle_time,
     ~             nx_l, ny_l, i4time_raob_earliest, i4time_raob_latest,
     ~             a9time, filename, istatus )

      integer   loopNum, levelNum  
      parameter ( loopNum=20, levelNum=100 )

      character*(*)  filename
      character*9    a9time(loopNum), a10_to_a9
      character*3    reportFlag
      character*2    yy, mo, dd, hh, mn, flag
      character*10   time

      real  lat_a(nx_l,ny_l), lon_a(nx_l,ny_l), topo_a(nx_l,ny_l)
      real  elevationDummy, latitudeDummy, longitudeDummy
      real  elevation(loopNum), latitude(loopNum), longitude(loopNum)
      real  pressure(loopNum,levelNum), height(loopNum,levelNum)
      real  temperature(loopNum,levelNum)
      real  tempDewDiff(loopNum,levelNum), dewpoint(loopNum,levelNum)
      real  windDir(loopNum,levelNum), windSpeed(loopNum,levelNum)

      integer recNum, inNum, jumpNum, logicRecNum, wmoIdDummy
      integer wmoId(loopNum), layerNum(loopNum)
      integer heightQua(loopNum,levelNum),dewpointQua(loopNum,levelNum)       
      integer temperatureQua(loopNum,levelNum),windQua(loopNum,levelNum)

      integer  d(12)
      data     d / 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 /

      call get_r_missing_data(r_missing_data,istatus)
      if ( istatus .ne. 1 ) then
         write (6,*) ' Error getting r_missing_data'
         return
      endif

      recNum= 0
      inNum= 0        ! inNum : the record number within time window
      istatus= 0

      open ( 1, file=filename, status='old', err=1000 )

      istatus= 1

      do i= 1,loopNum
         read (1,5,end=99,err=19) reportFlag, wmoIdDummy,elevationDummy,      
     ~                            latitudeDummy, longitudeDummy,
     ~                            iy, m1, id, ih, m2, logicRecNum
5        format ( a3, i5, f4.0, 2f5.2, 2x, 5i2, i3 )

         if ( reportFlag .ne. '*11' )  then
            write (6,*) 
     ~          ' Error reading sounding data of identification -reject'
	    write (6,*) reportFlag, wmoIdDummy
            go to 40
         endif

c               ------ creat a9time in yydddhhmm format ------
         if ( m1 .eq. 2  .and.  mod(iy,4) .eq. 0 )  d(m1)= d(m1) +1
	  
         if ( m2 .ne. -9 )  then   ! minus 30 mins to obtain the time in the air
            m2= m2 -30

            if ( m2 .lt. 0 )  then
               m2= m2 +60
               ih= ih -1

               if ( ih .lt. 0 )  then
                  ih= 23
                  id= id -1

                  if ( id .lt. 1 )  then
                     id= d(m1)
                     m1= m1 -1
                         
                     if ( m1 .lt. 1 )  then
                        m1= 12
                        iy= iy -1
                     endif
                  endif
               endif
            endif

         else         ! 00:-9 23:-9 12:-9 11:-9 -> l2:00 as the time in the air
            m2= 0
	    if ( ih .eq. 11  .or.  ih .eq. 23 )  ih= ih +1

            if ( ih .ge. 24 )  then
               ih= 0
               id= id +1

               if ( id .gt. d(m1) )  then
                  id= 1
                  m1= m1 +1
                      
                  if ( m1 .gt. 12 )  then
                     m1= 1
                     iy= iy +1
                  endif
               endif
            endif

         endif
            
         call i2a ( iy, yy )
         call i2a ( m1, mo )
         call i2a ( id, dd )
         call i2a ( ih, hh )
         call i2a ( m2, mn )

         time= yy//mo//dd//hh//mn
         a9time(i)= a10_to_a9(time,istatus)
         call cv_asc_i4time( a9time(i), i4time_raob )

c          ----------    test if raob is within time window    ----------
         if ( i4time_raob .ne. 0 ) then    
            if ( i4time_raob .ge. i4time_raob_earliest .and.
     ~           i4time_raob .le. i4time_raob_latest )  then
	       write (6,*) reportFlag, wmoIdDummy, elevationDummy,
     ~                     latitudeDummy, longitudeDummy,
     ~                     yy, mo, dd, hh, mn, logicRecNum,
     ~                     ' Inside time window'
	       inNum= inNum +1

               wmoId(inNum)= wmoIdDummy
	       elevation(inNum)= elevationDummy
	       latitude(inNum)= latitudeDummy
	       longitude(inNum)= longitudeDummy

               layerNum(inNum)= logicRecNum -2
               do j= 1,layerNum(inNum)
                  read (1,15,err=9,end=99) pressure(inNum,j),
     ~              height(inNum,j), heightQua(inNum,j),      
     ~              temperature(inNum,j), temperatureQua(inNum,j),        
     ~              tempDewDiff(inNum,j), dewpointQua(inNum,j),
     ~              windDir(inNum,j),windSpeed(inNum,j),windQua(inNum,j)      
	          go to 10

9                 write (6,*)' Error reading variables of sounding data'
                  do k= 1,j
                     write (6,*) pressure(inNum,k),
     ~                    height(inNum,k), heightQua(inNum,k),       
     ~                    temperature(inNum,k), temperatureQua(inNum,k),
     ~                    tempDewDiff(inNum,k), dewpointQua(inNum,k),
     ~                    windDir(inNum,k), windSpeed(inNum,k),
     ~                    windQua(inNum,k)
                  enddo
10             enddo
15             format ( 2x, f5.1, f5.0, i2, 2(f4.1,i2), 2f3.0, i2 )

               read (1,*)
    	       goto 50

            else
	       write (6,*) reportFlag, wmoIdDummy, elevationDummy,
     ~                     latitudeDummy, longitudeDummy,
     ~                     yy, mo, dd, hh, mn, logicRecNum,
     ~                     ' Outside time window -reject'
    	       goto 40

	    endif
         endif

19       write (6,*) ' Error reading sounding codes of stations -reject'
	 write (6,*) reportFlag, wmoIdDummy,
     ~               elevationDummy, latitudeDummy, longitudeDummy,
     ~               iy, m1, id, ih, m2, logicRecNum
	 do k= 1,levelNum
            read (1,'(a2)') flag
	    if ( flag .eq. '25' )  go to 50
	 enddo

40       jumpNum= logicRecNum -1
         do 41 k= 1,jumpNum
41          read (1,*) 

50       recNum= recNum +1
      enddo

c      ----------       examing data quality and changing units       ---------
99    do 100 i= 1,inNum
         if ( elevation(i) .eq. -999. )  elevation(i)= r_missing_data

      do 100 j= 1,layerNum(i)

         if ( pressure(i,j) .eq. -999. )  pressure(i,j)= r_missing_data
         if ( heightQua(i,j) .ne. 1 )  height(i,j)= r_missing_data
         if ( temperatureQua(i,j).ne.1 ) temperature(i,j)=r_missing_data

         if ( temperatureQua(i,j).eq.1 .and. dewpointQua(i,j).eq.1 )then
               dewpoint(i,j)= temperature(i,j) -tempDewDiff(i,j)
            else
               dewpoint(i,j)= r_missing_data
         endif

         if ( windQua(i,j) .ne. 1 )  then
            windDir(i,j)= r_missing_data
            windSpeed(i,j)= r_missing_data
         endif
100   continue

      do 900 i= 1,inNum
!        write (11,*) wmoId(i), elevation(i), latitude(i), longitude(i),
!    ~                a9time(i), layerNum(i)

         write(6,511)
     1             wmoId(i),layerNum(i)
     1            ,latitude(i),longitude(i),elevation(i)
     1            ,'     '             ! Station name (if known)       
     1            ,a9time_raob,'RAOB'
  511    format(i12,i12,f11.4,f15.4,f15.0,1x,a5,3x,a9,1x,a8)

         do 900 j= 1,layerNum(i)
            write (11,*) height(i,j), pressure(i,j), temperature(i,j),
     ~                   dewpoint(i,j), windDir(i,j), windSpeed(i,j)
900   continue

      write (6,*) ' found', inNum, 'stations within time window in',       
     ~            recNum, 'raob stations'

1000  return
      end



      subroutine  i2a (ii,aa)

      character*2  aa
      integer      ii

      if ( ii .lt. 10 )  then
         write (aa,'(a1,i1)') '0',ii
      else
         write (aa,'(i2)') ii
      endif

      return
      end
