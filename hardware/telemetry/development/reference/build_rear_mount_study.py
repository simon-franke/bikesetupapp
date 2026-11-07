"""Rear placement and exploded mounting study on the approximate fork.
Not manufacturer CAD; mount contact surfaces and compliance require prototypes.
"""
from pathlib import Path
import math
import json
import runpy
import cadquery as cq
OUT=Path(__file__).resolve().parent
# Reuse the existing fork geometry and colours without changing its assumptions.
ref=runpy.run_path(str(OUT/'build_fork_reference.py'))
fork=ref['fork'];cyl=ref['cyl'];silver=ref['silver'];black=ref['black']
white=cq.Color(0.88,0.9,0.91)
bodycolor=cq.Color(0.17,0.27,0.31)
soft=cq.Color(0.25,0.55,0.65)
green=cq.Color(0.10,0.34,0.19)
solids=cq.importers.importStep(str(OUT.parent/'Reader_cartridge.step')).solids().vals()
assert len(solids)==48
assert solids[7].BoundingBox().xlen>239

def behind(shape):
    # Local travel X -> fork Z; local width Y -> -fork X; outward Z -> -fork Y.
    return shape.rotate((0,0,0),(1,-1,1),120).translate((70,-4.5,295))

def block(dx,dy,dz,center):
    return cq.Workplane('XY').box(dx,dy,dz).translate(center).val()

# Curved crown saddle, fully above the swept stanchion; 0.5 mm radial liner space.
shoe_box=block(26,12,19,(70,-0.5,520))
upper_shoe=shoe_box.cut(cyl(22.5,21,(70,22,509.5)))
# Flush insert pocket for a small retaining screw, away from the fork itself.
upper_shoe=upper_shoe.cut(cyl(1.75,4,(70,-6.5,520),(0,1,0)))
insert=cyl(1.75,4,(70,-6.5,520),(0,1,0)).cut(cyl(1.05,4,(70,-6.5,520),(0,1,0)))
liner=cyl(22.5,19,(70,22,510.5)).cut(cyl(22,19,(70,22,510.5))).intersect(shoe_box)
# Compliant button between crown saddle and carrier. It is not a tested spherical joint.
button=cyl(4.5,2.5,(70,-9,520),(0,1,0)).cut(cyl(1.35,2.5,(70,-9,520),(0,1,0)))
washer=cyl(3.5,0.8,(70,-11.3,520),(0,1,0)).cut(cyl(1.35,0.8,(70,-11.3,520),(0,1,0)))
bolt=cyl(1.25,8,(70,-11.3,520),(0,1,0)).fuse(cyl(2.25,2.5,(70,-13.8,520),(0,1,0)))
bolt=bolt.cut(cyl(0.8,1.4,(70,-13.81,520),(0,1,0)))

def strap(radius,rear_center,z,width,rear_half_width=8):
    # Nominal band routing: round at the casting, flattened across the rear shoe.
    pts=[]
    threshold=-math.sqrt(radius*radius-rear_half_width*rear_half_width)
    for i in range(96):
        a=2*math.pi*i/96
        x=radius*math.cos(a);y=radius*math.sin(a)
        if y<threshold:y=rear_center
        pts.append((70+x,22+y))
    wire=cq.Workplane('XY').polyline(pts).close()
    outer=wire.wires().toPending().offset2D(0.5).extrude(width).translate((0,0,z))
    inner=cq.Workplane('XY').polyline(pts).close().wires().toPending().offset2D(-0.5).extrude(width+2).translate((0,0,z-1))
    return outer.cut(inner).val()

bands=[('Upper_band_1',strap(22.7,-29,513.5,2.5,14)),('Upper_band_2',strap(22.7,-29,524,2.5,14)),
       ('Lower_band_1',strap(23.7,-25.05,280.75,4.5,11.5)),('Lower_band_2',strap(23.7,-25.05,304.75,4.5,11.5))]
# Approximate tape allowance on the rear shoe's curved face.
ys=[-10+i for i in range(21)]
face=[(y,-25+math.sqrt(22*22-y*y)) for y in ys]
profile=face+[(y,z-0.35) for y,z in reversed(face)]
# YZ plane coordinates correspond to local Y/Z; extrusion direction is local X.
lower_pad=cq.Workplane('YZ').workplane(offset=-24).polyline(profile).close().extrude(48).val()

