// Extrusion along a path, including bezier path.

function revface(f, offset=0) =
  [ for (i=[0:1:len(f)-1]) [for(j=[len(f[i])-1:-1:0]) f[i][j] + offset ] ];
function endface(numpts, e) = len(e) ? e : [ [for (i=[0:1:numpts-1]) i] ];

// numslices should be odd

function shiftpoints(points, numpts, numslices) =
  [ for (i=[0:1:numslices-1])
    for (j=[0:1:numpts-1])
    (i%2)==0 ? points[i*numpts + j] :
     numslices > 20 ?
     // ensure "center points" are on a slice
     (( points[i*numpts + j] + points[i*numpts + ((j+1) % numpts)] ) / 2 ) :
     // interpolate between the surrounding slices
     // (works better when numslices is very small)
     (( points[(i-1)*numpts + j] + points[(i-1)*numpts + ((j+1) % numpts)] +
        points[(i+1)*numpts + j] + points[(i+1)*numpts + ((j+1) % numpts)] ) / 4 ) ];

function genfaces(numpts, numslices, end=[]) = concat(
  endface(numpts, end),
  genfaces_interior(numpts, numslices),
  revface(endface(numpts, end), numpts*(numslices - 1))
);

function genfaces_interior(numpts, numslices) = [
  for (i=[0:2:numslices-3])
    for (j=[0:1:numpts-1])
      for (k=[0,1,2,3])
        [ i * numpts, i * numpts, i * numpts ] +
        (k == 0 ?
          [ numpts + j, 0 + j, 2*numpts + j ] :
         k == 1 ?
          [ numpts + j, 2*numpts + j, 2*numpts + (j + 1) % numpts ] :
         k == 2 ?
          [ numpts + j, 2*numpts + (j + 1) % numpts, (j + 1) % numpts ] :
          [ numpts + j, (j + 1) % numpts, 0 + j ])
];

function rotate_matx(theta) = [
  [ 1,          0,           0, 0],
  [ 0, cos(theta), -sin(theta), 0],
  [ 0, sin(theta),  cos(theta), 0],
  [ 0,          0,           0, 1]
];
function rotate_maty(theta) = [
  [  cos(theta), 0, sin(theta), 0],
  [           0, 1,          0, 0],
  [ -sin(theta), 0, cos(theta), 0],
  [           0, 0,          0, 1]
];
function rotate_matz(theta) = [
  [ cos(theta), -sin(theta), 0, 0],
  [ sin(theta),  cos(theta), 0, 0],
  [          0,           0, 1, 0],
  [          0,           0, 0, 1]
];
function rotate_mat(amt) =
  rotate_matz(amt.z) * rotate_maty(amt.y) * rotate_matx(amt.x);
function trans_mat(amt) = [
  [ 1, 0, 0, amt.x ],
  [ 0, 1, 0, amt.y ],
  [ 0, 0, 1, amt.z ],
  [ 0, 0, 0, 1 ]
];
function affineT(mat, v) = mat * [v.x, v.y, v.z, 1];
function affine(mat, v) = [for (i=[0,1,2]) affineT(mat, v)[i]];

// Bezier math, from: https://pomax.github.io/bezierinfo/
function bezier_at(pts, t) =
  pow(1-t,3)*pts[0] +
  3*pow(1-t,2)*t*pts[1] +
  3*(1-t)*pow(t,2)*pts[2] +
  pow(t,3)*pts[3];
function bezier_dt_at(pts, t) =
  3*pow(1-t,2)*(pts[1]-pts[0]) +
  6*(1-t)*t*(pts[2]-pts[1]) +
  3*pow(t,2)*(pts[3]-pts[2]);
function unit_vector(p) = p / norm(p);
function bezier_unit_tangent_at(pts, t) = unit_vector(bezier_dt_at(pts, t));

