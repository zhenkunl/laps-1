
      function l_closest_time_i(wmoid,a9time_ob,nobs
     1                        ,i,i4time_sys,istatus)      

!     Determine if the ob time is the closest time for that station to systime

      logical l_closest_time_i

      character*9 a9time_ob(nobs)
      integer wmoid(nobs)
!     character*(*)wmoid(nobs)    ! Allows arbitrary variable type to compare

      i4_closest = 99999

      do j = 1,nobs
          if(wmoid(j) .eq. wmoid(i))then
!             Calculate time of station j
              call i4time_fname_lp(a9time_ob(j),i4time_j,istatus)
              i4_diff = abs(i4time_j - i4time_sys)
              if(i4_diff .lt. i4_closest)then
                  j_closest = j
                  i4_closest = i4_diff
              endif
          endif
      enddo ! j

      if(i .eq. j_closest)then
          l_closest_time_i = .true.
          write(6,*)' Closest time: ',a9time_ob(i)
     1             ,i,wmoid(i),j_closest,i4_closest
      else
          l_closest_time_i = .false.
      endif

      return
      end


      subroutine convert_array(array_in,array_out,n,string
     1                        ,r_missing_data,istatus)       

!     QC the observation array and convert units if needed
!     If 'string' is 'none', then do just the QC without conversion

      character*(*) string

      real*4 k_to_c

      real*4 array_in(n),array_out(n)

      do i = 1,n
          if(abs(array_in(i)) .ge. 1e10 .or. 
     1           array_in(i)  .eq. r_missing_data )then
              array_out(i) = r_missing_data
          elseif(string .eq. 'k_to_c')then
              array_out(i) = k_to_c(array_in(i))
          elseif(string .eq. 'pa_to_mb')then
              array_out(i) = array_in(i) / 100.
          elseif(string .eq. 'none')then
              array_out(i) = array_in(i)
          else
              write(6,*)' Unknown operator in convert_array: ',string
              istatus = 0
              return
          endif
      enddo ! i
     
      istatus = 1

      return
      end

