

        subroutine vis_to_albedo(i4time,csatid,
     &                           r_norm_vis_cnts_in,
     &                           lat,lon,
     &                           imax,jmax,
     &                           r_missing_data,
     &                           phase_angle_d,
     &                           specular_ref_angle_d,
     &                           emission_angle_d,
     &                           rland_frac,
     &                           albedo_out,
     &                           albedo_min,
     &                           albedo_max,
     &                           n_missing_albedo,
     &                           istatus)
c
c program computes albedo given visible image array normalized for brightness.
c
c     J. Smart       17-Mar-1994           Original version taken from vis_to_
c                                          albedo written by S. Albers.
c     S. Albers       2-Mar-1995           Set threshold solar alt to 15.
c     S. Albers      22-Nov-1995           Extra phase angle constraint
c     S. Albers      22-Aug-1996           Extra specular ref angle constraint
c     J. Smart        8-Apr-1998           Added csatid to argument list, added to
c                                          formatted output.
c       "             6-Jul-1999           Added Emission_angle_d to argument list
c
C***Parameter and variables list
c
        Implicit None

        Real*4          cld_cnts,cld_albedo,frac,term1,term2
        Real*4          cloud_frac_vis
        Real*4          albedo_to_cloudfrac,cloudfrac_to_albedo
        Real*4          rlnd_cnts,rlnd_albedo
        parameter       (cld_cnts=220.,
     &                   rlnd_cnts=68.,
     &                   cld_albedo=0.85,
     &                   rlnd_albedo=0.15)

        Integer         imax,jmax
        Integer         i4time

        Real*4          r_norm_vis_cnts_in(imax,jmax)
        Real*4          lat(imax,jmax)
        Real*4          lon(imax,jmax)
        Real*4          phase_angle_d(imax,jmax)
        Real*4          specular_ref_angle_d(imax,jmax)
        Real*4          rland_frac(imax,jmax)
        Real*4          solar_alt_d
        Real*4          albedo
        Real*4          albedo_out(imax,jmax)
        Real*4          albedo_min,albedo_max
        Real*4          r_missing_data
        Real*4          jline, iline, jdiff, idiff
        Real*4          Emission_angle_d(imax,jmax)
        Integer         istatus, n_missing_albedo
        Integer         i,j

        Real*4 arg
        Character*(*)   csatid
c
c     ------------------------- BEGIN ---------------------------------

        albedo_min=1.0
        albedo_max=0.0

        write(6,*)' Subroutine vis2albedo:'
c
c       write(6,28)
c28      format(1x,' i   j   n vis cnts   solalt deg',/,40('-'))
        do j = 1,jmax
           jline = float(j)/10.
           jdiff = jline - int(jline)
           do i = 1,imax
              iline = float(i)/10.
              idiff = iline - int(iline)

              if(r_norm_vis_cnts_in(i,j).ne.r_missing_data)then

                 call solalt(lat(i,j),lon(i,j),i4time,solar_alt_d)

c             if(idiff.eq.0.00 .and. jdiff.eq.0.00)then
c                write(6,29)i,j,r_norm_vis_cnts_in(i,j),solar_alt_d
c29               format(1x,2i3,2x,2f8.2)
c             end if

!                Test for favorable geometry
                 if(      solar_alt_d .gt. 15. 
     1                            .AND.
     1          (solar_alt_d .gt. 23. .or. phase_angle_d(i,j) .gt. 20.)
     1                            .AND.
     1          (rland_frac(i,j) .gt. 0.5 
     1                         .or. specular_ref_angle_d(i,j) .gt. 10.)
     1                            .AND.
     1                    emission_angle_d(i,j) .gt. 15.       
     1                                                            )then       

                   arg = (r_norm_vis_cnts_in(i,j)- rlnd_cnts) /
     &                 (cld_cnts - rlnd_cnts)
         
                   albedo = rlnd_albedo + arg *
     &                   (cld_albedo - rlnd_albedo)
                   albedo_out(i,j)=min(max(albedo,-0.5),+1.5) ! Reasonable


                   if(solar_alt_d .lt. 20.)then ! enabled for now
!                    Fudge the albedo at low solar elevation angles < 20 deg
                     frac = (20. - solar_alt_d) / 10.
                     term1 = .13 * frac
                     term2 = 1. + term1

                     cloud_frac_vis = 
     1                           albedo_to_cloudfrac(albedo_out(i,j))
                     cloud_frac_vis = (cloud_frac_vis + term1) * term2
                     albedo_out(i,j) = 
     1                           cloudfrac_to_albedo(cloud_frac_vis)
                   endif
c                                                               excesses
c Accumulate extrema
c
                   albedo_min = min(albedo,albedo_min)
                   albedo_max = max(albedo,albedo_max)
   
                 else              ! Albedo .eq. missing_data

                   albedo_out(i,j) = r_missing_data
                   n_missing_albedo = n_missing_albedo + 1

                 endif             ! QC based on geometry

              else

                 albedo_out(i,j) = r_missing_data
                 n_missing_albedo = n_missing_albedo + 1

              endif                ! r_norm_vis_cnts_in = r_missing_data

           end do
         end do

         write(6,*)' n_missing_albedo = ',n_missing_albedo
         write(6,*)'       Mins and Maxs'
         write(6,105)csatid,albedo_min,albedo_max

 105     format(1x,a6,'  ALBEDO      ',2f10.2)

        Return
        End

        function albedo_to_cloudfrac(albedo)

        clear_albedo = .2097063
        cloud_albedo = .4485300

        arg = albedo

        call stretch2(clear_albedo,cloud_albedo,0.,1.,arg)

        albedo_to_cloudfrac = arg

        return
        end

        function cloudfrac_to_albedo(cloud_frac_vis)

        cloudfrac_to_albedo = (cloud_frac_vis + .87808) / 4.18719

        return
        end

C-------------------------------------------------------------------------------
        Subroutine Stretch2(IL,IH,JL,JH,rArg)

        Implicit        None

        Real*4          A,B,IL,IH,JL,JH,rarg

        a = (jh - jl) / (ih - il)
        b =  jl - il * a

        rarg = a * rarg + b

        return
        end

