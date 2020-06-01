c CLASS = C SUBTYPE = EPIO
c  
c  
c  This file is generated automatically by the setparams utility.
c  It sets the number of processors and the class of the NPB
c  in this directory. Do not modify it by hand.
c  
        integer problem_size, niter_default
        parameter (problem_size=162, niter_default=100)
        double precision dt_default
        parameter (dt_default = 0.0001d0)
        integer wr_default
        parameter (wr_default = 5)
        integer iotype
        parameter (iotype = 3)
        character*(*) filenm
        parameter (filenm = 'btio.epio.out')
        logical  convertdouble
        parameter (convertdouble = .false.)
        character*11 compiletime
        parameter (compiletime='01 Jun 2020')
        character*3 npbversion
        parameter (npbversion='3.4')
        character*7 cs1
        parameter (cs1='mpifort')
        character*8 cs2
        parameter (cs2='$(MPIFC)')
        character*6 cs3
        parameter (cs3='-lcfun')
        character*6 cs4
        parameter (cs4='(none)')
        character*3 cs5
        parameter (cs5='-O3')
        character*27 cs6
        parameter (cs6='$(FFLAGS) -L/usr/local/lib ')
        character*6 cs7
        parameter (cs7='randi8')
