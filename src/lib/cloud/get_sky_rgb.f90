
        subroutine get_sky_rgb(r_cloud_3d,cloud_od,r_cloud_rad, &
                               cloud_rad_c, &
                               clear_rad_c, &
                               glow,glow_stars,od_atm_a, &
                               airmass_2_cloud,airmass_2_topo, &
                               topo_swi,topo_albedo, & 
                               aod_2_cloud,aod_2_topo, &
                               alt_a,azi_a,elong_a,ni,nj,sol_alt,sol_az, &
                               moon_alt,moon_az,moon_mag, &
                               sky_rgb)                                 ! O

        use mem_namelist, ONLY: r_missing_data
        include 'trigd.inc'

        addlogs(x,y) = log10(10.**x + 10.**y)
        trans(od) = exp(-od)
        brt(a,ext) = 1.0 - exp(-a*ext)

        parameter (nc = 3)

        real r_cloud_3d(ni,nj)      ! cloud opacity
        real cloud_od(ni,nj)        ! cloud optical depth
        real r_cloud_rad(ni,nj)     ! sun to cloud transmissivity (direct+fwd scat)
        real cloud_rad_c(nc,ni,nj)  ! sun to cloud transmissivity (direct+fwd scat) * solar color/int
        real clear_rad_c(nc,ni,nj)  ! integrated fraction of air illuminated by the sun along line of sight             
                                    ! (accounting for Earth shadow + clouds)
        real clear_rad_c_nt(3)      ! HSV night sky brightness
        real glow(ni,nj)            ! skyglow (log b in nanolamberts)
        real glow_stars(ni,nj)      ! starglow (log b in nanolamberts)
        real airmass_2_cloud(ni,nj) ! airmass to cloud 
        real airmass_2_topo(ni,nj)  ! airmass to topo  
        real topo_swi(ni,nj)        ! terrain illumination
        real topo_albedo(nc,ni,nj)  ! terrain albedo
        real aod_2_cloud(ni,nj)     ! future use
        real aod_2_topo(ni,nj)      ! future use
        real alt_a(ni,nj)
        real azi_a(ni,nj)
        real elong_a(ni,nj)
        real rintensity(nc), cld_rgb_rat(nc)
       
        real ext_g(nc),trans_c(nc)  ! od per airmass, tramsmissivity
        data ext_g /.07,.14,.28/    ! refine via Schaeffer

        real sky_rgb(0:2,ni,nj)
        real moon_alt,moon_az,moon_mag

        write(6,*)' get_sky_rgb: sol_alt = ',sol_alt
        write(6,*)' moon alt/az/mag = ',moon_alt,moon_az,moon_mag

        patm = 0.85

!       Use maximum sky brightness to calculate a secondary glow (twilight)
        call get_twi_glow_ave(glow(:,:) + log10(clear_rad_c(3,:,:)) &
                     ,alt_a,azi_a,ni,nj,sol_alt,sol_az,twi_glow_ave)
        write(6,*)' twi_glow_ave = ',twi_glow_ave

!       arg = maxval(glow(:,:) + log10(clear_rad_c(3,:,:))) ! phys val
        arg = maxval(8.0       + log10(clear_rad_c(3,:,:))) ! avoid moon
        write(6,*)' twi_glow_max = ',arg

!       glow_secondary = arg - 1.5          ! one thirtieth of max sky brightness
        glow_diff_cld      = 0.8
        glow_diff_clr      = 1.5
        glow_secondary_cld = twi_glow_ave - glow_diff_cld
        glow_secondary_clr = twi_glow_ave - glow_diff_clr

        write(6,*)' glow_secondary_cld = ',glow_secondary_cld
        write(6,*)' glow_secondary_clr = ',glow_secondary_clr

        if(sol_alt .le. 0.)then
            sol_alt_eff = max(sol_alt,-16.)
!           Test at -3.2 solar alt
            fracalt = sol_alt_eff / -16.
            corr1 = 8.3; corr2 = 3.612
