"""Native Fusion concept assembly. Dimensions are mm; rebuild to change presets.
Not a universal-fit or ride-approved product. Purchased parts are envelopes.
"""
import adsk.core
import adsk.fusion
import math
import json

OUT = '/Users/simonmoritzfranke/code/bikesetupapp/hardware/telemetry/development'
NEW = adsk.fusion.FeatureOperations.NewBodyFeatureOperation
CUT = adsk.fusion.FeatureOperations.CutFeatureOperation
JOIN = adsk.fusion.FeatureOperations.JoinFeatureOperation


def pt(x, y, z):
    return adsk.core.Point3D.create(x / 10, y / 10, z / 10)


def val(mm):
    return adsk.core.ValueInput.createByString(str(mm) + ' mm')


def component(parent, name, xyz=(0, 0, 0)):
    t = adsk.core.Matrix3D.create()
    t.translation = adsk.core.Vector3D.create(*(v / 10 for v in xyz))
    occurrence = parent.occurrences.addNewComponent(t)
    occurrence.component.name = name
    return occurrence.component


def sketch(c, axis, offset, name):
    planes = {'X': c.yZConstructionPlane, 'Y': c.xZConstructionPlane, 'Z': c.xYConstructionPlane}
    inp = c.constructionPlanes.createInput()
    inp.setByOffset(planes[axis], val(offset))
    plane = c.constructionPlanes.add(inp)
    plane.name = name + ' plane'
    plane.isLightBulbOn = False
    s = c.sketches.add(plane)
    s.name = name
    return s


def polygon(c, axis, offset, points, depth, name, op=NEW):
    s = sketch(c, axis, offset, name + ' profile')
    points = [s.modelToSketchSpace(pt(*p)) for p in points]
    for a, b in zip(points, points[1:] + points[:1]):
        line = s.sketchCurves.sketchLines.addByTwoPoints(a, b)
        line.isFixed = True
    assert s.profiles.count == 1, (name, s.profiles.count)
    inp = c.features.extrudeFeatures.createInput(s.profiles.item(0), op)
    inp.setDistanceExtent(False, val(depth))
    if op == CUT:
        inp.participantBodies = list(c.bRepBodies)
    f = c.features.extrudeFeatures.add(inp)
    f.name = name
    s.isLightBulbOn = False
    return f


def box(c, x, y, z, dx, dy, dz, name, op=NEW):
    return polygon(c, 'Z', z, [(x,y,z),(x+dx,y,z),(x+dx,y+dy,z),(x,y+dy,z)], dz, name, op)


def section(c, x, yz, length, name, op=NEW):
    return polygon(c, 'X', x, [(x,y,z) for y,z in yz], length, name, op)


def hole(c, axis, center, radius, depth, name, op=CUT):
    off = center['XYZ'.index(axis)]
    s = sketch(c, axis, off, name + ' profile')
    circle = s.sketchCurves.sketchCircles.addByCenterRadius(s.modelToSketchSpace(pt(*center)), radius / 10)
    circle.isFixed = True
    inp = c.features.extrudeFeatures.createInput(s.profiles.item(0), op)
    inp.setDistanceExtent(False, val(depth))
    if op == CUT:
        inp.participantBodies = list(c.bRepBodies)
    f = c.features.extrudeFeatures.add(inp)
    f.name = name
    s.isLightBulbOn = False
    return f


def paint(c, appearance):
    if appearance:
        for b in c.bRepBodies:
            b.appearance = appearance



# Lengths in millimetres. RLC2IC vendor CAD is positioned with its long edge
# parallel to travel (X), not transverse to travel. Z is out from the bike.
SCALE_STACK = 1.43 + 0.05 + 0.076  # bonded MS05 plus protective foil
SCALE_TOP = 6 + SCALE_STACK
PCB_BOTTOM = SCALE_TOP + 0.3
VENDOR = OUT + '/vendor/RLC2ICAxxxxxxA18.STEP'


