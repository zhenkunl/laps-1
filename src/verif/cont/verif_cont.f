
        program verif_radar_main

        character*9 a9time

        call get_systime(i4time,a9time,istatus)
        if(istatus .ne. 1)go to 999

        write(6,*)' systime = ',a9time

        call get_grid_dim_xy(NX_L,NY_L,istatus)
        if (istatus .ne. 1) then
           write (6,*) 'Error getting horizontal domain dimensions'
           go to 999
        endif

        call get_laps_dimensions(NZ_L,istatus)
        if (istatus .ne. 1) then
           write (6,*) 'Error getting vertical domain dimension'
           go to 999
        endif

        call get_r_missing_data(r_missing_data,istatus)
        if (istatus .ne. 1) then
           write (6,*) 'Error getting r_missing_data'
           go to 999
        endif
          
        call verif_radar(i4time,a9time,
     1                  NX_L,NY_L,
     1                  NZ_L,
     1                  r_missing_data,
     1                  j_status)

999     continue

        end
          
        subroutine verif_radar(i4time_sys,a9time,
     1                  NX_L,NY_L,
     1                  NZ_L,
     1                  r_missing_data,
     1                  j_status)

        real var_anal_3d(NX_L,NY_L,NZ_L)
        real var_fcst_3d(NX_L,NY_L,NZ_L)
        logical lmask_and_3d(NX_L,NY_L,NZ_L)
        logical lmask_or_3d(NX_L,NY_L,NZ_L)
        logical lmask_all_3d(NX_L,NY_L,NZ_L)

        integer       maxbgmodels
        parameter     (maxbgmodels=10)
        character*9   c_fdda_mdl_src(maxbgmodels)

        character EXT*31, directory*255, c_model*10

        character*10  units_2d
        character*125 comment_2d
        character*3 var_2d
        character*9 a9time,a9time_valid
        character*150 hist_dir, cont_dir, verif_dir
        character*150 hist_file

        integer n_fields
        parameter (n_fields=1)
        character*10 ext_anal_a(n_fields), ext_fcst_a(n_fields)
        character*10 var_a(n_fields)
        integer nthr_a(n_fields) ! number of thresholds for each field

        data ext_fcst_a /'fua'/        
        data ext_anal_a /'lps'/        
        data var_a      /'REF'/        
        data nthr_a     /3/        

        integer contable(0:1,0:1)

        integer maxthr
        parameter (maxthr=3)

        real cont_4d(NX_L,NY_L,NZ_L,maxthr)

        lmask_all_3d = .true.
        thresh_var = 20. ! lowest threshold for this variable

        i4_initial = i4time_sys

!       Get fdda_model_source from static file
        call get_fdda_model_source(c_fdda_mdl_src,n_fdda_models,istatus)

        write(6,*)' n_fdda_models = ',n_fdda_models
        write(6,*)' c_fdda_mdl_src = ',c_fdda_mdl_src

        do ifield = 1,n_fields

         var_2d = var_a(ifield)
         call s_len(var_2d,lenvar)

         do imodel = 1,n_fdda_models

          c_model = c_fdda_mdl_src(imodel)

          if(c_model(1:3) .ne. 'lga')then

            write(6,*)' Processing model ',c_model

            call s_len(c_model,len_model)

            call get_directory('verif',verif_dir,len_verif)

            hist_dir = verif_dir(1:len_verif)//var_2d(1:lenvar)
     1                                       //'/hist/'
     1                                       //c_model(1:len_model)
            len_hist = len_verif + 6 + lenvar + len_model

            cont_dir = verif_dir(1:len_verif)//var_2d(1:lenvar)
     1                                       //'/cont/'
     1                                       //c_model(1:len_model)
     1                                       //'/'
!           len_cont = len_verif + 6 + lenvar + len_model

            do ihr_fcst = 0,12

              i4_valid = i4_initial + ihr_fcst * 3600

              call make_fnam_lp(i4_valid,a9time_valid,istatus)

              write(6,*)
              write(6,*)' Histograms for forecast hour ',ihr_fcst

              lun_out = 11

!             Add c_model to this?
              hist_file = hist_dir(1:len_hist)//'/'//a9time_valid
     1                                        //'.hist'     

              write(6,*)hist_file

              open(11,file=hist_file,status='unknown')

!             Read analyzed reflectivity
              ext = ext_anal_a(ifield)
              call get_laps_3d(i4_valid,NX_L,NY_L,NZ_L
     1            ,ext,var_2d,units_2d,comment_2d,var_anal_3d,istatus)
              if(istatus .ne. 1)then
                  write(6,*)' Error reading 3D REF Analysis'
                  return
              endif

