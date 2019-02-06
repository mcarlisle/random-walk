// TASEP 1-D simulation
// 
// Michael Carlisle, @mcarlisle
// 2016
// v. 0.1   20160706 building a small sim for students to visualize
// v. 0.1.1 20190206 cleaning up and commenting this old code to post on github

// TASEP = "Totally Asymmetric Simple Exclusion Process"
// https://en.wikipedia.org/wiki/Asymmetric_simple_exclusion_process
// "Totally" refers to the p=1, q=0 case (always move to the right)
// This one is continuous-time, with open boundary conditions.
// Motivation: modeling a simple grid motion with "traffic jam" possibilities
// We hoped to build an elementary model of a single train line, i.e. NYC MTA.
// The Tracy-Widom distribution lurks within...
// Plenty of detail about the process in the console as it runs:
// num = number of active sites
// num blocked = number of times a particle cannot move to the right due to traffic

// TODO generalize entry/line/exit to per-site distributions
// TODO modify distributions per time frame (changing schedules, say)
// TODO weigh against some kind of schedule
// TODO collect all the statistics and interpret them
// TODO ... and lots of other things


boolean paused = false; // pause/unpause with any key


/** GLOBAL CONSTANTS **/
float VERYBIGTIME = 1.0E+20; 
// wayyyyyy beyond our timeframe... outside of time, one might say

int framerate = 30;  // per second
int step = 0;  // master discrete time steps iterated in draw()
int N = 100000; // number of steps granted in this simulation before re- setup()
int L = 50;    // length of line - be careful to adjust size(l,w) below accordingly!
float linerate = 1.0;  
float entryrate = 2.0; // rate of a new entry
float exitrate = 0.5;  // rate of an exit

int gridSquaresPerRow = 10;
int gridfineness = 100;
// Our line is a one-dimensional array. 
int gridLength = 1000;
boolean[] line = new boolean[L]; // from 0 to L-1
int[] numParticles = new int[N]; // how many particles at each time?
int gridWidth = gridLength / L;  // make sure this rounds nicely...
int pointSize;  // size of cell dot when drawing
int x0 = 100; 
int y0 = 100;
int initxpos = x0 + gridWidth / 2; // CONSTANT
int initypos = y0 + gridWidth / 2; // CONSTANT
int xpos = initxpos;
int ypos = initypos;  // position of first grid square's center
color c = color(100, 220, 70, 180); // green...?

// exponential distribution
// return an exponential random variable with parameter lambda
float expRV(float lambda) {
  float x = random(0, 1);
  if (lambda > 0) {
    return -log( 1-x ) / lambda; // inverse transform sampling
// see e.g. https://en.wikipedia.org/wiki/Inverse_transform_sampling
} else {
    return 0;  // error case
  }
}

// nextLineInc returns the next entry time increment.
// this is added to the entry time clock.
float nextLineInc() {
  return expRV(linerate);  
}

// nextEntryInc returns the next entry time increment.
// this is added to the entry time clock.
float nextEntryInc() {
  return expRV(entryrate);  
}

// nextExitInc returns the next entry time increment.
// this is added to the entry time clock.
float nextExitInc() {
  return expRV(exitrate);  
}

// clocks for moving 0 -> 1 -> ... -> L-2 -> L-1
float T = 0.0; // main clock - tracks total continuous time passed
float nextEntry = nextEntryInc(); // clock for entering cell 0
float[] nextLine = new float[L-1];  // clocks on the line
float nextExit = VERYBIGTIME;  // clock for exiting cell L-1 only set if exit waiting
float minLine = VERYBIGTIME;   // min clock on the line
boolean found = true;          // for checking line clocks for who is moving
int foundAt = L-1; 
boolean blocked = false;       // boolean for whether a particle was blocked
int numBlocked[] = new int[N]; // count the number of times a particle is blocked
// cell 0 particle is at (initxpos, initypos). 
// cell k particle is at (initxpos+k*gridWidth, initypos). 
void drawParticle(int k) {
  stroke(255, 0, 0);  // red
  fill(255, 0, 0);  // red
  ellipse(initxpos+k*gridWidth, ypos, pointSize, pointSize); 
  // fill in with "particle" color
}