def capsule_y(c, y, x, z1, z2, radius, depth, name, op=NEW):
    # Closed capsule in XZ, extruded along Y. Sampled semicircles keep sketches editable.
    pts=[]
    for i in range(13):
        a=math.pi*i/12
        pts.append((x+radius*math.cos(a),y,z2+radius*math.sin(a)))
    for i in range(13):
        a=math.pi+math.pi*i/12
        pts.append((x+radius*math.cos(a),y,z1+radius*math.sin(a)))
    return polygon(c,'Y',y,pts,depth,name,op)


def screw(parent, name, axis, start, length, colors, radius=1, head_r=1.8, head_h=1.2):
    c=component(parent,'FASTENER | '+name)
    hole(c,axis,start,radius,length,'Unthreaded screw envelope',NEW)
    p=list(start);p['XYZ'.index(axis)]+=length
    hole(c,axis,tuple(p),head_r,head_h,'Non-countersunk head',JOIN)
    # A simple driver recess makes fastener access obvious without modelling threads.
    q=p.copy();q['XYZ'.index(axis)]+=0.35
    hole(c,axis,tuple(q),0.65,head_h,'Driver recess',CUT)
    paint(c,colors['metal'])
    c.attributes.add('Engineering','Fastener','Envelope only: threads not modelled. Final length, head standard and torque require sourcing.')
    return c


