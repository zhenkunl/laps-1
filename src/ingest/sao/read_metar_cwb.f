      subroutine read_metar_cwb( 
     &     filename, maxSkyCover, recNum, altimeter,
     &     autoStationType, dewpoint, dpFromTenths, elevation,
     &     latitude, longitude, maxTemp24Hour, minTemp24Hour,
     &     precip1Hour, precip24Hour, precip3Hour, precip6Hour,
     &     presWeather, pressChange3Hour, pressChangeChar,
     &     reportType, seaLevelPress, skyCover, skyLayerBase,
     &     snowCover, stationName, tempFromTenths, temperature,
     &     timeObs, visibility, windDir, windGust, windSpeed, wmoId,
     &     badflag, istatus )

      implicit none

      integer maxSkyCover, recNum
 
      character*6  autoStationType(recNum)
      character*25 presWeather(recNum)
      character*6  reportType(recNum)
      character*8  skyCover( maxSkyCover, recNum)
      character*5  stationName(recNum)

      integer  pressChangeChar(recNum), wmoId(recNum)
      integer  istatus

      double precision  timeObs(recNum)

      real  altimeter(recNum), dewpoint(recNum), dpFromTenths(recNum)
      real  elevation(recNum), latitude(recNum), longitude(recNum)
      real  maxTemp24Hour(recNum), minTemp24Hour(recNum)
      real  precip1Hour(recNum), precip24Hour(recNum)
      real  precip3Hour(recNum), precip6Hour(recNum)
      real  pressChange3Hour(recNum), seaLevelPress(recNum)
      real  skyLayerBase( maxSkyCover, recNum), snowCover(recNum)
      real  tempFromTenths(recNum), temperature(recNum)
      real  visibility(recNum), windDir(recNum), windGust(recNum)
      real  windSpeed(recNum)
      real  badflag

      integer recNumm
      parameter ( recNumm=150 )

      integer windSpeedQua(recNumm), windGustQua(recNumm)
      integer temperatureQua(recNumm), dewpointQua(recNumm)
      integer altimeterQua(recNumm)
      integer i, j, n, i4time

      character*(*) filename
      character*2  yy(recNumm), m1(recNumm), dd(recNumm)
      character*2  hh(recNumm), m2(recNumm)
      character*10 time(recNumm)
      character*9  a10_to_a9

      istatus= 0

      open ( 1, file=filename, status='old', err=1000 )
      
      istatus= 1

      n= 0
      do j= 1,recNum
         read ( 1, 10, end=99, err=999 )
     *   hh(j), m2(j), stationName(j), latitude(j),
     *   longitude(j), windDir(j), windSpeed(j), windSpeedQua(j),
     *   windGust(j), windGustQua(j), visibility(j), presWeather(j),
     *   ( skyCover(i,j), skyLayerBase(i,j), i=1,10 ), temperature(j),
     *   temperatureQua(j), dewpoint(j), dewpointQua(j), altimeter(j),
     *   altimeterQua(j), precip1Hour(j), yy(j), m1(j), dd(j)
         n= n+1
      enddo
10    format( 2a2, a4, 2f5.2, 2f5.0, i1, f5.0, i1, 2x, f5.0, 5x, a2,
     *        10(a3,f5.0), 3(f5.0,i1), 10x, f5.3, 12x, 3a2 )

c      ----------       examing data quality and changing units       ---------
99    do j= 1,n

         if ( windSpeedQua(j) .ne. 1 )  windSpeed(j)= badflag
         if ( windGustQua(j) .ne. 1 )  windGust(j)= badflag
         if ( visibility(j) .eq. -9999. )  visibility(j)= badflag
         if ( precip1Hour(j) .eq. -9.999 )  precip1Hour(j)= 0.
         if ( presWeather(j) .eq. '-9' )  presWeather(j)= '  '

         if ( temperatureQua(j) .eq. 1 )  then
               temperature(j)= temperature(j) +273.15
            else
               temperature(j)= badflag
         endif

         if ( dewpointQua(j) .eq. 1 )  then
               dewpoint(j)= dewpoint(j) +273.15
            else
               dewpoint(j)= badflag
         endif

         if ( altimeterQua(j) .eq. 1 )  then
               altimeter(j)= altimeter(j) *100
            else
               altimeter(j)= badflag
         endif

         if ( yy(j)(1:1) .eq. ' ' )  yy(j)= '0'//yy(j)(2:2)
         if ( m1(j)(1:1) .eq. ' ' )  m1(j)= '0'//m1(j)(2:2)
         if ( dd(j)(1:1) .eq. ' ' )  dd(j)= '0'//dd(j)(2:2)
         time(j)= yy(j)//m1(j)//dd(j)//hh(j)//m2(j)
         call cv_asc_i4time( a10_to_a9(time(j),istatus), i4time )
         timeObs(j)= dble( i4time )

      enddo

      do 20 j= 1,n
      do 20 i= 1,maxSkyCover
         if ( skyCover(i,j) .eq. '-99' )  skyCover(i,j)= '   '
         if ( skyLayerBase(i,j) .eq. -9999. )  then
               skyLayerBase(i,j)= badflag
            else
               skyLayerBase(i,j)= skyLayerBase(i,j) *30
         endif
20    continue

      do j= 1,n
         autoStationType(j)= "UNK"
         reportType(j)= "METAR"

         pressChangeChar(j)= int(badflag) 
         wmoId(j)= int(badflag) 

         dpFromTenths(j)= badflag
         maxTemp24Hour(j)= badflag
         minTemp24Hour(j)= badflag  
         precip24Hour(j)= badflag
         precip3Hour(j)= badflag
         precip6Hour(j)= badflag
         pressChange3Hour(j)= badflag
         seaLevelPress(j)= badflag
         snowCover(j)= badflag
         tempFromTenths(j)= badflag
         wmoId(j)= badflag
      enddo
      go to 1000

999   do j= 1,n
         write(6,*)
     *   hh(j), m2(j), stationName(j), latitude(j), longitude(j), 
     *   windDir(j), windSpeed(j), windSpeedQua(j),
     *   windGust(j), windGustQua(j), visibility(j), presWeather(j),
     *   ( skyCover(i,j), skyLayerBase(i,j), i=1,10), temperature(j),
     *   temperatureQua(j), dewpoint(j), dewpointQua(j), altimeter(j),
     *   altimeterQua(j), precip1Hour(j), yy(j), m1(j), dd(j), hh(j),
     *   m2(j), time(j), timeObs(j)
      enddo
      write(6,*)
     *      autoStationType, reportType,
     *      pressChangeChar, wmoId,    
     *      dpFromTenths, maxTemp24Hour, minTemp24Hour,
     *      precip24Hour, precip3Hour, precip6Hour, pressChange3Hour,
     *      seaLevelPress, snowCover, tempFromTenths, wmoId

1000  return
      end
