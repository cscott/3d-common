// Arch support inspired by:
// https://github.com/KitWallace/openscad/blob/master/gothic-nested-archway.scad
module arch(x,y,r) {
  epsilon = .1;
  union() {
    difference() {
      intersection () {
        translate([x,y,0]) circle(r);
        translate([-x,y,0]) circle(r);
      }
      translate([0,y-r,0])
        square(size=[3*(r-x), 2*r - epsilon], center=true);
    }
    if (y > 0)
      translate([0,y/2,0]) square(size=[2 *(r-x), y],center=true);
  }
};

module arch2(width, height, thick=1, ratio=2, center=false, extrude=true) {
  // width = 2*(r-x), height = y + sqrt(r*r - x*x)
  // r:x ~= ratio:1
  x = width/(2*(ratio-1));
  r = ratio * x;
  y = height - sqrt(r*r - x*x);
  if (extrude) {
    translate([0,0,center?(-thick/2):0])
      linear_extrude(height=thick)
        arch(x=x, y=y, r=r);
  } else {
    arch(x=x, y=y, r=r);
  }
}

function v_sum_r(v,n,k) =
      k > n ? 0 : v[k] + v_sum_r(v,n,k+1);

function v_sum(v,n) = v_sum_r(v,n-1,0);

module nested_archway(width, height, thick, steps=[2,2,2,2], ratio=2, center=false, extra_thick=0) {
  epsilon = .1;
  if (center) {
    for (i=[-1,1]) scale([1,1,i]) translate([0,0,-epsilon])
      nested_archway(width, height, thick/2 + epsilon, steps, ratio, false, extra_thick/2);
  } else {
    for(i=[0:1:len(steps)]) {
      sum = v_sum(steps, i);
      t = (i < len(steps)) ? steps[i] + epsilon: thick - sum;
      translate([0,0,thick-sum-t])
        arch2(width-sum, height-sum, t + (i==0 ? extra_thick : 0),
              ratio=ratio, center=false);
    }
  }
}