void clearParticle(int k) {  
  stroke(0, 0, 0);  // black
  fill(0, 0, 0);  // black
  ellipse(initxpos+k*gridWidth, ypos, pointSize, pointSize); 
  // fill in with "particle" color
}


void setup() {
  size(1200, 200);  // length, width - use a high-res screen!
  background(0);
  paused = false;

  if(gridWidth >= 6) {
    pointSize = 5;
  } else {
    pointSize = 2;
  }

  for (int i=0; i<L-1; i++) {
    line[i] = false; // no particle in any cell to start
    nextLine[i] = VERYBIGTIME;  // each slot's clock is at Infinity to start
  }
  line[L-1] = false;  // nobody's perfect, even for loops on mismatched lists

  T = nextEntryInc(); // start the clock off with 1 particle on cell 0
  line[0] = true;     // there's a particle on cell 0
  nextLine[0] = T + nextLineInc();  // particle on cell 0's clock is running
  nextEntry = T + nextEntryInc();   // next entry is always possible
  nextExit = VERYBIGTIME;      // next exit should only get scheduled if waiting 
  println("First times: nextEntry = " + nextEntry + ", nextExit = " + nextExit);
  
  for(int i=0; i<N; i++) {
    numParticles[i] = 0;
    numBlocked[i] = 0;
  }
  
  frameRate(framerate);
  //  noLoop();  // put this back in if we want to be able to pause...
}//setup()


void draw() { // ONE FRAME
  background(0);

    // then, draw the grid.
    xpos = initxpos;
    //void gridWHC(int x0, int y0, int w, int h, int cellw, color c) {
    gridWHC(x0, y0, gridLength, gridWidth, gridWidth, c);

    step++;
    blocked = false;

    // run exponential clocks for each particle that is present. 
    // if a clock "goes off", i.e. it's the next minimum, 
    // move the particle if there is room.
    // either way, reset that clock.

    // find the next alarm to go off, and move a particle accordingly.
    minLine = min(nextLine); // VERYBIGTIME shouldn't be here unless no particles 
    T = min(minLine, nextEntry, nextExit);
    // should always be the smallest time > T to fire.

    print("step = " + step + ": minLine = " + minLine);
    println(", nextEntry = " + nextEntry + ", nextExit = " + nextExit);
    print("... winner is ");
    
    if(T == nextExit) {   // a particle is exiting
      print("nextExit... ");
      if( line[L-1] ) {
        line[L-1] = false;      // clear it out
        println(" bye!");
      } else {   // nobody's actually leaving, just an empty alarm
        println(" no one... is leaving..."); // this shouldn't happen
      }
      nextExit = VERYBIGTIME;  // kill exit clock since no one is there now
    } else if(T == minLine) { // a particle is moving
      // first, which is it?
      print("minLine... ");
      found = false;
      for(int k=0; (k<L-1) && (!found); k++) {
        if(T == nextLine[k]) {
          found = true;
          foundAt = k;
          print(" at cell " + k);
        }
      }
      if(!found) {
        println("Problem at time T = " + T + ": motion alarmed but didn't happen");
      } else {  // foundAt < L so go ahead and move, if possible
        if( !line[foundAt+1] ) {                     // if no one is at cell k+1...
          line[foundAt] = false;                     // cell k is moving...........
          line[foundAt+1] = true;                    // ............... to cell k+1
          nextLine[foundAt] = VERYBIGTIME;           // cell k's clock killed
          // cell k+1's clock activated... unless it's cell L-1, then forget it.
          if(foundAt < L-2) {
            nextLine[foundAt+1] = T + nextLineInc(); 
            println("... moved!");
          } else { // foundAt = L-2 and is moving into exit positioning
            nextExit = T + nextExitInc();
            println("... preparing for exit!");
          }          
        } else { // else, if cell k+1 is occupied, nobody moves! BLOCKED
          println("... blocked.");
          nextLine[foundAt] = T + nextLineInc();  // reset cell k's clock
          blocked = true;
        }
      }
    } else if(T == nextEntry) { // a particle is entering
      print("nextEntry... ");
      if( !(line[0]) ) {            // if the entry position is open
        line[0] = true;             // hello, new particle
        println("welcome!");
        nextLine[0] = T + nextLineInc(); // when's this one going to try to move?
      } else {
        println("blocked from entering.");  // BLOCKED FROM ENTERING
        blocked = true;
      }
      nextEntry = T + nextEntryInc();  // when's the next one queued up to enter?
    }
    
    println("Time step=" + step + " (analog time T = " + T + "): ");
    for (int j=0; j<L; j++) {
      if( line[j] ) { 
        print(j + " ");
        drawParticle(j);
        (numParticles[step])++;
      }
    }
    println("\n... num = " + numParticles[step]);
    if(blocked) {
      numBlocked[step] = numBlocked[step-1] + 1;
    } else {
      numBlocked[step] = numBlocked[step-1];
    }
    println("... num blocked = " + numBlocked[step]);
}//draw()



