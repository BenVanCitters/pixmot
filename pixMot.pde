import processing.video.*;
//private MovieMaker mm;
import codeanticode.gsvideo.*;
Capture capture;

private boolean record = false;

volatile int[] newIndx;
int[] pixBuffer;
float[] sinLkUp;
boolean runningApp = true;
MotionThread mThread = new MotionThread();
float vBufferFrameRate = 0;

void setup()
{
//  size(displayWidth,displayHeight, P2D);
  size(1280,720);  
  capture = new Capture(this, width,height, 60);
  capture.start();
  //  frameRate(2);
//  if (record)
//    mm = new MovieMaker(this, width, height, "mzoosdsasDraw3_.mpg", 
//    30, MovieMaker.MOTION_JPEG_B, MovieMaker.HIGH);

  sinLkUp = new float[(int)(TWO_PI*200.9999999)];
  for(int i = 0; i < sinLkUp.length; i++)
  {
    sinLkUp[i] = sin(TWO_PI*i/sinLkUp.length);
  }

  newIndx = new int[width*height];
  pixBuffer = new int[width*height];
  setupIndicies();
  mThread.start();
}

float sn(float t)
{
  //t = abs(t) + TWO_PI;
  t+=TWO_PI*(abs((int)(t/TWO_PI)) + 1);
  t = t%TWO_PI;
  t *= 200;//(sinLkUp.length*1.0);
  return sinLkUp[(int)(t)];
}

float snOsc(float t)
{
  return (sn(t)+1)/2;
}

void setupIndicies()
{
  //loadPixels();
  float tm = millis()/1000.0;
  //  tm= tm% 3.f;
  int wxh = width*height;
  float rotCtr[] = new float[]{width*snOsc(tm/4),height*snOsc(500+tm/5)};
  
  for (int i = 0; i< newIndx.length;i++)
  {
    float x = (i)%(width*1.0);
    float y = (i)/width;
    //    
    //    y -= height/2.0;
    //    x -= width/2.0;
    
    float ang = atan2(y-rotCtr[0],x-rotCtr[1]);
    float dist = .1+dist(x,y,rotCtr[0],rotCtr[1]);
    float d = sn(tm/8)*dist/30; 
    x += (d*cos(tm/2+ang+HALF_PI));    
    y += (d*sn(tm/2+ang+HALF_PI));
    //    
    //    x = i%width;
    //    y = i/width;
    //    x+= (int)(random(3)-1.5);
    //    y+= (int)(random(3)-1.5);
    y = (y+/*x*snOsc(tm/5)*.05 +*/ 1.*sn((x+tm)/(20.*snOsc(tm/2.1))));
    x = (x-/*y*snOsc(tm/3)*.07 +*/ 4.*sn((y+tm/2)/(18.*snOsc(tm/5))));
    
    int ny = (int)(y);
    int nx = (int)(x);
    ny = (ny%height) * width;
    nx = nx%width;

  //actions must be completed in one step
  //so that reads from this array don't return
  //out of bounds indicies
    int tmpIndex = (ny + nx); 
    newIndx[i] = (tmpIndex%(wxh) + (wxh))%(wxh);
  }
}

void captureEvent(Capture c) {
  c.read();
}

void draw()
{ 
  loadPixels();
  
  for (int i = 0; i < pixels.length; i++)
  {
    pixBuffer[i] = pixels[newIndx[i]];
//    pixels[i] = pixels[newIndx[i]];
//    pixels[i] = lerpColor(pixels[i], pixels[newIndx[i]], .1);
  }
  
  float colorMult = 1.f + .1f*sn(155+millis()/8000.0);
  float capToBufPct = .01f + .99f*snOsc(millis()/6033.0);
  float bufToScrPct = .03f + .5*snOsc(500+millis()/3000.0);

  capture.loadPixels();  
  
  for (int i = 0; i < pixels.length; i++)
  {    
    pixels[i] =lerpColor(pixels[i], capture.pixels[i], capToBufPct);
    pixels[i] =lerpColor(pixels[i], (int)(pixBuffer[i]*colorMult), bufToScrPct);
//    pixels[i] =lerpColor(pixels[i], Float.floatToIntBits(pixBuffer[i]*colorMult), bufToScrPct);
//    pixels[i] = capture.pixels[newIndx[i]];
  }
  
  updatePixels();

  println("pixMotCam framerate: " + frameRate + " vBufferFrameRate: " + vBufferFrameRate + "\ncapToBufPct: "  + capToBufPct + 
          " bufToScrPct: " + bufToScrPct + " colorMult: " + colorMult);
//  if (record)
//    mm.addFrame();
}


//void movieEvent(GSMovie myMovie) 
//{
//  myMovie.read();
//}

void stop()
{
//  if (record)
//    mm.finish();
  runningApp = false;
  super.stop();
}
void exit()
{
//  if (record)
//    mm.finish();
  runningApp = false;
  super.exit();
}

public class MotionThread extends Thread 
{
  public void run() 
  {
    while(runningApp)
    {
      long frameStart = millis();
      setupIndicies(); 
      vBufferFrameRate = (1000.0/(millis()-frameStart));
//      println("vframerate: " + (1000.0/(millis()-frameStart)));
    }
  }
}

