// RL Jun 15, 2022 

// Define origin ("affectation")
X  = 0;
Y  = 0;
Z  = 0;

// Define Points
Point(1) = {X, Y, Z, 0.5};
Point(2) = {X+2, Y, Z, 0.5};
Point(3) = {X+2, Y+2, Z, 0.5};
Point(4) = {X, Y+2, Z, 0.5};

// Define lines
Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};

// Define line loop
Line Loop(1) = {1, 2, 3, 4}

// Define surfaces from line loop
Plane Surface(1) = {1};








//+
Curve Loop(1) = {4, 1, 2, 3};
//+
Surface(1) = {1};
//+
Transfinite Surface {1} = {1, 2, 3, 4};
//+
Transfinite Curve {4, 3, 2, 1} = 3 Using Progression 1;
//+
Recombine Surface {1};
//+
Recombine Surface {1};
//+
Recombine Surface {1};
//+
SetFactory("OpenCASCADE");
Wire(2) = {3, 2, 1, 4};
Extrude { Curve{4}; Surface{1}; Curve{3}; Curve{2}; Curve{1}; } Using Wire {2}

