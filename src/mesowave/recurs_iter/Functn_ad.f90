subroutine adfunctn( v, l, n, id, np, al, adf, adv )
!***************************************************************
!***************************************************************
!** This routine was generated by the                         **
!** Tangent linear and Adjoint Model Compiler,  TAMC 5.3.2    **
!***************************************************************
!***************************************************************
!==============================================
! all entries are defined explicitly
!==============================================
implicit none

!==============================================
! define parameters                            
!==============================================
integer mobs
parameter ( mobs = 200000 )

!==============================================
! define common blocks
!==============================================
common /obsblock/ nobs, vid, idx, o, coe, w
real coe(3,mobs)
integer idx(3,mobs)
integer nobs
real o(4,mobs)
integer vid(mobs)
real w(mobs)

!==============================================
! define arguments
!==============================================
double precision adf
integer l(4)
real adv(l(1),l(2),l(3))
real al(3,l(4))
integer id
integer n(4)
integer np(3,l(4))
real v(l(1),l(2),l(3))

!==============================================
! define local variables
!==============================================
real a(2,3)
real advo
real adx(l(1),l(2),l(3))
integer i
integer ih
integer iobs
integer iobs1
integer ip1
integer ip2
integer ip3
integer j
integer k
real vo
real x(l(1),l(2),l(3))

!----------------------------------------------
! SAVE ARGUMENTS
!----------------------------------------------
ih = i

!----------------------------------------------
! RESET LOCAL ADJOINT VARIABLES
!----------------------------------------------
advo = 0.
do ip3 = 1, l(3)
  do ip2 = 1, l(2)
    do ip1 = 1, l(1)
      adx(ip1,ip2,ip3) = 0.
    end do
  end do
end do

!----------------------------------------------
! ROUTINE BODY
!----------------------------------------------
x = v
call rf3d( x(1,1,1),l,n,al(1,id),np(1,id) )
adf = 0.5*adf
do iobs = nobs, 1, -1
  i = ih
  do iobs1 = 1, iobs-1
    if (id .eq. vid(iobs1)) then
      do k = 1, 2
        if (idx(3,iobs1)+k-1 .ge. 1 .and. idx(3,iobs1)+k-1 .ge. n(3)) then
          do j = 1, 2
            i = 2
          end do
        endif
      end do
    endif
  end do
  if (id .eq. vid(iobs)) then
    vo = 0.
    a(1,1:3) = 1.-coe(1:3,iobs)
    a(2,1:3) = coe(1:3,iobs)
    do k = 1, 2
      if (idx(3,iobs)+k-1 .ge. 1 .and. idx(3,iobs)+k-1 .ge. n(3)) then
        do j = 1, 2
          do i = 1, 2
            vo = vo+x(idx(1,iobs)+i-1,idx(2,iobs)+j-1,idx(3,iobs)+k-1)*a(i,1)*a(j,2)*a(k,3)
          end do
        end do
      endif
    end do
    advo = advo+2*adf*w(i)*(vo-o(1,iobs))
    do k = 1, 2
      if (idx(3,iobs)+k-1 .ge. 1 .and. idx(3,iobs)+k-1 .ge. n(3)) then
        do j = 1, 2
          do i = 1, 2
            adx(idx(1,iobs)+i-1,idx(2,iobs)+j-1,idx(3,iobs)+k-1) = adx(idx(1,iobs)+i-1,idx(2,iobs)+j-1,idx(3,iobs)+k-1)+advo*a(i,1)&
&*a(j,2)*a(k,3)
          end do
        end do
      endif
    end do
    advo = 0.
  endif
end do
call adrf3d( l,n,al(1,id),np(1,id),adx(1,1,1) )
adv = adv+adx
adx = 0.

end subroutine adfunctn