void keyPressed() {
  if(paused) {
    loop();
    paused = false;
    println("CONTINUING...");
  } else {
    noLoop();
    paused = true;
    println("PAUSED - CLICK THE GRID AND PRESS ANY KEY TO CONTINUE");
  }
  if(step > N) {  // if we've hit the end, start over.
    setup();   
  }
}


//========================================================
// DO NOT TOUCH BELOW HERE - THIS IS FOR THE GRID ONLY!!!!
// https://forum.processing.org/beta/num_1195788276.html
//========================================================
// grid of given width/height

void gridWHC(int x0, int y0, int w, int h, int cellw, color c) {
  stroke(c); 
  for (int iy=y0; iy<=y0+h; iy+=cellw) line(x0, iy, x0+w, iy); 
  for (int ix=x0; ix<=x0+w; ix+=cellw) line(ix, y0, ix, y0+h);
}//gridWHC()

void gridWHC(int w, int h, int cellw, color c) { 
  gridWHC(0, 0, w, h, cellw, c);
}//gridWHC()

void gridWHC(int x0, int y0, int w, int h, color c) { 
  gridWHC(x0, y0, w, h, 10, c);
}//gridWHC()

void gridWHC(int w, int h, color c) { 
  gridWHC(0, 0, w, h, 10, c);
}//gridWHC()

void gridWH(int x0, int y0, int w, int h, int cellw) { 
  gridWHC(x0, y0, w, h, cellw, color(20, 100, 100, 80));
}//gridWH()

void gridWH(int w, int h, int cellw) { 
  gridWHC(0, 0, w, h, cellw, color(20, 100, 100, 80));
}//gridWH()

void gridWH(int x0, int y0, int w, int h) { 
  gridWHC(x0, y0, w, h, 10, color(20, 100, 100, 80));
}//gridWH()

void gridWH(int w, int h) { 
  gridWHC(0, 0, w, h, 10, color(20, 100, 100, 80));
}//gridWH()

//========================================================
// grid of given #row/#column

void gridMNC(int x0, int y0, int mrow, int ncol, int cellw, color c) { 
  stroke(c); 
  int x1=x0+ncol*cellw;
  int y1=y0+mrow*cellw;
  for (int i=0, iy=y0; i<=mrow; i++, iy+=cellw) line(x0, iy, x1, iy);
  for (int i=0, ix=x0; i<=ncol; i++, ix+=cellw) line(ix, y0, ix, y1);
}//gridMNC()

void gridMNC(int mrow, int ncol, int cellw, color c) { 
  gridMNC(0, 0, mrow, ncol, cellw, c);
}//gridMNC()

void gridMNC(int x0, int y0, int mrow, int ncol, color c) { 
  gridMNC(x0, y0, mrow, ncol, 10, c);
}//gridMNC()

void gridMNC(int mrow, int ncol, color c) { 
  gridMNC(0, 0, mrow, ncol, 10, c);
}//gridMNC()

void gridMN(int x0, int y0, int mrow, int ncol, int cellw) { 
  gridMNC(x0, y0, mrow, ncol, cellw, color(20, 100, 100, 80));
}//gridMN()

void gridMN(int mrow, int ncol, int cellw) { 
  gridMNC(0, 0, mrow, ncol, cellw, color(20, 100, 100, 80));
}//gridMN()

void gridMN(int x0, int y0, int mrow, int ncol) { 
  gridMNC(x0, y0, mrow, ncol, 10, color(20, 100, 100, 80));
}//gridMN()

void gridMN(int mrow, int ncol) { 
  gridMNC(0, 0, mrow, ncol, 10, color(20, 100, 100, 80));
}//gridMN()