!           argref = corr1 + (fracalt**0.83 * (corr2-corr1))
            argref = corr1 + (fracalt**0.68 * (corr2-corr1))
            contrast = 70. + 30. * (abs(sol_alt_eff + 8.)/8.)**2
            write(6,*)' argref = ',argref
            write(6,*)' contrast = ',contrast
        endif

!       Cloud glow Calculation
!       Sun = 96000 lux
!       Vega = 2.54 * 1e-6 lux
!       1 lambert = 1 lumen / cm**2
!       Sun is -26.9 mag per sphere
!       (180/pi)^2 * 4 * pi = 41250 square degrees in a sphere.
!       5.346e11 square arcsec in a sphere
        glow_cld_day = v_to_b(-26.9 + log10(5.346e11)*2.5)
        write(6,*)' glow_cld_day (nl) = ',glow_cld_day

!       Redness section (sun and aureole at low solar altitude)
        sol_alt_red_thr = 7.0 + (od_atm_a * 20.)
        if(sol_alt .le. sol_alt_red_thr .and. sol_alt .gt. -16.0)then
            redness = min((sol_alt_red_thr - sol_alt) / sol_alt_red_thr,1.0)**1.5
        else
            redness = 0.
        endif
        write(6,*)' sol_alt_red_thr/redness = ',sol_alt_red_thr,redness

!       Grnness section (clear sky at low solar altitudes)      
        sol_alt_grn_thr = 10.0                       
        if(sol_alt .le. sol_alt_grn_thr .and. sol_alt .gt. -16.0)then
            grnness = min((sol_alt_grn_thr - sol_alt) / sol_alt_grn_thr,1.0)
        else
            grnness = 0.
        endif
        write(6,*)' sol_alt_grn_thr/grnness = ',sol_alt_grn_thr,grnness

!       Brighten resulting image at night
        if(sol_alt .lt. -16.)then
            ramp_night = 1.0
        else
            ramp_night = 1.0
        endif

        if(ni .eq. nj)then ! polar
            write(6,*)' slice from SW to NE through midpoint'
        else
            write(6,*)' slices at 46,226 degrees azimuth'
        endif

        if(.true.)then
          if(sol_alt .ge. 0.)then       ! daylight
            write(6,11)
11          format('    i   j      alt      azi     elong   pf_scat   opac       od      alb     cloud  airmass   rad    rinten   airtopo  switopo  topoalb   topood  topovis  cld_visb  glow      skyrgb')
          elseif(sol_alt .ge. -16.)then ! twilight
            write(6,12)
12          format('    i   j      alt      azi     elong   pf_scat   opac       od      alb     cloud  airmass   rad    rinten glw_cld_nt glw_cld  glw_twi glw2ndclr rmaglim  cld_visb  glow      skyrgb')
          else                          ! night
            write(6,13)
13          format('    i   j      alt      azi     elong   pf_scat2  opac       od      alb     cloud  airmass   rade-3 rinten glw_cld_nt glw_cld glwcldmn glw2ndclr rmaglim  cld_visb  glow      skyrgb')
          endif
        endif

        do j = 1,nj
        do i = 1,ni

         if(alt_a(i,j) .eq. r_missing_data)then
          sky_rgb(:,i,j) = 0.          
         else
          idebug = 0
          if(ni .eq. nj)then ! polar
!             if(i .eq. ni/2 .AND. j .eq. (j/5) * 5)then
              if(i .eq.    j .AND. j .eq. (j/5) * 5)then ! SW/NE
                  idebug = 1
              endif
          else ! cyl
              if(azi_a(i,j) .eq. 46. .OR. azi_a(i,j) .eq. 226.)then ! constant azimuth
                  idebug = 1
!                 if(i .eq. 1)write(6,11)   
              endif
          endif

!         a substitute for cloud_rad could be arg2 = (cosd(alt))**3.

!         using 'rill' is a substitute for considering the slant path
!         in 'get_cloud_rad'
          rill = (1. - cosd(elong_a(i,j)))/2.
          whiteness_thk = r_cloud_rad(i,j) ! * rill ! default is 0.