parts=[]
for i,s in enumerate(solids):
    b=s.BoundingBox()
    if i==7:
        # Extend only the unmagnetised tip, to reach the crown-side connection.
        s=s.fuse(block(20,8,1.5,(130,0,5.25))).translate((98,0,0))
        s=behind(s).cut(cyl(1.35,8,(70,-14,520),(0,1,0)))
        label='Carrier_extended_tip_with_M2p5_hole';color=silver;shift=80
    else:
        if i in (8,9):s=s.translate((98,0,0))
        s=behind(s)
        if i==0:label='Rigid_reader_chassis';color=silver;shift=55
        elif i in (1,4):label='Replaceable_POM_guide_'+str(i);color=white;shift=68
        elif i==8:label='Magnetic_scale';color=black;shift=80
        elif i==9:label='Protective_foil';color=silver;shift=80
        elif 10<=i<=34:label='RLS_encoder_detail_'+str(i);color=green if i==34 else silver;shift=78
        elif i==37:label='Rear_reader_cover';color=bodycolor;shift=115
        elif i==40:label='Cable_strain_relief';color=black;shift=70
        elif i==43:label='Lower_curved_mounting_shoe';color=bodycolor;shift=25
        elif i in (38,39):label='Lid_screw_'+str(i);color=silver;shift=135
        elif i in (35,36):label='PCB_screw_'+str(i);color=silver;shift=92
        else:label='Reader_fastener_'+str(i);color=silver;shift=85
    parts.append((label,s,color,shift))
extra=[('Lower_adhesive_allowance',behind(lower_pad),soft,10),
       ('Upper_crown_liner',liner,soft,15),('Upper_crown_saddle',upper_shoe,bodycolor,32),
       ('Upper_M2p5_insert',insert,silver,32),('Upper_TPU_compliance_spacer',button,soft,60),
       ('Upper_retaining_washer',washer,silver,92),('Upper_retaining_screw',bolt,silver,108)]
for exploded in (False,True):
    scene=cq.Assembly(name='REAR_SENSOR_'+('EXPLODED' if exploded else 'ASSEMBLED'))
    scene.add(fork,name='Approximate_fork_fixed_reference')
    for label,s,color,shift in parts+extra:
        if exploded:s=s.translate((0,-shift,0))
        scene.add(s,name=label,color=color)
    for label,s in bands:
        scene.add(s,name=label+'_routing_reference',color=black)
        bb=s.BoundingBox()
        head=block(5,4,4,(70,46.7 if label.startswith('Upper') else 47.2,(bb.zmin+bb.zmax)/2))
        scene.add(head,name=label+'_locking_head_envelope',color=black)
    path=OUT.parent.parent/'exports'/('Rear_fork_exploded.step' if exploded else 'Rear_fork_assembled.step')
    scene.save(str(path))
# Own custom parts must be valid solids. Check the mounting shoe and carrier
# against the relevant fork solids at sampled compression positions separately.
checks=[]
for label,s,_,_ in parts+extra:
    assert s.isValid(),label
    assert s.Volume()>0,label
fork_parts={name:node.obj for name,node in fork.objects.items() if node.obj is not None}
collisions=[]
# Only external accessory-to-fork clashes; approximate fork internal geometry is
# not suitable for validating suspension internals.
for travel in (0,80,160):
    for label,s,_,_ in parts+extra:
        fixed=label.startswith(('Carrier_','Magnetic_','Protective_','Upper_'))
        accessory=s if fixed else s.translate((0,0,travel))
        for name,obj in fork_parts.items():
            shape=obj.val() if isinstance(obj,cq.Workplane) else obj
            if name.startswith('LOWER_'):shape=shape.translate((0,0,travel))
            overlap=accessory.intersect(shape).Volume()
            if overlap>0.001:collisions.append({'travel_mm':travel,'accessory':label,'fork_part':name,'overlap_mm3':round(overlap,4)})
band_shoe_interferences=[]
for label,band in bands:
    shoe=upper_shoe if label.startswith('Upper') else behind(solids[43])
    overlap=band.intersect(shoe).Volume()
    if overlap>0.001:band_shoe_interferences.append({'band':label,'overlap_mm3':round(overlap,4)})
report={'band_to_shoe_interferences':band_shoe_interferences,'rear_placement':True,'sampled_compression_mm':[0,80,160],
        'accessory_to_approximate_fork_collisions':collisions,
        'excluded':'Band routing, intentional liner contacts, screw-thread fit and accessory-to-accessory articulation; no frame, wheel or hoses.',
        'limits':'Approximate fork. TPU compliance, retention, fork flex, steering/frame clearance and physical fit untested.'}
(OUT/'rear_mount_validation.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