!             Read forecast reflectivity
              ext = ext_fcst_a(ifield)
              call get_directory(ext,directory,len_dir)
              DIRECTORY=directory(1:len_dir)//c_model(1:len_model)//'/'

              call get_lapsdata_3d(i4_initial,i4_valid,NX_L,NY_L,NZ_L       
     1                          ,directory,var_2d
     1                          ,units_2d,comment_2d,var_fcst_3d
     1                          ,istatus)
              if(istatus .ne. 1)then
                  write(6,*)' Error reading 3D REF Forecast'
                  return
              endif

!             Calculate "and" mask
              do k = 1,NZ_L
              do i = 1,NX_L
              do j = 1,NY_L
                lmask_and_3d(i,j,k) = .false.
                if(var_anal_3d(i,j,k) .ne. r_missing_data .and. 
     1             var_anal_3d(i,j,k) .ge. thresh_var .and.
     1             var_fcst_3d(i,j,k) .ne. r_missing_data .and.
     1             var_fcst_3d(i,j,k) .ge. thresh_var           )then
                    lmask_and_3d(i,j,k) = .true.
                endif
              enddo ! j
              enddo ! i
              enddo ! k

!             Calculate "or" mask
              do k = 1,NZ_L
              do i = 1,NX_L
              do j = 1,NY_L
                lmask_or_3d(i,j,k) = .false.
                if((var_anal_3d(i,j,k) .ne. r_missing_data .and. 
     1              var_anal_3d(i,j,k) .ge. thresh_var) .OR.
     1             (var_fcst_3d(i,j,k) .ne. r_missing_data .and.
     1              var_fcst_3d(i,j,k) .ge. thresh_var)          )then       
                    lmask_or_3d(i,j,k) = .true.
                endif
              enddo ! j
              enddo ! i
              enddo ! k

              write(lun_out,*)
              write(lun_out,*)' NO mask is in place'

              write(lun_out,*)
              write(lun_out,*)' Calling radarhist for analysis at '
     1                        ,a9time_valid
              call radarhist(NX_L,NY_L,NZ_L,var_anal_3d,lmask_all_3d
     1                     ,lun_out)       

              write(lun_out,*)
              write(lun_out,*)' Calling radarhist for',ihr_fcst
     1               ,' hr forecast valid at ',a9time_valid
              call radarhist(NX_L,NY_L,NZ_L,var_fcst_3d,lmask_all_3d
     1                    ,lun_out)

              write(lun_out,*)
              write(lun_out,*)
     1    ' 3-D AND mask is in place with dbz threshold of ',thresh_var       

              write(lun_out,*)
              write(lun_out,*)' Calling radarhist for analysis at '
     1                      ,a9time_valid
              call radarhist(NX_L,NY_L,NZ_L,var_anal_3d,lmask_and_3d
     1                      ,lun_out)

              write(lun_out,*)
              write(lun_out,*)' Calling radarhist for',ihr_fcst
     1               ,' hr forecast valid at ',a9time_valid
              call radarhist(NX_L,NY_L,NZ_L,var_fcst_3d,lmask_and_3d
     1                    ,lun_out)

              nthr = nthr_a(ifield)

!             Calculate contingency tables
              do idbz = 1,nthr
                rdbz = float(idbz*20)

                write(lun_out,*)
                write(lun_out,*)' Calculate contingency table for '
     1                         ,rdbz,' dbz'
                call contingency_table(var_anal_3d,var_fcst_3d
     1                                ,NX_L,NY_L,NZ_L,rdbz,lun_out
     1                                ,contable)


!               Calculate/Write Skill Scores
                call skill_scores(contable,lun_out)

!               Calculate Contingency Table (3-D)
                call calc_contable(i4_initial,i4_valid
     1                       ,var_anal_3d,var_fcst_3d
     1                       ,rdbz,contable,NX_L,NY_L,NZ_L
     1                       ,cont_4d(1,1,1,idbz))

              enddo ! idbz

!             Write Contingency Tables (3-D)
              call put_contables(i4_initial,i4_valid,nthr
     1                        ,cont_4d,NX_L,NY_L,NZ_L,cont_dir)

              close (lun_out) 

            enddo ! ihr_fcst

          endif ! c_model .ne. lga

         enddo ! model

        enddo ! fields

 999    write(6,*)' End of subroutine verif_radar'

        return

        end
