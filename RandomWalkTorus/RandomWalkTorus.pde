/**
 * Random walk on a torus
 * by Michael Carlisle
 * 
 * v0.1.0: 20100925 (SRW 1-step only)
 * v0.2.0: 20100930 (added Gaussian walk, expanded SRW to jumps)
 * v0.2.1: 20101012 (added coloring for favorite point... it's invisible. :( )
 * v0.2.2: 20101120 (moved to K1xK2 rectangle from KxK square)
 * v0.2.3: 20110703 (added # of unvisited points, stops at cover time, external Green's function)
 * v0.3.0: 20110711 (great. didn't save AGAIN. added: pause on cover time, etc.)
 * v0.4.0: 20111119 (merged with other versions - added in pausing, more data to user, etc.)
 * v0.4.1: 20111122 (moving walk type and size to Walker class, to calc other cover times, etc.)
 * v0.4.2: 20120320 (web version with processing.js - tweaked some parameters)
 */

// K1 = horiztonal size of torus; will be used to size window as well. K2 = vertical
// good pair for SRW(1): K=700, colorSize=12 
//int K1 = 700, K2 = 700;
int K1 = 1000;
int K2 = 1000;

//int startX = floor(K1 / 2);
//int startY = floor(K2 / 2);

int startX = floor(K1 / 2);
int startY = floor(K2 / 2);
int r = 10; // when considering a disc, this is its radius


// TODO: tie colorSize, drawSteps to K1, K2
// use colorSize = 15, drawSteps = 25000 for K = 400, 20 & 100000 for K=700

int colorSize = 12; // threshold for going to next color branch -- 
int drawSteps = 100;  // how many steps to take before drawing them all on screen - TODO: scale to K1, K2?
int numSteps = 0;   // counter for total steps taken
int unvisited = K1 * K2;  // how many points have not yet been visited
int covertime = 0;
int penult = 0;
boolean paused = false;
int expCT = floor((4 / 3.14159265) * K1 * K2 * log(K1) * log(K2)); // ORIGINAL - is this WRONG, depending on cov(X_1)?!
int expFPvisits = floor((1 / 3.14159265) * log(expCT) * log(expCT)); // ditto above... ack

int favx1 = startX, favx2 = startY, favN = 0;

// 0 = SRW, 1 = Gaussian-like
int whichWalk = 0;
// gives range of SRW, or variance of Gaussian
float walkParameter = 1.0;
//float walkParameter = 2.0;
float stepRand;

Walker w = new Walker(startX, startY, whichWalk, walkParameter); 

int[][] torus = new int[K1][K2];    // to hold visit counts to each point

void setup() {
  size(1000, 1000); 

  background(0);
  noSmooth();
  //  smooth();

  for (int i=0; i<K1; i++) {
    for (int j=0; j<K2; j++) {
      torus[i][j] = 0;
    }
  }

  covertime = 0;
  penult = 0;
  numSteps = 0;
  unvisited = K1 * K2; 
  paused = false;
  favx1 = startX;
  favx2 = startY;
  favN = 0;
}  // end setup()


void draw() {
  // have it draw() drawSteps number of steps all at once.

  for (int i=0; i<drawSteps; i++) {

    switch( whichWalk ) {
    case 0: 
      w.SRWstep( floor(walkParameter) ); 
      break;
    case 1: 
      w.NearlyStdNormalStep( walkParameter ); 
      break;
    default:
    }    
    (torus[w.x1][w.x2])++;

    if ( (torus[w.x1][w.x2]) == 1 ) {  // if this is the first visit to this point,
      unvisited--;  // decrement the unvisited counter
      if (unvisited == 1) {  
        penult = numSteps + 1;
      } else if (unvisited == 0) {  // if this is the LAST point to be hit,
        covertime = numSteps + 1;
        println("cover time: " + covertime);  // tell me and END the walk.
        println("K-approx cover time: " + expCT);
        println("variance of steps: " + w.variance);
        println("K-approx cover time (2nd attempt): " + w.expCTnew);
        println("K-approx favorite point visits: " + expFPvisits);
        int expFPvisitsReal = floor((1 / 3.14159265) * log(covertime) * log(covertime));
        println("expected favorite point visits for actual cover time: " + expFPvisitsReal);
        println("time since previous unvisited point: " + (covertime-penult));
        println("specs of this walk: " + K1 + "x" + K2);
        if (whichWalk==0) {
          println("  SRW with uniform step size (1.." + int(walkParameter) + ")");
        } else if (whichWalk==1) {
          println("  almost-Gaussian 2D with step variance " + walkParameter);
        }
        //        exit();
        println("Press any key to start a new path... ");
        keyPressed();
        setup();  // just start over!
        break; // get out of this for loop
      }
      /*      // HACK: external Green's function bit - abstract this out!
       else if( abs(w.x1) < r && abs(w.x2) < r ) { // if we've hit the disc,
       println("Hit D(0," + r + ") at (" + w.x1 + "," + w.x2 + "). G_{D(0,"
       + r + ")^c}((" + startX + "," + startY + ")) = " + torus[startX][startY]);
       exit();
       }
       */
    } else if ( (torus[w.x1][w.x2]) > favN ) {  // else if we have a new favorite point,
      favx1 = w.x1;
      favx2 = w.x2;
      favN = (torus[w.x1][w.x2]);       // set it as such
    }
    colorVisit(w, torus[w.x1][w.x2]);  // TODO comment this out if you don't want to draw the graph
    numSteps++;
  } // end for i=0 to drawSteps

  // color the favorite point WHITE. [YUCK HACK]
  // it will (hopefully) stick out from one of the clusters of brightest (favorite) color.
  stroke(255, 255, 255);
  point(favx1, favx2);



  // outputs favorite point position to console
  println("Total steps: " + numSteps + " :: Favorite point: (" + favx1 + ", " + favx2 + ") :: " + favN
    + " :: Number unvisited: " + unvisited);

  // TODO output data to file.
}  // end draw()


