# paths: recursive list function 
# inputs: N = pos int number of steps (default 0), 
#         S = int final position (default 0), 
#         p = list of existing paths (default empty),
#         u = up char (default '+'),
#         d = down char (default '-'),
# output: list of all SSRW paths that reach S in N steps.
# the structure of a "path" is a string of '+' and '-' for '+1' and '-1' steps.
#
# Examples:
# paths(N=6, S=0) outputs a list containing the 6C3 = 20 different 
#     6-step paths starting at 0 and ending at 0, defaulting to '+' and '-'.
# paths(N=7, S=1, u='H', d='T') outputs a list containing the 7C4 = 35 different 
#     7-step paths starting at 0 and ending at 1, using 'H' and 'T'.

paths <- function(N=0, S=0, u='+', d='-', p=list()) { 
  # First, there are many possible reasons to return an empty list:
  # steps N <= 0, or if N and S not of same parity, or N < abs(S) (can't reach)
  if ( (class(N) != "numeric") || class(S) != "numeric" || (class(p) != "list")
    || (N <= 0) || (N < abs(S)) || ((N - S) %% 2 == 1) ) {
    cat(sprintf("paths: bad inputs! N = %d cannot end at S = %d\n", N, S));
    return( list() ) # bad inputs; should return no possible paths
  } else if(N > 22) { # too big, say you can't do it in reasonable time
    cat(sprintf("paths: too big! Try N < 22. N = %d\n", N));
    return( list() )
    # else, iterate through all current entries on the list. 
  } else if(N == S) { # base case: only one path left: up N steps
    if (length(p) == 0) { return( list(strrep(u, N)) ); 
      } else { return(lapply(p, paste, strrep(u, N), sep='')); }
  } else if(N == -S) { # base case: only one path left: down N steps
    if (length(p) == 0) { return( list(strrep(d, N)) ); 
      } else { return(lapply(p, paste, strrep(d, N), sep='')); }
  } else { # recursion: N >= 2: each path can branch; feed back in.
#    cat(sprintf("recursion: down one from N = %d, S = %d\n", N, S));
    if (length(p) == 0) {
      return( append(paths(N-1, S-1, u, d, list(u)), 
                     paths(N-1, S+1, u, d, list(d))) );
    } else {
      return( append(paths(N-1, S-1, u, d, lapply(p, paste, u, sep='')), 
                     paths(N-1, S+1, u, d, lapply(p, paste, d, sep=''))) );
    }
  }
} # end paths


# path_stats:
# input:  path_str: a "path" string with 2 different characters,
#         u and d: the characters for "up" and "down", respectively.
# output: a pair (N,S): number of steps N, final pos S, assuming start pos 0.
# NOTE: u and d listed here as regex patterns because + is a reserved char.
# 
# Example: path_stats("+++-++") returns 6 4
# Example: path_stats("ududdduud",'u','d') returns 9 1
path_stats <- function(path_str, u="[+]", d="[-]") {
  if( (class(u) != "character") || (class(d) != "character")
      || (class(path_str) != "character") ) {
    cat(sprintf("path_stats: bad input!\n"));
    return (c(0,0));
  } else {
    library(stringr);
#    cat(sprintf("u = %s, d = %s, path = %s\n", u, d, path_str));
    num_u <- str_count(path_str, u);
    num_d <- str_count(path_str, d);
    N <- nchar(path_str);
    S <- num_u - num_d;
    if ( (num_u + num_d != N) || ((N-S) %% 2 != 0) ) {
      cat(sprintf("path_stats: bad string! non-path characters present\n"));
      return (c(0,0));
    } else { return (c(N,S)); }
  }
} # end path_stats


# path_int: 
# input:  path_str: a "path" string with 2 different characters,
#         u and d: the characters for "up" and "down", respectively.
# output: assuming start pos 0, the (discrete) integral of the path, over 
#         length-1 time steps, with u an up step and d a down step (of height 1).
# (basic trapezoidal rule, since all areas computed here are trapezoids.)
#
# Example: path_int("+") returns 0.5
# Example: path_int("uuudu", 'u', 'd') returns 9.5
path_int <- function(path_str, u="+", d="-") {
  # this is a very simple calculation, and we'll just do it iteratively.
  total  <- 0.0;
  height <- 0;
  N <- nchar(path_str);
  for(i in 1:N) { # must be iterated; we're tracking running height
    prev   <- height;
    height <- ifelse(substr(path_str,i,i) == u, height + 1, height - 1);
    total  <- total + (prev + height) / 2;
  }
  return (total);
} # end path_int
