# random-walk
random walk visualizations in Processing, calculation tools in R

-----

TASEP-1D (Totally Asymmetric Simple Exclusion Process) one-dimensional simulation/visualization (2016)

I used this for undergraduate independent study projects in studying the NYC MTA's subway traffic.

-----

grid_stochastic_rw_1d, grid_stochastic_rw

stochastic time random walk, 1-dim and 2-dim (2012-2014)

This is supporting code for research on stochastic time random walks, written and modified with Michael Laufer over 2012-2014.

The grid code at the bottom (as in the TASEP visualization) is from https://forum.processing.org/beta/num_1195788276.html

Modify the mean for the best effect - compare mean zero versus nonzero.

-----

paths.R

Some functions to help describe and analyze simple random walks (2019)

Examples:

paths(N=6, S=0) outputs a list containing the 6C3 = 20 different 
     6-step paths starting at 0 and ending at 0, defaulting to '+' and '-'.

paths(N=7, S=1, u='H', d='T') outputs a list containing the 7C4 = 35 different 
     7-step paths starting at 0 and ending at 1, using 'H' and 'T'.

path_stats("+++-++") returns 6 4

path_stats("ududdduud",'u','d') returns 9 1

path_int("+") returns 0.5

path_int("uuudu",'u','d') returns 9.5
