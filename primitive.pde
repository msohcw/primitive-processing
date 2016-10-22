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
  
  double h, s, b;
  h = s = b = 0;
  for(int i = 0; i < W*H; ++i){
    h += hue(base.pixels[i]);
    s += saturation(base.pixels[i]);
    b += brightness(base.pixels[i]);
  }
  
  h /= W*H;
  s /= W*H;
  b /= W*H;
  
  int H, S, B;
  H = round((float) h);
  S = round((float) s);
  B = round((float) b);
  background(color(H,S,B));
}

int epochs = 50000;
int currentEpoch = 0;

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
  color o = pixels[floor(p.y) * W + floor(p.x)];
  return sqrt(sq(hue(o) - hue(c)) + sq(saturation(o) - saturation(c)) + sq(brightness(o) - brightness(c)));
}


void draw(){
  if(currentEpoch > epochs) return;
  epochs++;
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
  rmseOriginal = rmseNew = 0;
  for(int i = (int) min.y; i <= (int) max.y; ++i){
    for(int j = (int) min.x; j <= (int) max.x; ++j){
      copy[k] = pixels[i*W + j];
      if(inTriangle(new PVector(j, i), points[0], points[1], points[2])) rmseOriginal += rmse(new PVector(j, i),copy[k]);
      k++;
    }
  }
  noStroke();
  boolean erase = false;
  color fill = color(random(255), random(255),random(255),random(255));
  fill(fill);
  triangle(points[0].x, points[0].y, points[1].x, points[1].y, points[2].x, points[2].y);
  
  if(erase){
    loadPixels();
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