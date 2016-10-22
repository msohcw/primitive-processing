PGraphics pg;

int W, H;
PImage base;

void setup() {
  size(800, 530);
  W = 800;
  H = 530;
  background(0);
  base = loadImage("lake.png");
  base.loadPixels();
  loadPixels();

//  int[] h = new int[256];
//  int[] s = new int[256]; 
//  int[] b = new int[256];
//  for(int i = 0; i < 256; ++i) h[i] = s[i] = b[i] = 0;
  
  float h, s, b;
  h = s = b = 0;
  for(int i = 0; i < W*H; ++i){
    color pix = base.pixels[i];
    //h[round(hue(pix))]++; s[round(saturation(pix))]++; b[round(brightness(pix))]++;
    h += hue(pix); s += saturation(pix); b += brightness(pix);
  }
  
  //int H, S, B;
  //int bestH, bestS, bestB;
  //bestH = bestS = bestB = 0;
  //H = S = B = 0;
  
  //for(int i = 0; i < 256; ++i){
  //  if(h[i] > bestH){
  //    bestH = h[i];
  //    H = i;  
  //  }
  //  if(s[i] > bestS){
  //    bestS = s[i];
  //    S = i;
  //  }
  //  if(b[i] > bestB){
  //    bestB = b[i];
  //    B = i;
  //  }
  //}
  h/= W*H; s/= W*H; b/= W*H;
  colorMode(HSB);
  background(color(round(h),round(s),round(b)));
}

int epochs = 100000;
int currentEpoch = 0;
float temperature = 0.1;

boolean inTriangle(PVector p, PVector t1, PVector t2, PVector t3){
  // uses conversion to barycentric coordinates
  float det = (t2.y-t3.y)*(t1.x-t3.x) + (t3.x-t2.x)*(t1.y-t3.y);
  float s =  (t2.y - t3.y) * (p.x - t3.x) + (t3.x - t2.x)*(p.y - t3.y);
  float t =  (t3.y - t1.y) * (p.x - t3.x) + (t1.x - t3.x)*(p.y - t3.y);
  s/= det;
  t/= det;
  return (s >= 0) && (s <= 1) && (t >= 0) && (t <= 1) && (s+t <= 1);
}


float rmse(PVector p, color c){
  float h_bias = 1.3;
  float s_bias = 0.9;
  float b_bias = 0.8;
  color o = base.pixels[floor(p.y) * W + floor(p.x)];
  return sqrt(sq(hue(o) - hue(c))*h_bias + sq(saturation(o) - saturation(c))* s_bias + sq(brightness(o) - brightness(c))* b_bias);
}

int triangles = 0;

float area(PVector t1, PVector t2, PVector t3){
  return 0.5 * abs((t1.x * t2.y) + (t2.x * t3.y) + (t3.x * t1.y) - (t2.x * t1.y) - (t3.x * t2.y) - (t1.x * t3.y));
}

void draw(){
  if(currentEpoch > epochs) return;
  currentEpoch++;
  temperature -= 0.1 * 1/epochs;
  if(currentEpoch % 100 == 0) println(currentEpoch + " epochs , " + triangles + " triangles");
  for(int T = 0; T < 10; ++T){
    PVector[] points = new PVector[3];
    PVector min = new PVector(W, H);
    PVector max = new PVector(0, 0);
    
    for(int i = 0; i < 3; ++i){
      int x, y;
      float expansion = 0.5;
      x = floor(random(W*(1+expansion)) - 0.5*expansion*W);
      y = floor(random(H*(1+expansion)) - 0.5*expansion*H);
      PVector p = new PVector();
      p.x = x;
      p.y = y;
      points[i] = p;
      min.x = min(min.x, x); min.y = min(min.y, y);
      max.x = max(max.x, x); max.y = max(max.y, y);
    }
    
    max.x = min(W-1, max.x); max.y = min(H-1, max.y);
    min.y = max(0, min.y); min.x = max(0, min.x);
    
    int total = ceil((max.y - min.y + 1) * (max.x - min.x + 1));
    color[] copy = new color[total];
    loadPixels();
    updatePixels();
    int k = 0;
    float rmseOriginal, rmseNew;
    int[] h = new int[256];
    int[] s = new int[256]; 
    int[] b = new int[256];
    for(int i = 0; i < 256; ++i) h[i] = s[i] = b[i] = 0;
    
    rmseOriginal = rmseNew = 0;
    for(int i = (int) min.y; i <= (int) max.y; ++i){
      for(int j = (int) min.x; j <= (int) max.x; ++j){
        copy[k] = pixels[i*W + j];
        if(inTriangle(new PVector(j, i), points[0], points[1], points[2])){
          color test = base.pixels[i*W +j];
          h[floor(hue(test))]++;
          s[floor(saturation(test))]++;
          b[floor(brightness(test))]++;
          rmseOriginal += rmse(new PVector(j, i),copy[k]);
        }
        k++;
      }
    }
    int H, S, B;
    int bestH, bestS, bestB;
    bestH = bestS = bestB = 0;
    H = S = B = 0;
    for(int i = 0; i < 256; ++i){
      if(h[i] > bestH){
        bestH = h[i]; H = i;  
      }
      if(s[i] > bestS){
        bestS = s[i]; S = i; 
      }
      if(b[i] > bestB){
        bestB = b[i]; B = i;
      }
    }
    
    noStroke();
    colorMode(HSB);
    color fill = color(H, S, B, random(128));
    fill(fill);
    triangle(points[0].x, points[0].y, points[1].x, points[1].y, points[2].x, points[2].y);
    loadPixels();
    for(int i = (int) min.y; i <= (int) max.y; ++i){
      for(int j = (int) min.x; j <= (int) max.x; ++j){
        if(!inTriangle(new PVector(j, i), points[0], points[1], points[2])) continue;
        rmseNew += rmse(new PVector(j, i),pixels[i*W + j]);
      }
    }
    
    triangles++;
    
    if(rmseNew/rmseOriginal > (1 - temperature*0.1) || random(1) < temperature){
      triangles--;
      k = 0;
      for(int i = (int) min.y; i <= (int) max.y; ++i){
        for(int j = (int) min.x; j <= (int) max.x; ++j){
          pixels[i*W + j] = copy[k];
          k++;
        }
      }
      updatePixels();
    }
  }
}