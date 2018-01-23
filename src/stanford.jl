using Arrows
using AlioAnalysis
using AlioZoo
import Arrows: source

"Stanford kinematics forward model."
function stanford_fwd(inputs)
  length(inputs) == 6 || throw(ArgumentError("Requires 6 inputs: 5 angles, 1 arm length."))
  phi1 = inputs[1]
  phi2 = inputs[2]
  phi4 = inputs[3]
  phi5 = inputs[4]
  phi6 = inputs[5]
  d2 = inputs[6]
  d3 = 2.0
  h1 = 1.0
  sinphi6 = SinArrow()(phi6)
  cosphi4 = CosArrow()(phi4)
  sinphi1 = SinArrow()(phi1)
  cosphi5 = CosArrow()(phi5)
  cosphi1 = CosArrow()(phi1)
  cosphi2 = CosArrow()(phi2)
  sinphi4 = SinArrow()(phi4)
  cosphi6 = CosArrow()(phi6)
  sinphi2 = SinArrow()(phi2)
  sinphi5 = SinArrow()(phi5)

  r11 = -sinphi6*(cosphi4*sinphi1+cosphi1*cosphi2*sinphi4)-cosphi6*(cosphi5*(sinphi1*sinphi4-cosphi1*cosphi2*cosphi4)+cosphi1*sinphi2*sinphi5)
  r12 = sinphi6*(cosphi5*(sinphi1*sinphi4-cosphi1*cosphi2*cosphi4)+cosphi1*sinphi2*sinphi5)-cosphi6*(cosphi4*sinphi1+cosphi1*cosphi2*sinphi4)
  r13 = sinphi5*(sinphi1*sinphi4-cosphi1*cosphi2*cosphi4)-cosphi1*cosphi5*sinphi2
  r21 = sinphi6*(cosphi1*cosphi4-cosphi2*sinphi1*sinphi4)+cosphi6*(cosphi5*(cosphi1*sinphi4+cosphi2*cosphi4*sinphi1)-sinphi1*sinphi2*sinphi5)
  r22 = cosphi6*(cosphi1*cosphi4-cosphi2*sinphi1*sinphi4)-sinphi6*(cosphi5*(cosphi1*sinphi4+cosphi2*cosphi4*sinphi1)-sinphi1*sinphi2*sinphi5)
  r23 = -sinphi5*(cosphi1*sinphi4+cosphi2*cosphi4*sinphi1)-cosphi5*sinphi1*sinphi2
  r31 = cosphi6*(cosphi2*sinphi5+cosphi4*cosphi5*sinphi2)-sinphi2*sinphi4*sinphi6
  @show Arrows.src(r31)
  r32 = -sinphi6*(cosphi2*sinphi5+cosphi4*cosphi5*sinphi2)-cosphi6*sinphi2*sinphi4
  r33 = cosphi2*cosphi5-cosphi4*sinphi2*sinphi5
  px = d2*sinphi1 - d3*cosphi1*sinphi2
  py = -d2*cosphi1 - d3*sinphi1*sinphi2
  pz = h1 + d3*cosphi2
  outputs = [px, py, pz, r11, r12, r13, r21, r22, r23, r31, r32, r33]
end
#
# "Stanford kinematics forward model."
# function stanford_fwd2(inputs)
#   length(inputs) == 6 || throw(ArgumentError("Requires 6 inputs: 5 angles, 1 arm length."))
#   phi1 = inputs[1]
#   phi2 = inputs[2]
#   phi4 = inputs[3]
#   phi5 = inputs[4]
#   phi6 = inputs[5]
#   d2 = inputs[6]
#   d3 = 2.0
#   h1 = 1.0
#   sinphi6 = SinArrow()(phi6)
#   cosphi4 = CosArrow()(phi4)
#   sinphi1 = SinArrow()(phi1)
#   cosphi5 = CosArrow()(phi5)
#   cosphi1 = CosArrow()(phi1)
#   cosphi2 = CosArrow()(phi2)
#   sinphi4 = SinArrow()(phi4)
#   cosphi6 = CosArrow()(phi6)
#   sinphi2 = SinArrow()(phi2)
#   sinphi5 = SinArrow()(phi5)
#
#   r11 = sinphi6*(cosphi4*sinphi1+cosphi1*cosphi2*sinphi4)cosphi6*(cosphi5*(sinphi1*sinphi4cosphi1*cosphi2*cosphi4)+cosphi1*sinphi2*sinphi5)
#   r12 = sinphi6*(cosphi5*(sinphi1*sinphi4cosphi1*cosphi2*cosphi4)+cosphi1*sinphi2*sinphi5)cosphi6*(cosphi4*sinphi1+cosphi1*cosphi2*sinphi4)
#   r13 = sinphi5*(sinphi1*sinphi4cosphi1*cosphi2*cosphi4)cosphi1*cosphi5*sinphi2
#   r21 = sinphi6*(cosphi1*cosphi4cosphi2*sinphi1*sinphi4)+cosphi6*(cosphi5*(cosphi1*sinphi4+cosphi2*cosphi4*sinphi1)sinphi1*sinphi2*sinphi5)
#   r22 = cosphi6*(cosphi1*cosphi4cosphi2*sinphi1*sinphi4)sinphi6*(cosphi5*(cosphi1*sinphi4+cosphi2*cosphi4*sinphi1)sinphi1*sinphi2*sinphi5)
#   r23 = sinphi5*(cosphi1*sinphi4+cosphi2*cosphi4*sinphi1)cosphi5*sinphi1*sinphi2
#   r31 = cosphi6*(cosphi2*sinphi5+cosphi4*cosphi5*sinphi2)sinphi2*sinphi4*sinphi6
#   @show Arrows.src(r31)
#   r32 = sinphi6*(cosphi2*sinphi5+cosphi4*cosphi5*sinphi2)cosphi6*sinphi2*sinphi4
#   r33 = cosphi2*cosphi5cosphi4*sinphi2*sinphi5
#   px = d2*sinphi1  d3*cosphi1*sinphi2
#   py = d2*cosphi1  d3*sinphi1*sinphi2
#   pz = h1 + d3*cosphi2
#   outputs = [px, py, pz, r11, r12, r13, r21, r22, r23, r31, r32, r33]
# end

function stanford_arr()
  carr = CompArrow(:stanford,
                   [:x1, :x2, :x3, :x4, :x5, :x6],
                   Symbol[])
  i = ▹(carr)
  ars = stanford_fwd(▹(carr))
  foreach(link_to_parent!, ars)
  @show filter(Arrows.loose, inner_sub_ports(carr))
  # link_to_parent!(carr, Arrows.loose)
  # @assert is_wired_ok(carr)
  carr
end
