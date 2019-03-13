// stochastic time random walk simulation
// michael carlisle, michael laufer
// 2012-2014


// randstep returns a simple asymmetric random walk value of +1 or -1.
int randstep(float mean, float SD) {
  float x = random(0,1);
  if(x < 0.5*(1+mean/SD)) {  // up prob p = (1/2)*(1+mean/SD)
    return 1;
  } else { return -1; }
}  // randstep(mu, sigma)


int usualtimetracker = 0;  // use this to track time via console

int framerate = 10;  // per second

int K1 = 1500; // size of applet window
int K2 = 900; // size of applet window
int gridSquaresPerRow = 100;
int gridfineness = 10;
//int gridfineness = (K1-1)/gridSquaresPerRow;
// meta-time runs from 0 to T.
int T = 20000000;  // total time horizon
float mu = 0.9;  // mean of usual time RW
float sigma = 1;  // SD of usual time RW
int pointSize = 5;

// usual time is just a RW indexed by meta-time.
int[] usualtime = new int[T+1];

// spatial RW is a 2-dim RW indexed first by meta-time, then plotted by usual time.
int[] RWX = new int[T+1];
int[] RWY = new int[T+1];
// for now, this RW will just be simple symmetric RW in 2-dim (on the torus)
// we can complicate it later.

int[] currentmetas = new int[T+1];  // this stores all "current" meta-times.
int copies = 0;  // track # copies of the point at "current" usual time
int[] timedir = new int[T]; // this stores the slopes of the usual time curve.


void setup() {
  size(1500,900); // had to change variables to numbers in Processing 3
  // NOTE: These numbers MUST match K1 and K2!
  background(0);

  usualtime[0] = 0;  // start at 0
  RWX[0] = floor(K1/2); // start (X,Y) in the middle of the screen
  RWY[0] = floor(K2/2); 
  for(int i=1; i<T; i++) {
    usualtime[i] = usualtime[i-1] + randstep(mu, sigma);  // usual time is a RW on randstep

    // later, put the spatial RW generation in its own step function, ugh
    // maybe borrow my old Walker class??
    // 20140120: added "stay still" chance on RW
    int p = int(random(5));
    switch(p) {
      case 0:  // right n steps
        RWX[i]=RWX[i-1]+gridfineness;
        // catch out-of-torus points, project them back
        if(RWX[i]>=K1) { RWX[i]-=K1; }
        RWY[i]=RWY[i-1];        
      break;
      case 1:  // up
        RWX[i]=RWX[i-1];
        RWY[i]=RWY[i-1]+gridfineness;        
        if(RWY[i]>=K2) { RWY[i]-=K2; }
      break;
      case 2:  // left
        RWX[i]=RWX[i-1]-gridfineness;
        if(RWX[i]<0) { RWX[i]+=K1; }
        RWY[i]=RWY[i-1];        
      break;
      case 3:  // down
        RWX[i]=RWX[i-1];
        RWY[i]=RWY[i-1]-gridfineness;        
        if(RWY[i]<0) { RWY[i]+=K2; }
      break;
      case 4:  // stay still
        RWX[i]=RWX[i-1];
        RWY[i]=RWY[i-1];        
      break;
    default: // do nothing
    }
  }

  int mintime = min(usualtime);
//  usualtimetracker = mintime;
// 20140120: changed usualtimetracker to start at 0...
  usualtimetracker = 0;
  int maxtime = max(usualtime);

  frameRate(framerate);
//  noLoop();  // put this back in if we want to be able to pause...
}//setup()