!         rint_coeff =  380. * (1. - whiteness_thk) ! default is 380.
!         rint_coeff =  900. * (1. - whiteness_thk) ! default is 380.

!         rintensity = 250. - ((abs(r_cloud_3d(i,j)-0.6)**2.0) * rint_coeff)

!         Phase function that depends on degree of forward scattering in cloud    
!         pwr controls angular extent of forward scattering peak of a thin cloud
!         Useful reference: http://www-evasion.imag.fr/Publications/2008/BNMBC08/clouds.pdf
          if(elong_a(i,j) .le. 90.)then
              pwr = 3.0
              ampl = r_cloud_rad(i,j) * 0.7; b = 1.0 + pwr * r_cloud_rad(i,j)
              pf_scat = 0.9 + ampl * (cosd(min(elong_a(i,j),89.99))**b)
              cloud_odl  = -99.9 ! flag value for logging
              bkscat_alb = -99.9 ! flag value for logging
          else
!             convert from opacity to albedo
!             bkscat_alb = r_cloud_3d(i,j) ** 2.0 ! approx opacity to albedo
              cloud_opacity = min(r_cloud_3d(i,j),0.999999)
              cloud_odl = -log(1.0 - cloud_opacity)
!             bksc_eff_od = cloud_odl     * 0.12 ! > .10 due to machine epsilon
              bksc_eff_od = cloud_od(i,j) * 0.10 
              cloud_rad_trans = exp(-bksc_eff_od)
              bkscat_alb = 1.0 - cloud_rad_trans 
              ampl = 0.15 * bkscat_alb
              pf_scat = 0.9 + ampl * (-cosd(elong_a(i,j)))
          endif

!         Obtain cloud brightness
          if(sol_alt .ge. -4.)then ! Day/twilight from cloud_rad_c array
!             Potential intensity of cloud if it is opaque 
!               (240. is nominal intensity of a white cloud far from the sun)
!               (0.25 is dark cloud base value)                                  
              rint_top  = 240.                                        * pf_scat 
              rint_base = 240. * (  0.35                            ) * pf_scat 
!             Gamma color correction applied when sun is near horizon 
              cld_rgb_rat(:) = (cloud_rad_c(:,i,j) / cloud_rad_c(1,i,j)) ** 0.45
              rintensity(:) = rint_top  * cld_rgb_rat(:) * r_cloud_rad(i,j) &
                            + rint_base * (1.0 - r_cloud_rad(i,j))
!             rintensity = min(rintensity,255.)
              rintensity = max(rintensity,0.)

!             Apply cloud reddening
              trans_c = trans(ext_g * airmass_2_cloud(i,j))              
              rintensity = rintensity * (trans_c/trans_c(1))**0.25 ! 0.45

          else ! later twilight (clear_rad_c) and nighttime (surface lighting)
              glow_cld_nt = log10(5000.) ! 10 * clear sky zenith value (log nl)
              glow_cld = addlogs(glow_cld_nt,glow_secondary_cld) ! 2ndary sct

              glow_twi = glow(i,j) + log10(clear_rad_c(3,i,j)) ! phys val

              if(sol_alt .lt. -16.)then
!                 Add phys term for scattering by moonlight on the clouds
                  pf_scat2 = 5. ** (pf_scat - 1.1)
!                 glow_cld_day = 2e10 ! nanolamberts (actual about 3e9)
                  glow_cld_moon = log10(glow_cld_day * cloud_rad_c(2,i,j) * pf_scat2)
                  glow_cld = addlogs(glow_cld,glow_cld_moon)
              endif

!             During twilight, compare with clear sky background
!             Note that secondary scattering might also be considered in
!             early twilight away from the bright twilight arch.
!             The result creates a contrast effect for clouds vs twilight            
              rintensity(:) = max(min(((glow_cld -argref) * contrast + 128.),255.),0.)
          endif

          cld_red = nint(rintensity(1))                
          cld_grn = nint(rintensity(2))                        
          cld_blu = nint(rintensity(3))                         