void keyPressed() {
  if (paused) {
    loop();
    paused = false;
    println("CONTINUING...");
  } else {
    noLoop();
    paused = true;
    println("PAUSED - CLICK THE SQUARE AND PRESS ANY KEY TO CONTINUE");
  }
  if (covertime > 0) {  // if we've hit the end, start over.
    setup();
  }
}


void colorVisit(Walker walk, int numVisits) {

  int colorscale = int(255 * (1+(numVisits % colorSize)) / colorSize);

  if (numVisits <= colorSize) {   // first, grays.
    stroke(colorscale, colorscale, colorscale);
  } else if (numVisits <= 2*colorSize) {  // then purples.
    stroke(colorscale, 0, colorscale);
  } else if (numVisits <= 3*colorSize) {  // then blues.
    stroke(0, 0, colorscale);
  } else if (numVisits <= 4*colorSize) {  // then greens.
    stroke(0, colorscale, 0);
  } else if (numVisits <= 5*colorSize) {  // then yellows.
    stroke(colorscale, colorscale, 0);
  } else if (numVisits <= 6*colorSize) {  // then oranges.
    stroke(255, 176+colorscale/8, 0); // range oranges between ffa000-ffc000. yuck.
  } else if (numVisits <= 7*colorSize) {  // then reds.
    stroke(colorscale, 0, 0);
  } else { // finally, after 7*colorSize visits, just stay on bright red.
    stroke(255, 0, 0);
  }
  point(walk.x1, walk.x2);
} // end colorVisit()


class Walker {
  int x1, x2, walkType, expCTnew;
  float jumpsize, variance;

  Walker(int x, int y, int walkTypeChoice, float jumpsizeChoice) { 
    x1 = x; 
    x2 = y;
    walkType = walkTypeChoice;
    jumpsize = jumpsizeChoice;
    switch(walkType) {
    case 0:  // simple choice out of 4, then uniform on (1..jumpsize)
      variance = 0;
      for (int i=1; i<=jumpsize; i++) variance += (i*i)/(2*jumpsize); // in Z^2, so 2 of each of size i w/ prob 1/(4*jumpsize)
      break;
    case 1: 
      variance = jumpsize * jumpsize;
      break;
    case 2: // simple choice out of 4, then uniform on (0..jumpsize) -- build in some laziness
      variance = 0;
      for (int i=0; i<=jumpsize; i++) variance += (i*i)/(2*(jumpsize+1)); 
      break;
    }  // end switch
    expCTnew = floor((2 / 3.14159265) * (1/variance) * K1 * K2 * log(K1) * log(K2)); // attempt...
    //    expCTnew = floor((2 / 3.14159265) * variance * K1 * K2 * log(K1) * log(K2)); // attempt...
  }  // constructor

  // SRW picks direction. Then Unif(1,2,...,N) picks distance.
  // Pre: 0 < N < K.
  void SRWstep(int N) {  
    int r = int(random(4));
    int n = (N==1) ? 1 : int(random(N));
    /*     int n = 1;
     if(N>1) {  
     stepRand = random(1.0);
     
     }
     */
    switch(r) {
    case 0:  // right n steps
      x1+=n;        
      break;
    case 1:  // up
      x2+=n;        
      break;
    case 2:  // left
      x1-=n;        
      break;
    case 3:  // down
      x2-=n;        
      break;
    default: // do nothing
    }
    // catch out-of-torus points, project them back
    if (x1>=K1) {
      x1-=K1;
    } else if (x1<0) {
      x1+=K1;
    }
    if (x2>=K2) {
      x2-=K2;
    } else if (x2<0) {
      x2+=K2;
    }
  }  // end SRWstep(int N)

  // Walks symmetrically like a 2D normal RV projected onto the torus.
  // Uses Box-Muller with two uniform [0,1).
  // http://en.wikipedia.org/wiki/Box%E2%80%93Muller_transform
  // Multiplying by s makes z1, z2 ~ N(0,s^2) instead of N(0,1).
  void NearlyStdNormalStep(float s) {
    float y1 = random(1.0);
    float y2 = random(1.0);
    // y1, y2 ~ Unif(0,1).
    float z1 = sqrt(-2 * log(y1)) * cos(TWO_PI * y2) * s;
    float z2 = sqrt(-2 * log(y1)) * sin(TWO_PI * y2) * s;
    x1 = (x1 + round(z1)) % K1;
    x2 = (x2 + round(z2)) % K2;
    while ( x1 < 0 ) x1 += K1;
    while ( x2 < 0 ) x2 += K2;    // I should NOT have to do this. :(
    //    print("(y1,y2)=(" + y1 + "," + y2 + ")  ");
    //    print("(z1,z2)=(" + z1 + "," + z2 + ")  ");
    //    println("(x1,x2)=(" + x1 + "," + x2 + ")");
  }  // end NearlyStdNormalStep
} // end class Walker