def make_cartridge(root, name, xyz, vendor_component, colors, exploded=False):
    group=component(root,name,xyz)
    base=component(group,'01 | Rigid aluminium datum chassis | 48 x 22 x 3')
    polygon(base,'Z',0,[(-24,-9,0),(-22,-11,0),(22,-11,0),(24,-9,0),(24,9,0),(22,11,0),(-22,11,0),(-24,9,0)],3,'Chamfered base plate')
    # Two guides on a common datum: fore/aft shoulders locate each insert.
    for x in (-15,15):
        for dx in (-3.3,3.1):box(base,x+dx,-8.3,3,0.2,16.6,1,'Guide locating shoulder',JOIN)
        for y in (-6.3,6.3):hole(base,'Z',(x,y,0.4),0.8,3,'M2 guide tapped pilot')
    # Stand-off feet are outside the moving carrier; only the gold-pad regions
    # contact the encoder. Rear component area remains clear.
    for x in (-7.5,7.5):
        box(base,x-2.2,-7,3,4.4,2.6,PCB_BOTTOM+0.75-3,'Encoder bracket leg',JOIN)
        capsule_y(base,-7,x,PCB_BOTTOM+2.6,PCB_BOTTOM+5.4,2.2,5.892,'Gold-pad support seat',JOIN)
        hole(base,'Y',(x,-5.5,PCB_BOTTOM+4),0.8,4.5,'M2 encoder tapped pilot')
    # Lid posts sit beside the sensor, clear of the scale and PCB components.
    for y in (-8,8):
        hole(base,'Z',(0,y,3),1.8,18.8,'Lid post',JOIN)
        hole(base,'Z',(0,y,17.8),0.8,5,'M2 lid tapped pilot')
    # Service screws are outside the strip path and accessible with lid removed.
    for x in (-20,20):
        for y in (-6,6):hole(base,'Z',(x,y,-0.1),1.1,3.2,'Detachable shoe clearance')
    # Debris can leave the floor below the strip rather than collect at a blind end.
    for x in (-5,5):box(base,x-1,-2,-0.1,2,4,3.2,'Drain opening',CUT)
    paint(base,colors['metal'])
    base.attributes.add('Engineering','Manufacture','Machined aluminium datum part; printed duplicate is for fit only. M2 holes are tap-drill envelopes.')
    for n,x in enumerate((-15,15)):
        zlift=9 if exploded else 0
        g=component(group,'02 | POM guide '+str(n+1)+' | 0.20 lateral / 0.10 vertical clearance',(0,0,zlift))
        yz=[(-8,3),(8,3),(8,8.5),(2.8,8.5),(2.8,6.05),(4.1,6.05),(4.1,4.45),(-4.1,4.45),(-4.1,6.05),(-2.8,6.05),(-2.8,8.5),(-8,8.5)]
        section(g,x-3,yz,6,'Captured carrier edge bearing')
        for y in (-6.3,6.3):hole(g,'Z',(x,y,2.9),1.1,5.8,'Guide M2 clearance')
        paint(g,colors['white'])
        for y in (-6.3,6.3):screw(group,'guide M2 x 8','Z',(x,y,0.5+zlift+(5 if exploded else 0)),8,colors)
    moving=component(group,'MOVING | 160 mm stroke carrier test specimen')
    runner=component(moving,'03 | Smooth carrier 8 x 1.5 mm')
    box(runner,-120,-4,4.5,240,8,1.5,'Carrier')
    paint(runner,colors['metal'])
    strip=component(moving,'04 | MS05 bonded scale stack | 224 mm')
    box(strip,-112,-2.5,6,224,5,1.43,'Magnetic scale with adhesive')
    paint(strip,colors['orange'])
    foil=component(moving,'05 | Protective foil and adhesive | 0.126 mm')
    box(foil,-112,-2.4,7.43,224,4.8,0.126,'Protective foil stack')
    paint(foil,colors['metal'])
    # Use the actual manufacturer's STEP geometry. Original coordinates are mm;
    # Fusion matrices are cm. 90 degrees about X maps the original PCB upright.
    m=adsk.core.Matrix3D.create()
    m.setToRotation(math.pi/2,adsk.core.Vector3D.create(1,0,0),adsk.core.Point3D.create(0,0,0))
    m.translation=adsk.core.Vector3D.create(-0.88,(-1.09+(16 if exploded else 0))/10,(PCB_BOTTOM-1.775+(13 if exploded else 0))/10)
    pcb_occ=group.occurrences.addExistingComponent(vendor_component,m)
    pcb_occ.isLightBulbOn=True
    for x in (-7.5,7.5):
        screw(group,'encoder M2 x 6 - adjust gap before tightening','Y',(x,-4.982+(22 if exploded else 0),PCB_BOTTOM+4+(13 if exploded else 0)),6,colors,head_r=1.9,head_h=2)
    # A removable, tapered shell shields the mechanics; it is not a sliding bearing.
    cover=component(group,'07 | Tapered protective shell | remove to service',(0,0,37 if exploded else 0))
    polygon(cover,'Y',-11,[(-24,-11,3.1),(-24,-11,10),(-10,-11,23),(10,-11,23),(24,-11,10),(24,-11,3.1)],22,'Tapered pod exterior')
    polygon(cover,'Y',-9.8,[(-22.8,-9.8,2),(-22.8,-9.8,9.4),(-10.3,-9.8,21.8),(10.3,-9.8,21.8),(22.8,-9.8,9.4),(22.8,-9.8,2)],19.6,'Shell interior',CUT)
    for x in (-25,22):box(cover,x,-4.6,3.8,3,9.2,4.7,'Carrier entry clearance',CUT)
    for y in (-8,8):hole(cover,'Z',(0,y,21),1.1,4,'Lid screw clearance')
    # Downward-facing cable notch in side skirt; strain relief sits on the chassis.
    box(cover,4.5,9,3,4,4,4,'Remote electronics cable outlet',CUT)
    paint(cover,colors['dark'])
    if not exploded:
        # Open assembly is the default inspection view; finished silhouette is
        # available by turning this occurrence on in the browser.
        group.occurrences.itemByName(cover.name+':1').isLightBulbOn=False
    for y in (-8,8):screw(group,'lid M2 x 5','Z',(0,y,18+(42 if exploded else 0)),5,colors)
    # A small two-screw cable bar retains a 2.5 mm cable independently of solder pads.
    bar=component(group,'08 | Cable strain-relief bar | 2.5 mm cable',(0,0,8 if exploded else 0))
    box(bar,2,4.2,3,9,5.6,3,'Cable clamp')
    hole(bar,'Y',(6.5,4,3.9),1.25,6,'Cable cradle',CUT)
    for x in (3.3,9.7):
        hole(bar,'Z',(x,7,2.9),0.85,3.2,'M1.6 cable bar clearance')
        hole(base,'Z',(x,7,0.4),0.65,3,'M1.6 cable bar pilot')
        screw(group,'cable clamp M1.6 x 5','Z',(x,7,1+(13 if exploded else 0)),5,colors,radius=0.8,head_r=1.3,head_h=1)
    paint(bar,colors['dark'])
    # Curved replaceable shoe, with no brackets projecting beyond the pod.
    shoe=component(group,'09 | Curved adhesive shoe R22 | FOX LOWER RADIUS UNVERIFIED',(0,0,-12 if exploded else 0))
    ys=[-10+i for i in range(21)]
    bottom=[(y,-3-22+math.sqrt(22*22-y*y)) for y in reversed(ys)]
    section(shoe,-24,[(-10,0),(10,0)]+bottom,48,'Curved bonding shoe')
    for x in (-20,20):
        for y in (-6,6):hole(shoe,'Z',(x,y,-2.8),0.8,3,'M2 blind service pilot')
    for x in (-12,12):polygon(shoe,'Y',-11,[(x-2.6,-11,-2),(x+2.6,-11,-2),(x+2.6,-11,-0.9),(x-2.6,-11,-0.9)],22,'Recessed backup strap tunnel',CUT)
    paint(shoe,colors['dark'])
    for x in (-20,20):
        for y in (-6,6):screw(group,'shoe M2 x 5','Z',(x,y,-2+(4 if exploded else 0)),5,colors)
    group.attributes.add('Engineering','Status','Detailed bench prototype, not ride validated. Actual RLS STEP is the older through-hole A18 mechanical model; confirm ordered B00 revision before manufacture. No fork or shock CAD imported.')
    group.attributes.add('Engineering','Clearance','Nominal sensing gap 0.30 mm above protective foil; guide slot 8.20 x 1.60 for 8 x 1.50 carrier. Adjust board after measuring bonded strip. Guide clearance does not include manufacturing or thermal errors.')
    return group