!         Obtain brightness (glow) of clear sky
          if(sol_alt .ge. 0.)then ! Daylight from skyglow routine
              glow_tot = glow(i,j) + log10(clear_rad_c(3,i,j))
!             rintensity_glow = min(((glow(i,j)-7.) * 100.),255.)
              rintensity_glow = min(((glow_tot -7.) * 100.),255.)
              if(.false.)then
                clr_red = rintensity_glow *  rintensity_glow / 255.
                clr_grn = rintensity_glow * (rintensity_glow / 255.)**0.80
                clr_blu = rintensity_glow  
              else ! consider color
                z = 90. - alt_a(i,j)        
                airmass = 1. / (cosd(z) + 0.025 * exp(-11 * cosd(z)))
                ray_red = brt(airmass,ext_g(1)*patm*0.50) ! + od_atm_a?
                ray_grn = brt(airmass,ext_g(2)*patm*0.50) ! + od_atm_a?
                ray_blu = brt(airmass,ext_g(3)*patm*0.50) ! + od_atm_a?
                elong_gn = 55. + 10. * sind(sol_alt)
                frac_ray = max(min((elong_a(i,j)-elong_gn)/35.,1.0),0.0)
                frac_ray = frac_ray * cosd(alt_a(i,j)) * 0.5
                if(idebug .eq. 1)then
!                   write(6,115)alt_a(i,j),elong_a(i,j),airmass,ray_red,ray_grn,ray_blu
115                 format('frac_ray',3f8.2,3f8.4)
                endif
!               frac_ray = 1.0
!               gob = max((rintensity_glow/255.)**0.8,((ray_grn/ray_blu)**0.885)*frac_ray)
!               rob = max( rintensity_glow/255.      ,((ray_red/ray_blu)**0.885)*frac_ray)
                exr = 1.0 * (1.0 - 0.2*grnness)
                exg = 0.8 * (1.0 - 0.5*grnness)
                gob = (1.0-frac_ray) * (rintensity_glow/255.)**exg+((ray_grn/ray_blu)**0.885)*frac_ray
                rob = (1.0-frac_ray) * (rintensity_glow/255.)**exr+((ray_red/ray_blu)**0.885)*frac_ray
                clr_red = rintensity_glow *  rob
                clr_grn = rintensity_glow *  gob
                clr_blu = rintensity_glow  
              endif

          elseif(sol_alt .ge. -16.)then ! Twilight from clear_rad_c array
              call get_clr_rad_nt(alt_a(i,j),azi_a(i,j),clear_rad_c_nt)
              glow_nt = log10(clear_rad_c_nt(3)) ! log nL           

              hue = clear_rad_c(1,i,j)
              sat = clear_rad_c(2,i,j)
              glow_twi = glow(i,j) + log10(clear_rad_c(3,i,j)) ! phys val
              glow_twi = addlogs(glow_twi,glow_secondary_clr)
              glow_twi = addlogs(glow_twi,glow_nt)

              if(glow_stars(i,j) .gt. 1.0)then
!                 write(6,*)'i,j,glow_stars',i,j,glow_stars(i,j)
              endif
!             glow_stars(i,j) = 1.0                           ! test
              glow_tot = addlogs(glow_twi,glow_stars(i,j))    ! with stars 
              star_ratio = 10. ** ((glow_tot - glow_twi) * 0.45)

!             arg = glow(i,j) + log10(clear_rad_c(3,i,j)) * 0.15             
              arg = glow_tot                                  ! experiment?            
              rintensity_floor = 0. ! 75. + sol_alt

!             rintensity_glow = max(min(((arg     -7.) * 100.),255.),rintensity_floor)
!             rintensity_glow = max(min(((arg -argref) * 100.),255.),rintensity_floor)
              rintensity_glow = max(min(((arg -argref) * contrast + 128.),255.),rintensity_floor)
!             rintensity_glow = min(rintensity_glow*star_ratio,255.)              
              call hsl_to_rgb(hue,sat,rintensity_glow,clr_red,clr_grn,clr_blu)
