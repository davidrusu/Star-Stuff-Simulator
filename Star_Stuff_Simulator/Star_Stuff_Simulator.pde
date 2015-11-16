float sqrt2 = sqrt(2);
float maxSpeed = 5;
int nParticles = 250000;
int nParticlesStep = 10000;
float cellW, cellH; // set at setup

Vec[][] grid = new Vec[200][200];
Vec[][] buffer = new Vec[grid.length][grid[0].length];
float[][] particles;
float[][] vels;

ArrayList<Vec> blackHoles = new ArrayList<Vec>();
ArrayList<Vec> bhVels = new ArrayList<Vec>();

boolean drawingField = false;
boolean showMenu = true;

void setup() {
  size(displayWidth, displayHeight);
  cellW = ((float) width) / grid.length;
  cellH = ((float) height) / grid[0].length;
  reset();
  noSmooth();
}

void reset() {
  particles = new float[nParticles][2];
  vels = new float[nParticles][2];
  int thickness = max(1, clamp(0, particles.length, particles.length / 50000));
  int spiralPoints = particles.length / thickness;
  for (int i = 0; i < spiralPoints; i++) {
    float ratio = ((float)i)/spiralPoints;
    float radius = height / 2;
    float rad = (radius * 2 * PI * i / spiralPoints / 50);
    float r = radius * ratio;
    for (int j = 0; j < thickness; j++) {
      float ray = r + 20 * ((float) j / thickness) ;
      particles[i * thickness + j] = new float[]{width/2 + sin (rad)*ray, height/2 + cos(rad)*ray};
      vels[i * thickness + j] = new float[]{0, 0};
    }
  }

  float s = 0.001;
  for (int x = 0; x < grid.length; x++) {
    for (int y = 0; y < grid[x].length; y++) {
      grid[x][y] = new Vec(random(-s, s), random(-s, s));
      //      grid[x][y] = new Vec(0, 0);
      buffer[x][y] = new Vec(random(-s, s), random(-s, s));
    }
  }
  blackHoles.clear();
}

void keyPressed() {
  if (key == 'r') {
    reset();
  } else if (key == 'f') {
    drawingField = !drawingField;
  } else if (keyCode == UP) {
    nParticles += nParticlesStep;
  } else if (keyCode == DOWN) {
    nParticles = max(0, nParticles - nParticlesStep);
  } else if (key == 'm') {
    showMenu = !showMenu;
  }
}

void mouseClicked() {
  if (mouseButton == RIGHT) {
    blackHoles.add(new Vec(mouseX, mouseY));
    bhVels.add(new Vec(0, 0));
  }
}

void attract(float ax, float ay, float s) {
  int mx = (int) (ax / cellW);
  int my = (int) (ay / cellH);
  for (int x = 0; x < grid.length; x++) {
    for (int y = 0; y < grid[x].length; y++) {
      float dx = ax - x * cellW;
      float dy = ay - y * cellH;
      float d = max(0.1, sqrt(dx * dx + dy * dy));
      float sd = s/(d*d);
      grid[x][y].add(dx/d * sd, dy/d * sd);
    }
  }
}

void update() {
  if (mousePressed && mouseButton == LEFT) {
    attract(mouseX, mouseY, 10000);
  }
  updateBlackHoles();
  updateGrid();
  updateParticles();
}

void updateParticles() {
  for (int i = 0; i < particles.length; i++) {
    float[] p = particles[i];
    float[] v = vels[i];
    float px = p[0];
    float py = p[1];
    float vx = v[0];
    float vy = v[1];
    int x = min(grid.length - 1, max(0, (int) ((px + cellW / 2) / cellW)));
    int y = min(grid[x].length - 1, max(0, (int) ((py + cellH / 2) / cellH)));
    float transferRate = 0.5;
    Vec g = grid[x][y];
    float dvx = g.x - vx;
    float dvy = g.y - vy;
    vx += dvx * transferRate;
    vy += dvy * transferRate;
    float effect = 1 / (cellW * cellH / 10);
    grid[x][y].addScaled(-dvx, -dvy, effect);

    if (px < 0) {
      px = 0;
      vx *= -1;
    }
    if (px > width) {
      px = width;
      vx *= -1;
    }
    if (py < 0) {
      py = 0;
      vy *= -1;
    }
    if (py > height) {
      py = height;
      vy *= -1;
    }
    px += vx;
    py += vy;
    p[0] = px;
    p[1] = py;
    v[0] = vx;
    v[1] = vy;
  }
}

int clamp(int l, int u, int c) {
  return min(u, max(l, c));
}

float clamp(float l, float u, float c) {
  return min(u, max(l, c));
}

void updateBlackHoles() {
  for (int i = 0; i < blackHoles.size(); i++) {
    Vec bh = blackHoles.get(i);
    Vec bhv = bhVels.get(i);

    int x = clamp(0, grid.length -1, (int) ((bh.x + cellW / 2) / cellW));
    int y = clamp(0, grid[x].length - 1, (int) ((bh.y + cellH / 2) / cellH));
    Vec g = grid[x][y];
    float force = clamp(0, 0.5, g.dist());
    
    bhv.addScaled(g.norm(), force * 0.1);
    bhv.addScaled(width / 2 - bh.x, height / 2 - bh.y, 0.0001);
    bhv.scale(0.999); // dampening
    bh.add(bhv);
    attract(bh.x, bh.y, 1000);
  }
}

