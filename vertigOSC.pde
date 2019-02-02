/**
 * vertigosc.pde  (midgatbb)
 *
 * Control MIDI Guitar 2 with a wii Balance Board and OSCulator
 * 
 * Reece Geraghty
 * 
 * v0.01  program changes, left side only
 *
 *
 */

import oscP5.*;
import netP5.*;
import java.util.Map;

OscP5 oscP5;
NetAddress osculatorHost;

int[] selectedInputs = { 0,1,2,3,4,5,6 };
String[] wiiBBSensorName = { "bl","br","tl","tr","sm","vx","vy"  } ;
float[] wiiBBsensor = new float[7];
float[] previousYPos = new float[wiiBBSensorName.length];
float xPos = 0;
int previousWidth, previousHeigth; // used to detect window resize

// midi 
int programCount = 32;
int programNumber = 1;

// osc 
String addressPattern = "/wii/1/balance";
String typeTag = "fffffff";
String eventType = "init";

// time 
int beginEventTime = millis();
int eventTime = beginEventTime;
int lastEventTime = beginEventTime;

// event
String lastEventType = eventType;
float thresholdHit = .12;
float thresholdAdj = .08;
float thresholdOpp = .04;
int hitDelay = 500;
int triggerUp = 0;
int triggerDown = 0;
int triggerSum = 0;

PGraphics graph;
PFont f = createFont("Andale Mono", 20, true);

void setup() {
  size(800,600);
  noFill();
  smooth();
  
  frameRate(25);
  if (frame != null) {
    frame.setResizable(true);
  }
  
  graph = createGraphics(width, height);
  
  drawBackground();

  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this,12001);
  osculatorHost = new NetAddress("127.0.0.1",8001);
}


// incoming oscEvents
void oscEvent(OscMessage theOscMessage) {
  lastEventTime = eventTime;
  lastEventType = eventType;
  int eventTime = millis();
 
  // check message is for us
  if(theOscMessage.checkAddrPattern(addressPattern)==true) {
    if(theOscMessage.checkTypetag(typeTag)) {

//        if (lastEvent.equals("init" == true )){
//           oscP5.send(addressPattern+"/reset",new Object[] {1}, osculatorHost);
//        }
      
      
        // get our vars
        for(int i = 0; i < wiiBBsensor.length; i ++) {
          wiiBBsensor[i] = theOscMessage.get(i).floatValue();
        }
      
        float bl = theOscMessage.get(0).floatValue();
        float br = theOscMessage.get(1).floatValue();
        float tl = theOscMessage.get(2).floatValue();
        float tr = theOscMessage.get(3).floatValue();
        float sm = theOscMessage.get(4).floatValue();
        float vx = theOscMessage.get(5).floatValue();
        float vy = theOscMessage.get(6).floatValue();
 
      
      // program logic goes here
      //
      // ?) process the sum and virtual sensors first to reduce cycles
      //
 
     
      // no action, bypass further events
      if (sm == 0.00) {
          if (eventType.equals("nothing") == true ){
          // nothing to do
          } else {
            lastEventType = eventType;
            eventType = "nothing";
   //         println(eventType+"/"+lastEventType);
          } 
      }
      
      
      // process osc events
      else {
         // conform out of range midi program numbers
          programNumber = (triggerUp-triggerDown);
          if (programNumber < 1) { 
            int programNumber = programCount;
            triggerUp = 0;
            triggerDown = 0;
          }
          if (programNumber > programCount) { 
            int programNumber = 1;
            triggerUp = 0;
            triggerDown = 0;
          }
        
          // program change up
          //
          //
          
          if (eventType.equals("triggerUp") == true) {
          // only trigger after other events
          } else {
            if ((tl>thresholdHit) && (tr<thresholdAdj) && (bl<thresholdOpp) && (br<thresholdOpp)) {
              eventType = "triggerUp";
              oscP5.send(addressPattern+"/"+eventType,new Object[] {programNumber}, osculatorHost);
              triggerUp++;
           //   println(eventType+"/"+(programNumber));
            }
          }

      
        // program change down
        //
        if (eventType.equals("triggerDown") == true) {
        // only trigger after other events
        } else {
          if ((bl>thresholdHit) && (br<thresholdAdj) && (tl<thresholdOpp) && (tr<thresholdOpp)) {
            eventType = "triggerDown";
            oscP5.send(addressPattern+"/"+eventType,new Object[] {programNumber}, osculatorHost);
            triggerDown++;
        //    println(eventType+"/"+(programNumber));
          } 
        }
      
      
      // todo: virtual pedal
      //  
      // if tr and br remain go over .1 for 150ms then go into vpedal mode until they both reach 0
      //
      //
      // 
      
      
      
        }

      }
  }
    

  return;
  
}





void draw() {
  background(0);

  for (int i = 0; i < wiiBBSensorName.length; i++) {
    float OSCval = wiiBBsensor[i];
    float graphHeight = height / selectedInputs.length;
    float yPos = map(wiiBBsensor[selectedInputs[i]], 0, 1, i * graphHeight + graphHeight, i * graphHeight);
 
    previousYPos[i] = yPos;
   
    graph.beginDraw(); 
    graph.strokeWeight(10*(OSCval+.1)); 
    graph.stroke((50+(255*(OSCval+0.01))),(220-(200*(OSCval+0.01))),50);  
    graph.line(xPos, previousYPos[i], xPos+1, yPos);
    graph.endDraw();

    fill(64);
    textFont(f,(int)graphHeight);

    text(wiiBBSensorName[i]+":"+nf(OSCval,0,15), 15, (i + 1) * graphHeight ); 
    image(graph,0,0);
 
  }

  // Restart if graph full or window resized
  if (++xPos >= width || previousWidth != width || previousHeigth != height) {
    previousWidth = width;
    previousHeigth = height;
    xPos = 0;
    drawBackground();
  }
}


void drawBackground() {
  graph = createGraphics(width, height);
  
  strokeWeight(1);                        
  PFont f = createFont("Andale Mono", 10, true);  
  for (int i = 0; i < selectedInputs.length; i++) {
    float graphHeight = height / selectedInputs.length;

    // Different rectangle border and fill colour for alternate graphs
    if(i % 2 == 0) {
      stroke(0);
      fill(0);
    }
    else {
      stroke(32);
      fill(32);
    }
    rect(0, i * graphHeight, width, graphHeight);

  }
}