def run(_context: str):
    app=adsk.core.Application.get()
    doc=app.documents.add(adsk.core.DocumentTypes.FusionDesignDocumentType)
    doc.name='Telemetry v6 | guided reader cartridge | revised'
    design=adsk.fusion.Design.cast(app.activeProduct)
    root=design.rootComponent
    options=app.importManager.createSTEPImportOptions(VENDOR)
    assert app.importManager.importToTarget2(options,root)
    assert root.occurrences.count==1,'Expected a single manufacturer assembly'
    vendor_occ=root.occurrences.item(0)
    vendor_component=vendor_occ.component
    vendor_occ.isLightBulbOn=False
    vendor_component.name='RLS RLC2IC through-hole | manufacturer STEP A18'
    colors={k:None for k in ('metal','dark','white','orange','blue')}
    lib=app.materialLibraries.itemByName('Fusion Appearance Library')
    if lib:
        for k,n in {'metal':'Aluminum - Satin','dark':'Plastic - Matte (Black)','white':'Plastic - Matte (White)','orange':'Plastic - Matte (Red)','blue':'Plastic - Matte (Blue)'}.items():
            a=lib.appearances.itemByName(n)
            if a:colors[k]=design.appearances.addByCopy(a,'v6 '+k)
    assembled=make_cartridge(root,'A | ASSEMBLED | shell hidden to inspect',(0,42,0),vendor_component,colors)
    exploded=make_cartridge(root,'B | EXPLODED | assembly order',(0,-42,0),vendor_component,colors,True)
    # One removable setup gauge: use across the scale while setting board height.
    gauge=component(root,'C | 0.30 mm nonmagnetic gap setup gauge',(30,-42,0))
    box(gauge,0,0,0,25,5,0.3,'Feeler gauge envelope')
    paint(gauge,colors['orange'])
    app.activeViewport.visualStyle=adsk.core.VisualStyles.ShadedWithVisibleEdgesOnlyVisualStyle
    app.activeViewport.fit()
    print(json.dumps({'document':doc.name,'features':design.timeline.count,'components':root.allOccurrences.count,'nominalGap_mm':0.3,'vendorCAD':True}))