void updateGrid() {
  float propRate = 0.01;
  for (int x = 0; x < grid.length; x++) {
    for (int y = 0; y < grid[x].length; y++) {
      Vec v = buffer[x][y];
      v.set(grid[x][y]);
      if (x < grid.length - 1) {
        v.addScaled(grid[x+1][y], propRate);
        v.add(1, 0);
        if (y < grid[x].length - 1) {
          v.addScaled(grid[x+1][y+1], propRate / sqrt2);
          v.add(1/sqrt2, 1/sqrt2);
        }
        if (y > 0) {
          v.addScaled(grid[x+1][y-1], propRate / sqrt2);
          v.add(1/sqrt2, -1/sqrt2);
        }
      }
      if (x > 0) {
        v.addScaled(grid[x-1][y], propRate);
        v.add(-1, 0);
        if (y < grid[x].length - 1) {
          v.addScaled(grid[x-1][y+1], propRate / sqrt2);
          v.add(-1/sqrt2, 1/sqrt2);
        }
        if (y > 0) {
          v.addScaled(grid[x-1][y-1], propRate / sqrt2);
          v.add(-1/sqrt2, -1/sqrt2);
        }
      }
      if (y < grid[x].length - 1) {
        v.addScaled(grid[x][y+1], propRate);
        v.add(0, 1);
      }
      if (y > 0) {
        v.addScaled(grid[x][y-1], propRate);
        v.add(0, -1);
      }

      float pressure = 1;
      if (x == 0 || x == grid.length-1 || y == 0 || y == grid[0].length-1) {
        v.scale(pressure);
      }

      float realD = max(0.000001, v.dist());
      float d = min(maxSpeed, realD);
      v.scale(d/realD);
    }
  }

  Vec[][] temp = grid;
  grid = buffer;
  buffer = grid;
}

void draw() {
  update();
  background(0);
  if (drawingField) {
    drawField();
  }

  drawBlackHoles();
  loadPixels();
  drawParticles();
  updatePixels();
  fill(255);
  if (showMenu) {
    text("fps " + frameRate, 25, 25);
    text("particles (UP / DOWN): currently " + particles.length + ", next reset " + nParticles, 25, 40);
    text("draw field (f): " + drawingField, 25, 55);
    text("reset (r)", 25, 70);
    text("add blackhole (RIGHT CLICK)", 25, 85);
    text("attract to mouse (LEFT CLICK)", 25, 100);
    text("hide menu (m)", 25, 115);
  }
}

void drawBlackHoles() {
  fill(255, 255, 200);
  noStroke();
  for (int i = 0; i < blackHoles.size(); i++) {
    Vec bh = blackHoles.get(i);
    ellipse(bh.x, bh.y, 10, 10);
  }
}

void drawParticles() {
  float w = 2;
  int c = color(255);
  for (int i = 0; i < particles.length; i += 1) {
    float[] p = particles[i];

    int px = max(0, min(width-1, (int) p[0]));
    int py = max(0, min(height-1, (int) p[1]));
    int index = py * width + px;
    pixels[index] = (pixels[index] + c) / 2;
  }
}

void drawField() {
  float scale = sqrt(cellW * cellW + cellH*cellH) / maxSpeed * 2;
  int points = (int) (scale * 10);
  loadPixels();
  for (int x=0; x< grid.length; x+=1) {
    for (int y = 0; y < grid[x].length; y+=1) {
      Vec vec = grid[x][y];
      for (int i = 0; i < points; i++) {
        float p = (float) i / points;
        float pc = p*p;
        int px = max(0, min(width-1, (int) (scale * vec.x*p + x * cellW)));
        int py = max(0, min(height-1, (int) (scale * vec.y*p + y * cellH)));
        int c = color(0 * (1-pc) + 50 * pc, 0 * (1-pc) + 50 * pc, 0 * (1-pc) + 50 * pc);
        int index = py * width + px;
        pixels[index] = c;
      }
    }
  }
  updatePixels();
}


class Vec { // mutable because performance :(
  float x;
  float y;

  Vec(float x, float y) {
    this.x = x;
    this.y = y;
  }

  void set(Vec v) {
    x = v.x;
    y = v.y;
  }

  float dist() {
    return sqrt(x * x + y * y);
  }

  float dist(Vec v) {
    float dx = x - v.x;
    float dy = y - v.y;
    return sqrt(dx * dx + dy * dy);
  }

  Vec norm() {
    float d = this.dist();
    return new Vec(x / d, y / d);
  }

  void add(Vec vec) {
    this.x += vec.x;
    this.y += vec.y;
  }

  void add(float x, float y) {
    this.x += x;
    this.y += y;
  }

  void addScaled(Vec v, float s) {
    this.x += v.x * s;
    this.y += v.y * s;
  }

  void addScaled(float x, float y, float s) {
    this.x += x * s;
    this.y += y * s;
  }

  void scale(float s) {
    x *= s;
    y *= s;
  }
}