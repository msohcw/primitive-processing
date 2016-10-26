PImage base;
color[] copy;

int W = 200; 
int H = 133;
float expansion = 0.1;
float density = -30;
float global = -35000;

int left, right, up, down;
float rmseTotal = 0;
int pix = 0;
int triangles = 0;

PVector[] pts = new PVector[3];
PVector boundMax = new PVector(0, 0);
PVector boundMin = new PVector(W, H);

float rmse(PVector p, color c){
  color o = base.pixels[floor(p.y) * W + floor(p.x)];
  return sqrt(sq(red(o) - red(c))*h_bias + sq(green(o) - green(c))* s_bias + sq(blue(o) - blue(c))* b_bias);
}

float area(PVector t1, PVector t2, PVector t3){
  return 0.5 * abs((t1.x * t2.y) + (t2.x * t3.y) + (t3.x * t1.y) - (t2.x * t1.y) - (t3.x * t2.y) - (t1.x * t3.y));
}

boolean inTriangle(PVector p, PVector t1, PVector t2, PVector t3){
  // uses conversion to barycentric coordinates
  float det = (t2.y-t3.y)*(t1.x-t3.x) + (t3.x-t2.x)*(t1.y-t3.y);
  float s =  (t2.y - t3.y) * (p.x - t3.x) + (t3.x - t2.x)*(p.y - t3.y);
  float t =  (t3.y - t1.y) * (p.x - t3.x) + (t1.x - t3.x)*(p.y - t3.y);
  s/= det;
  t/= det;
  return (s >= 0) && (s <= 1) && (t >= 0) && (t <= 1) && (s+t <= 1);
}

void setup() {
  size(200, 133);
  copy = new color[W * H];
  base = loadImage("lake_xs.png");
  
  base.loadPixels();
  loadPixels();

  left = round(0 - W * expansion);
  right = round(W * (1 + expansion));
  up = round(0 - H*expansion);
  down = round(H * (1 + expansion));
  
  float h, s, b;
  h = s = b = 0;
  
  for(int i = 0; i < W*H; ++i){
    color pix = base.pixels[i];
    h += red(pix); s += saturation(pix); b += brightness(pix);
  }
  
  h/= W*H; s/= W*H; b/= W*H;
  colorMode(HSB);
  background(color(round(h),round(s),round(b)));
  
  for(int i = 0; i < W*H; ++i) rmseTotal += rmse(new PVector(i%W, floor(i/W)), color(#ffffff));
}

void updateBounds(int i){
  if(pts[i].x < boundMin.x) boundMin.x = pts[i].x;
  if(pts[i].x > boundMax.x) boundMax.x = pts[i].x;
  if(pts[i].y < boundMin.y) boundMin.y = pts[i].y;
  if(pts[i].y > boundMax.y) boundMax.y = pts[i].y;
}

void clipBounds(){
  boundMax.x = min(W-1, boundMax.x);
  boundMin.x = max(0, boundMin.x);
  boundMax.y = min(H-1, boundMax.y);
  boundMin.y = max(0, boundMin.y);
}

void shrink(){
  PVector average = new PVector(0,0);
  float av_dist = 0;
  for(int i = 0; i < 3; ++i){
    average.x += pts[i].x;
    average.y += pts[i].y;
    av_dist += dist(pts[i].x, pts[i].y, average.x, average.y);
  }
  average.x/=3;
  average.y/=3;
  for(int i = 0; i < 3; ++i){
    float factor = 0.995;
    pts[i].x = factor * pts[i].x + (1-factor) * average.x;
    pts[i].y = factor * pts[i].y + (1-factor) * average.y;
  }
}

int tries = 0;
Boolean repeat = false;
PVector transform = new PVector(0,0,0);
PVector[] oldPts = new PVector[3];

void draw(){
  for(int k = 0; k < 100; ++k){
    loadPixels();
    updatePixels();
    
    if(pts[0] == null){
      tries = 0;
      boundMax = new PVector(0, 0);
      boundMin = new PVector(W, H);
      pts[0] = new PVector(random(left, right), random(up, down));
      pts[1] = new PVector(random(left, right), random(up, down));
      pts[2] = new PVector(random(left, right), random(up, down));
      for(int i = 0; i < 3; ++i) updateBounds(i);
      arrayCopy(pts, oldPts);
      arrayCopy(pixels, copy);
    }else{
     tries++;
     // erase
     arrayCopy(copy, pixels);
     updatePixels();
     // check if too many tries or triangle too small
     if(tries > 10000 || area(pts[0], pts[1], pts[2]) < 0.01 * W * H){
        tries = 0;
        pts = new PVector[3];
        return;
     }
     // mutate
     arrayCopy(pts, oldPts);
     if(repeat){
       // reapply positive mutation
       repeat = false;
       pts[(int) transform.z].x += transform.x;
       pts[(int) transform.z].y += transform.y;
     }else{
       // try new mutation
       int mutated = floor(random(3));
       transform.z = mutated;
       transform.x = round(random(-5,5));
       transform.y = round(random(-5,5));
       pts[mutated].x += transform.x;
       pts[mutated].y += transform.y;
       pts[mutated].x = min(right, max(left, pts[mutated].x));
       pts[mutated].y = min(down, max(up, pts[mutated].y));
       updateBounds(mutated);
     }
    }
    shrink();
    clipBounds();
    
    float r, g, b;
    r = g = b = 0
    float rmseChange = 0;
    int A = 0;
    // sum current RMSE
    for(int i = (int) boundMin.y; i <= (int) boundMax.y; ++i){
      for(int j = (int) boundMin.x; j <= (int) boundMax.x; ++j){
        if(inTriangle(new PVector(j, i), pts[0], pts[1], pts[2])){
          color tgt = base.pixels[i*W +j];
          // color curr = pixels[i*W +j];
          r += red(tgt);
          g += green(tgt);
          b += blue(tgt);
          rmseChange -= rmse(new PVector(j, i) , curr);
          A++;
        }
      }
    } 
    
    r /= A; g /= A; b /= A;
    noStroke();
    colorMode(RGB);
    fill(r,g,b,128);
    triangle(pts[0].x, pts[0].y, pts[1].x, pts[1].y, pts[2].x, pts[2].y);
    
    loadPixels();
    updatePixels();
    
    // add new RMSE
    for(int i = (int) boundMin.y; i <= (int) boundMax.y; ++i){
      for(int j = (int) boundMin.x; j <= (int) boundMax.x; ++j){
        if(inTriangle(new PVector(j, i), pts[0], pts[1], pts[2])){
          color curr = pixels[i*W +j];
          rmseChange += rmse(new PVector(j, i) , curr);
        }
      }
    }
    
    // if positive change in terms of RMSE density or global RMSE, apply
    if(rmseChange/A < density || rmseChange < global){
      pts = new PVector[3];
      rmseTotal += rmseChange;
      triangles++;
      println("triangles: " + triangles);
    }else if(rmseChange/A < density/2){
      repeat = true;
    }else if(rmseChange > 0){
      // undo mutation
      arrayCopy(oldPts, pts);
    }
  }
}