!             if(idebug .eq. 1)then
!                 write(6,*)'Clr RGB = ',nint(clr_red),nint(clr_grn),nint(clr_blu),rintensity_floor, rintensity_glow
!             endif
!             clr_red = rintensity_glow * clear_rad_c(2,i,j)
!             clr_blu = rintensity_glow * clear_rad_c(3,i,j)
!             clr_grn = 0.5 * (clr_red + clr_blu)                               

          else ! Night from clear_rad_c array (default flat value of glow)
              call get_clr_rad_nt(alt_a(i,j),azi_a(i,j),clear_rad_c_nt)
              hue = clear_rad_c_nt(1)
              sat = clear_rad_c_nt(2)
              glow_nt = log10(clear_rad_c_nt(3)) ! log nL           

              if(moon_alt .gt. 0.)then ! add moon mag condition
!                 Glow from Rayleigh, no clear_rad crepuscular rays yet
!                 argm = glow(i,j) + log10(clear_rad_c(3,i,j)) * 0.15
                  glow_moon = glow(i,j)          ! log nL                 
                  glow_tot = addlogs(glow_nt,glow_moon)
              else
                  glow_tot = glow_nt
                  glow_moon = 0.
              endif

!             Add in stars. Stars have a background glow of 1.0
              glow_tot = addlogs(glow_tot,glow_stars(i,j))

!             if((idebug .eq. 1 .and. moon_alt .gt. 0.) .OR. glow_stars(i,j) .gt. 1.0)then
              if((idebug .eq. 1) .OR. glow_stars(i,j) .gt. 2.0)then
                  write(6,91)glow_nt,glow_moon,glow_stars(i,j),glow_tot
91                format(' glow: nt/moon/stars/tot = ',4f9.3)
                  idebug = 1 ! for subsequent writing at this grid point
              endif

!             rintensity_glow = max(min(((glow_tot - 2.3) * 100.),255.),20.)
              rintensity_glow = max(min(((glow_tot - argref) * contrast + 128.),255.),20.)
              call hsl_to_rgb(hue,sat,rintensity_glow,clr_red,clr_grn,clr_blu)

          endif

!         Apply redness to clear sky / sun
          elong_red = 12.0
          if(elong_a(i,j) .le. elong_red)then
!         if(.false.)then                        
              red_elong = (elong_red - elong_a(i,j)) / elong_red
!             write(6,*)' alt/elong/redelong: ',alt_a(i,j),elong_a(i,j),red_elong
              clr_red = clr_red * 1.0
              clr_grn = clr_grn * (1. - redness * red_elong)**0.3 
              clr_blu = clr_blu * (1. - redness * red_elong)
          endif

!                     Rayleigh  Ozone   Mag per optical depth            
          od_atm_g = (0.1451  + .016) / 1.086
          od_2_cloud = (od_atm_g + od_atm_a) * airmass_2_cloud(i,j)

!         Empirical correction to account for bright clouds being visible
          cloud_visibility = exp(-0.71*od_2_cloud) ! empirical coefficient

!         Use clear sky values if cloud cover is less than 0.5
          frac_cloud = r_cloud_3d(i,j)
!         frac_cloud = 0.0 ; Testing
          frac_cloud = frac_cloud * cloud_visibility  
          frac_clr = 1.0 - frac_cloud                         
          sky_rgb(0,I,J) = clr_red * frac_clr + cld_red * frac_cloud
          sky_rgb(1,I,J) = clr_grn * frac_clr + cld_grn * frac_cloud
          sky_rgb(2,I,J) = clr_blu * frac_clr + cld_blu * frac_cloud
          sky_rgb(:,I,J) = min(sky_rgb(:,I,J),255.)

