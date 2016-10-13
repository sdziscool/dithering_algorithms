import java.util.*;
PImage src;
PImage res;
int[][] matrix;


// Bayer matrix 8x8
int[][] matrix3x3 = {
  {
    1, 8, 4
  }
  , 
  {
    7, 6, 3
  }
  , 
  {
    5, 2, 9
  }
};
int[][] matrix4x4 = {   
  {
    1, 9, 3, 11
  }
  , 
  {
    13, 5, 15, 7
  }
  , 
  {
    4, 12, 2, 10
  }
  , 
  {
    16, 8, 14, 6
  }
};
int[][] matrix2x2 = {
  {
    1, 3
  }
  , 
  {
    4, 2
  }
};
int[][] matrix8x8 = {
  {
    1, 49, 13, 61, 4, 52, 16, 64
  }
  , 
  {
    33, 17, 45, 29, 36, 20, 48, 32
  }
  , 
  {
    9, 57, 5, 53, 12, 60, 8, 56
  }
  , 
  {
    41, 25, 37, 21, 44, 28, 40, 24
  }
  , 
  {
    3, 51, 15, 63, 2, 50, 14, 62
  }
  , 
  {
    35, 19, 47, 31, 34, 18, 46, 30
  }
  , 
  {
    11, 59, 7, 55, 10, 58, 6, 54
  }
  , 
  {
    43, 27, 39, 23, 42, 26, 38, 22
  }
};

float mratio = 10 / 18.5; //okay as is 1.0 / 18.5
float mfactor = 255.0 / 50; //okay as is 255.0 / 5
int coloram = 4; //IMPORTANT Amount of colors you want in your result
int palsw = 0; //paletteswitch, 0 is random, 1 is random+black, 2 is 3bit and anything else is b&w monochrome
int loops = 4; //amount of loops for randomcolor.
String image = "header.png"; //path to image
float scale = 0.5; //scaling of image before processing, can be done without artefacting when using dithering
int s = 1; // steps, best left at 1
int msize = 4; //2,3,4,8 also defines matrix!, anything other than 2,3,4 and 8 results in msize = 4 
color[] palette; //main palette, could later be implemented to be user defined
color[] altpal = new color[coloram]; //array containg all random colors
float endscale = 1; //not working correctly, scaling of image after processing

void setup() {
  src = loadImage(image);  
  res = createImage(src.width, src.height, RGB);
  src.resize((int)(scale*src.width), (int)(scale*src.height));
  size(src.width, src.height, JAVA2D);
  noLoop();
  noStroke();
  noSmooth();
}

void draw() {

  for (int i = 0; i<loops; i++) {

    // Init canvas
    background(0, 0, 0);

    image(src, 0, 0);

    // Define step

    collorcollector();

    background(0, 0, 0);

    if (msize == 2) { 
      matrix = matrix2x2;
    } else if (msize == 3) { 
      matrix =  matrix3x3;
    } else if (msize == 8) { 
      matrix =  matrix8x8;
    } else { //failsafe
      matrix = matrix4x4;
      msize = 4;
    }

    // Scan image
    for (int x = 0; x < src.width; x+=s) {
      for (int y = 0; y < src.height; y+=s) {
        // Calculate pixel
        color oldpixel = src.get(x, y);
        color value = color( (oldpixel >> 16 & 0xFF) + (mratio*matrix[x%msize][y%msize] * mfactor), (oldpixel >> 8 & 0xFF) + (mratio*matrix[x%msize][y%msize] * mfactor), (oldpixel & 0xFF) + + (mratio*matrix[x%msize][y%msize] * mfactor) );
        color newpixel = findClosestColor(value);      
        src.set(x, y, newpixel);
        // Draw
        stroke(newpixel);   
        //point(x, y);
        line(x, y, x+s, y+s);
      }
    }
    
    res = src;
    
    
    //frame.resize((int)(endscale*src.width), (int)(endscale*src.height));
    size((int)(endscale*src.width), (int)(endscale*src.height));
    noSmooth();
    noStroke();
    res.resize((int)(endscale*src.width), (int)(endscale*src.height));
    noSmooth();
    noStroke();
    image(res, 0, 0);
    save(palsw + "_" + hour() + second() + millis()*100 + "_" + i + "result.png");

    if (!(palsw == 0 || palsw == 1)) {
      break;
    }
    src = loadImage(image);
    src.resize((int)(scale*src.width), (int)(scale*src.height));
  }
  exit();
}

// Find closest colors in palette
color findClosestColor(color in) {

  //Palette colors
  color[] pal3bit = { // 3bit color palette
    color(0), 
    color(255), 
    color(255, 0, 0), 
    color(0, 255, 0), 
    color(0, 0, 255), 
    color(255, 255, 0), 
    color(0, 255, 255), 
    color(255, 0, 255), 
    color(0, 255, 255),
  };

  color[] monopal = {
    color(0), color(255)
  }; //monochrom palette black and white


  if (palsw == 0 || palsw == 1) {
    palette = altpal;
  } else if (palsw == 2) {
    palette = pal3bit;
  } else { 
    palette = monopal;
  }



  PVector[] vpalette = new PVector[palette.length];  
  PVector vcolor = new PVector( (in >> 16 & 0xFF), (in >> 8 & 0xFF), (in & 0xFF));
  int current = 0;
  float distance = vcolor.dist(new PVector(0, 0, 0));

  for (int i=0; i<palette.length; i++) {
    int r = (palette[i] >> 16 & 0xFF);
    int g = (palette[i] >> 8 & 0xFF);
    int b = (palette[i] & 0xFF);
    vpalette[i] = new PVector(r, g, b);
    float d = vcolor.dist(vpalette[i]);
    if (d < distance) {
      distance = d;
      current = i;
    }
  }
  return palette[current];
}

void collorcollector() { //extracts colors from original image at random, only takes new colors

  int i = 0;
  if (palsw == 1) {
    altpal[0] = color(0);
    i++;
  }
  int rx;
  int ry;

  rx = int(random(src.width));
  ry = int(random(src.height));
  for (int x = rx; x < src.width; x++) {
    for (int y = ry; y < src.height; y++) {
      //i < altpal.length
      if ( !Arrays.asList(altpal).contains(color(get(x, y)))) {

        if (i == altpal.length) {
          break;
        }

        altpal[i]=color(get(x, y));
        i++;

        x = int(random(src.width));
        y = int(random(src.height));
        //System.out.println("flag1 " + altpal[i-1] + i + color(get(x,y)));
      }
    }
  }
}

