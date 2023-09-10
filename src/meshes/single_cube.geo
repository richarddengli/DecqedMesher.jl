// simple 3D cavity
// DP May 6, 2022

Xcav  = 1.0;
Ycav  = 1.0;
Zcav  = 1.0;

// The enclosing cavity
Point(1) = {-Xcav/2,-Ycav/2, Zcav/2, 1};
Point(2) = { Xcav/2,-Ycav/2, Zcav/2, 1};
Point(3) = { Xcav/2,-Ycav/2,-Zcav/2, 1};
Point(4) = {-Xcav/2,-Ycav/2,-Zcav/2, 1};
Point(5) = {-Xcav/2, Ycav/2, Zcav/2, 1};
Point(6) = { Xcav/2, Ycav/2, Zcav/2, 1};
Point(7) = { Xcav/2, Ycav/2,-Zcav/2, 1};
Point(8) = {-Xcav/2, Ycav/2,-Zcav/2, 1};


Line(1) = {1,2};
Line(2) = {2,3};
Line(3) = {3,4};
Line(4) = {4,1};
Line(5) = {5,6};
Line(6) = {6,7};
Line(7) = {7,8};
Line(8) = {8,5};
Line(9) = {1,5};
Line(10) = {4,8};
Line(11) = {2,6};
Line(12) = {3,7};


Line Loop(1) = {1,2,3,4}; // Order matters
Line Loop(2) = {5,6,7,8};
Line Loop(3) = {1,11,-5,-9};
Line Loop(4) = {-3,12,7,-10};
Line Loop(5) = {4,9,-8,-10};
Line Loop(6) = {-2,11,6,-12};


// Create nodes on the lines
Transfinite Line{1,2,3,4,5,6,7,8,9,10,11,12} = 5;


Physical Line(1) = {1};
Physical Line(2) = {2};
Physical Line(3) = {3};
Physical Line(4) = {4};
Physical Line(5) = {5};
Physical Line(6) = {6};
Physical Line(7) = {7};
Physical Line(8) = {8};
Physical Line(9) = {9};
Physical Line(10) = {10};
Physical Line(11) = {11};
Physical Line(12) = {12};


Plane Surface(1) = {1};	// Create a surface out of the line loop
Plane Surface(2) = {2};	// Create a surface out of the line loop
Plane Surface(3) = {3};	// Create a surface out of the line loop
Plane Surface(4) = {4};	// Create a surface out of the line loop
Plane Surface(5) = {5};	// Create a surface out of the line loop
Plane Surface(6) = {6};	// Create a surface out of the line loop


Physical Surface(1) = {1}; // Make plane surface 1 a physical surface
Physical Surface(2) = {2}; // Make plane surface 1 a physical surface
Physical Surface(3) = {3}; // Make plane surface 1 a physical surface
Physical Surface(4) = {4}; // Make plane surface 1 a physical surface
Physical Surface(5) = {5}; // Make plane surface 1 a physical surface
Physical Surface(6) = {6}; // Make plane surface 1 a physical surface


Surface Loop(1) = {-1,-6,3,2,5,-4}; 
Volume(1) = {1};
Physical Volume (1) = {1};