!         Use topo value if airmass to topo > 0
          if(airmass_2_topo(i,j) .gt. 0.)then
              od_2_topo = (od_atm_g + od_atm_a) * airmass_2_topo(i,j)
              topo_visibility = exp(-1.00*od_2_topo)                    

              if(airmass_2_cloud(i,j) .gt. 0. .AND. airmass_2_cloud(i,j) .lt. airmass_2_topo(i,j)) then
                  topo_visibility = topo_visibility * (1.0 - r_cloud_3d(i,j))
              endif

              topo_swi_frac = (max(topo_swi(i,j),001.) / 1000.) ** 0.45
              rtopo_red = 120. * topo_swi_frac * (topo_albedo(1,i,j)/.15)**0.45
              rtopo_grn = 120. * topo_swi_frac * (topo_albedo(2,i,j)/.15)**0.45
              rtopo_blu = 120. * topo_swi_frac * (topo_albedo(3,i,j)/.15)**0.45

              sky_rgb(0,I,J) = nint(rtopo_red*topo_visibility + sky_rgb(0,I,J)*(1.0-topo_visibility) )
              sky_rgb(1,I,J) = nint(rtopo_grn*topo_visibility + sky_rgb(1,I,J)*(1.0-topo_visibility) )
              sky_rgb(2,I,J) = nint(rtopo_blu*topo_visibility + sky_rgb(2,I,J)*(1.0-topo_visibility) )
          else
              od_2_topo = 0.
          endif

          sky_rgb(:,i,j) = min(sky_rgb(:,i,j) * ramp_night,255.)

          if(idebug .eq. 1)then
              rmaglim = b_to_maglim(10.**glow_tot)
              call apply_rel_extinction(rmaglim,alt_a(i,j),od_atm_g+od_atm_a)
              if(sol_alt .ge. 0.)then        ! daylight
                  write(6,102)i,j,alt_a(i,j),azi_a(i,j),elong_a(i,j) & 
                      ,pf_scat,r_cloud_3d(i,j),cloud_od(i,j),bkscat_alb &
                      ,frac_cloud,airmass_2_cloud(i,j),r_cloud_rad(i,j),rintensity(1),airmass_2_topo(i,j) &
                      ,topo_swi(i,j),topo_albedo(1,i,j),od_2_topo,topo_visibility,cloud_visibility,rintensity_glow,nint(sky_rgb(:,i,j)) &
                      ,nint(cld_red),nint(cld_grn),nint(cld_blu)
              elseif(sol_alt .ge. -16.)then ! twilight
                  write(6,103)i,j,alt_a(i,j),azi_a(i,j),elong_a(i,j) & 
                      ,pf_scat,r_cloud_3d(i,j),cloud_od(i,j),bkscat_alb &
                      ,frac_cloud,airmass_2_cloud(i,j),r_cloud_rad(i,j) &
                      ,rintensity(1),glow_cld_nt,glow_cld,glow_twi &
                      ,glow_secondary_clr,rmaglim,cloud_visibility &
                      ,rintensity_glow,nint(sky_rgb(:,i,j)),clear_rad_c(:,i,j),nint(clr_red),nint(clr_grn),nint(clr_blu)                              
              else ! night
                  write(6,104)i,j,alt_a(i,j),azi_a(i,j),elong_a(i,j) & 
                      ,pf_scat2,r_cloud_3d(i,j),cloud_od(i,j),bkscat_alb &
                      ,frac_cloud,airmass_2_cloud(i,j),cloud_rad_c(2,i,j)*1e3,rintensity(1) &
                      ,glow_cld_nt,glow_cld,glow_cld_moon,glow_secondary_clr,rmaglim &
                      ,cloud_visibility,rintensity_glow,nint(sky_rgb(:,i,j)),clear_rad_c_nt(:)
              endif
102           format(2i5,3f9.2,f9.3,f9.4,4f9.3,f9.4,f7.1,f9.3,f9.1,4f9.3,f9.2,2x,3i4,' cldrgb',1x,3i4)
103           format(2i5,3f9.2,f9.3,f9.4,4f9.3,f9.4,f7.1,f9.3,f9.1,4f9.3,f9.2,2x,3i4,' clrrad',3f10.6,3i4)
104           format(2i5,3f9.2,f9.3,f9.4,4f9.3,f9.6,f7.1,f9.3,f9.3,4f9.3,f9.2,2x,3i4,' clrrad',3f8.2)
          endif

         endif ! missing data tested via altitude

        enddo ! i
        enddo ! j

        return
        end