function bezier_divide1(pts, z=0.5) = [
  pts[0],
  z*pts[1] - (z-1)*pts[0],
  pow(z,2)*pts[2] - 2*z*(z-1)*pts[1] + pow(z-1,2)*pts[0],
  pow(z,3)*pts[3] - 3*pow(z,2)*(z-1)*pts[2] + 3*z*pow(z-1,2)*pts[1] - pow(z-1,3)*pts[0]
];
function bezier_divide2(pts, z=0.5) = [
  pow(z,3)*pts[3] - 3*pow(z,2)*(z-1)*pts[2] + 3*z*pow(z-1,2)*pts[1] - pow(z-1,3)*pts[0],
  pow(z,2)*pts[3] - 2*z*(z-1)*pts[2] + pow(z-1,2)*pts[1],
  z*pts[3] - (z-1)*pts[2],
  pts[3]
];

function bezier_arclength(pts, thresh=1) =
  norm(pts[3]-pts[0]) < thresh ? norm(pts[3] - pts[0]) :
  (bezier_arclength(bezier_divide1(pts), thresh) +
   bezier_arclength(bezier_divide2(pts), thresh));

// return the t value corresponding to a given arclength
function bezier_t_for_length(pts, length, thresh=1) =
  norm(pts[3]-pts[0]) < thresh ? (length/norm(pts[3] - pts[0])) :
  let(div1=bezier_divide1(pts), len1=bezier_arclength(div1, thresh))
  len1 > length ?
  (bezier_t_for_length(div1, length, thresh)/2) :
  (0.5 + bezier_t_for_length(bezier_divide2(pts), length-len1, thresh)/2);


// https://pomax.github.io/bezierinfo/#circles_cubic
function bezier_arc(radius, angle) =
  let(f=4*tan(angle/4)/3) [
  [ radius, 0, 0 ],
  [ radius, radius*f, 0],
  [ radius*(cos(angle) + f*sin(angle)),
    radius*(sin(angle) - f*cos(angle)), 0],
  [ radius*cos(angle), radius*sin(angle), 0]
];

// Compute rotation matrix from two vectors.
// From: http://math.stackexchange.com/questions/180418/calculate-rotation-matrix-to-align-vector-a-to-vector-b-in-3d

function rotate_from2vec_int(v) =
  [[0, -v[2], v[1]], [v[2], 0, -v[0]], [-v[1], v[0], 0]];
function rotate_from2vec(v1, v2) =
  let(cross=cross(v1, v2), vx=rotate_from2vec_int(cross),
      c=v1*v2, s=norm(cross))
  ([[1, 0, 0], [0, 1, 0], [0, 0, 1]] + vx + vx*vx*(1-c)/(s != 0 ? s*s : 1));

function mat3tomat4(M) = [
  concat(M[0], [0]),
  concat(M[1], [0]),
  concat(M[2], [0]),
  [ 0, 0, 0, 1 ]
];

module bezier_extrude(profile_points, bezier_points, endface=[], slices=$fn, initial_vec=undef) {
  // ensure #slices is odd
  nslices = 1 + 2*floor((slices <= 0 ? 13 : slices) / 2);
  // initial direction and position
  d0 = initial_vec == undef ? bezier_unit_tangent_at(bezier_points, 0) :
    initial_vec;
  points = [ for (i=[0:1:nslices-1]) for (j=[0:1:len(profile_points)-1])
    bezier_at(bezier_points, i/(nslices-1)) +
    rotate_from2vec(d0, bezier_unit_tangent_at(bezier_points, i/(nslices-1))) *
    profile_points[j]
  ];
  //echo(nslices=nslices,d0=d0,points=points);
  polyhedron(points=shiftpoints(points, len(profile_points), nslices),
             faces=genfaces(len(profile_points), nslices, endface));
}

// test!
sample_line_bezier =[[0,0,0],[0,1,0],[0,2,0],[0,3,0]];
sample_curve_bezier = [[5,0,0],[5,4,0],[4,5,2],[0,5,2]];
sample_arc_bezier = bezier_arc(8, 35);
bezier_extrude([[-1,0,0],[0,0,1],[1,0,0]], sample_curve_bezier, slices=10);

bezier_extrude([[-1,0,0],[-.5,0,.5],[.5,0,.5],[1,0,0]], sample_arc_bezier, slices=10);
