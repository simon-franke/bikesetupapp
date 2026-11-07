"""Approximate FOX-36-like reference, NOT manufacturer CAD or a fit guarantee.
Published: 36 mm stanchions, 160 mm travel, 571 mm axle-to-crown,
44 mm offset, 15 x 110 mm axle, 263 mm steerer (29 inch assumption).
Casting shapes, leg spacing, seals and crown are illustrative estimates.
"""
from pathlib import Path
import cadquery as cq
OUT=Path(__file__).resolve().parent
black=cq.Color(0.12,0.13,0.14)
orange=cq.Color(0.95,0.28,0.035)
gold=cq.Color(0.67,0.47,0.19)
silver=cq.Color(0.65,0.68,0.71)
blue=cq.Color(0.10,0.32,0.65)

def cyl(radius,height,xyz,direction=(0,0,1)):
    return cq.Solid.makeCylinder(radius,height,cq.Vector(*xyz),cq.Vector(*direction))

fork=cq.Assembly(name='APPROXIMATE_2021_36_29_160_REFERENCE')
for x,label in ((-70,'left'),(70,'right')):
    lower=cyl(23,310,(x,22,15)).fuse(cyl(24,10,(x,22,320)))
    lower=lower.cut(cyl(18.4,310,(x,22,35)))
    lug=cyl(18,30,(x-15,44,0),(1,0,0))
    neck=cq.Workplane('XY').box(28,36,32).translate((x,34,16)).val()
    lower=lower.fuse(lug,neck).cut(cyl(7.5,40,(x-20,44,0),(1,0,0)))
    fork.add(lower,name='LOWER_'+label+'_estimated_casting',color=orange)
    tube=cyl(18,405,(x,22,120)).cut(cyl(15,405,(x,22,120)))
    fork.add(tube,name='UPPER_'+label+'_36mm_stanchion',color=gold)
    seal=cyl(25,7,(x,22,327)).cut(cyl(18.1,7,(x,22,327)))
    fork.add(seal,name='LOWER_'+label+'_dust_seal_estimate',color=black)
    fork.add(cyl(22,38,(x,22,510)),name='UPPER_'+label+'_crown_socket',color=black)
    fork.add(cyl(15,4,(x,22,548)),name='UPPER_'+label+'_adjuster',color=blue)
# Forward arch: half annulus above the tyre, with feet on the lower casting.
outer=cyl(74,15,(0,34,330),(0,1,0)).cut(cyl(58,17,(0,33,330),(0,1,0)))
half=cq.Workplane('XY').box(180,60,85,centered=(True,True,False)).translate((0,42,330)).val()
arch=outer.intersect(half)
for x in (-66,66):
    foot=cq.Workplane('XY').box(16,15,20,centered=(True,True,False)).translate((x,41.5,310)).val()
    arch=arch.fuse(foot)
fork.add(arch,name='LOWER_forward_arch_estimate',color=orange)
# Stylised crown geometry, not a reproduction of FOX's casting.
points=[(-90,8),(-90,35),(-55,43),(0,24),(55,43),(90,35),(90,8),(22,-21),(-22,-21)]
crown=cq.Workplane('XY').workplane(offset=530).polyline(points).close().extrude(22)
crown=crown.edges('|Z').fillet(4)
fork.add(crown.val(),name='UPPER_crown_bridge_estimate',color=black)
fork.add(cyl(24,19,(0,0,552)),name='UPPER_crown_race_datum_571',color=black)
steerer=cq.Solid.makeCone(19.05,14.3,80,cq.Vector(0,0,571),cq.Vector(0,0,1)).fuse(cyl(14.3,183,(0,0,651)))
steerer=steerer.cut(cyl(11.5,263,(0,0,571)))
fork.add(steerer,name='UPPER_tapered_steerer_263',color=silver)
fork.add(cyl(7.5,170,(-85,44,0),(1,0,0)),name='LOWER_15mm_axle_110mm_hub_space',color=silver)
# Small visual brake bosses, no bolt-pattern accuracy claim.
for z in (42,116):
    boss=cyl(9,15,(-70,-9,z),(0,1,0)).cut(cyl(3,15,(-70,-9,z),(0,1,0)))
    fork.add(boss,name='LOWER_brake_boss_'+str(z)+'_estimate',color=black)
fork.save(str(OUT/'Approximate_Fox36_160_reference.step'))
print('Wrote approximate fork reference STEP file')