void draw() {
//  gridWH(400,400,20);
//  gridWH(4,4,130,130,20);
//  gridMNC(8,8,4,4,20,color(230,60,100,80));

  background(0);
//  gridMNC(0,0,gridfineness,gridfineness,gridSquaresPerRow,color(100,220,70,180));

// find all the meta-times for the current usual time. store # copies in copies.
// then plot all the spatial points for these meta-times.
  copies = 0;
  for(int i=0; i<T-1; i++) {
    if( usualtime[i] == usualtimetracker ) {
      currentmetas[copies] = i;
      copies++;
      if( (i>0) && (usualtime[i-1] < usualtime[i]) && (usualtime[i] < usualtime[i+1]) ) { 
        timedir[i] = 1;  // upward slope
      } else if( (i>0) && (usualtime[i-1] > usualtime[i]) && (usualtime[i] > usualtime[i+1]) ) { 
        timedir[i] = -1; // downward slope
      } else if( (i>0) && (usualtime[i-1] < usualtime[i]) && (usualtime[i] > usualtime[i+1]) ) { 
        timedir[i] = 2; // upward peak
      } else { timedir[i] = -2; }  // downward peak
    }
  }  // now copies = # particles at usual time usualtimetracker, 
  // and currentmetas[] holds the meta-times of those positions.
  
// plot the points for this iteration.
  println("(usual) time = " + usualtimetracker + " :: number of copies = " + copies);

  for(int i=0; i<copies; i++) {
   //println("(x,y) = (" + RWX[currentmetas[i]] + ", " + RWY[currentmetas[i]] + ")");
   if( timedir[currentmetas[i]] == 1 ) {
     stroke(0,0,255);  // forward time = blue
   } else if( timedir[currentmetas[i]] == -1 ) {
     stroke(255,0,0);  // backward time = red
   } else if( timedir[currentmetas[i]] == 2 ) {
     stroke(0,255,0);  // upward peak time = green
   } else if( timedir[currentmetas[i]] == -2 ) {
     stroke(255,255,255);  // downward peak time = white
   } 
   ellipse(RWX[currentmetas[i]], RWY[currentmetas[i]], pointSize, pointSize);
  }
  
  usualtimetracker++;
  
}//draw()




//========================================================
// DO NOT TOUCH BELOW HERE - THIS IS FOR THE GRID ONLY!!!!
//========================================================
// grid of given width/height

void gridWHC(int x0, int y0, int w, int h, int cellw, color c) {
  stroke(c); 
  for (int iy=y0; iy<=y0+h; iy+=cellw) line(x0, iy, x0+w, iy); 
  for (int ix=x0; ix<=x0+w; ix+=cellw) line(ix, y0, ix, y0+h); 
}//gridWHC()

void gridWHC(int w, int h, int cellw, color c) { 
  gridWHC(0,0,w,h,cellw,c); 
}//gridWHC()

void gridWHC(int x0, int y0, int w, int h, color c) { 
  gridWHC(x0,y0,w,h,10,c); 
}//gridWHC()

void gridWHC(int w, int h, color c) { 
  gridWHC(0,0,w,h,10,c); 
}//gridWHC()

void gridWH(int x0, int y0, int w, int h, int cellw) { 
  gridWHC(x0,y0,w,h,cellw,color(20,100,100,80)); 
}//gridWH()

void gridWH(int w, int h, int cellw) { 
  gridWHC(0,0,w,h,cellw,color(20,100,100,80)); 
}//gridWH()

void gridWH(int x0, int y0, int w, int h) { 
  gridWHC(x0,y0,w,h,10,color(20,100,100,80)); 
}//gridWH()

void gridWH(int w, int h) { 
  gridWHC(0,0,w,h,10,color(20,100,100,80)); 
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
  gridMNC(0,0,mrow,ncol,cellw,c); 
}//gridMNC()

void gridMNC(int x0, int y0, int mrow, int ncol, color c) { 
  gridMNC(x0,y0,mrow,ncol,10,c); 
}//gridMNC()

void gridMNC(int mrow, int ncol, color c) { 
  gridMNC(0,0,mrow,ncol,10,c); 
}//gridMNC()

void gridMN(int x0, int y0, int mrow, int ncol, int cellw) { 
  gridMNC(x0,y0,mrow,ncol,cellw,color(20,100,100,80)); 
}//gridMN()

void gridMN(int mrow, int ncol, int cellw) { 
  gridMNC(0,0,mrow,ncol,cellw,color(20,100,100,80)); 
}//gridMN()

void gridMN(int x0, int y0, int mrow, int ncol) { 
  gridMNC(x0,y0,mrow,ncol,10,color(20,100,100,80)); 
}//gridMN()

void gridMN(int mrow, int ncol) { 
  gridMNC(0,0,mrow,ncol,10,color(20,100,100,80)); 
}//gridMN()