"""Export the completed v6 cartridge and three inspection views."""
import adsk.core
import adsk.fusion
import json
OUT='/Users/simonmoritzfranke/code/bikesetupapp/hardware/telemetry/development'

def run(_context: str):
    app=adsk.core.Application.get();doc=app.activeDocument
    assert doc.name=='Telemetry v6 | guided reader cartridge | revised'
    d=adsk.fusion.Design.cast(app.activeProduct);root=d.rootComponent
    a=next(o for o in root.occurrences if o.component.name.startswith('A |'))
    b=next(o for o in root.occurrences if o.component.name.startswith('B |'))
    # The source copy is nested under its own hidden parent so shared vendor
    # occurrences can be visible in the assemblies.
    source=next((o for o in root.occurrences if o.component.name.startswith('RLS ')),None)
    if source:
        folder=root.occurrences.addNewComponent(adsk.core.Matrix3D.create())
        folder.component.name='SOURCE | RLS manufacturer CAD | hidden reference'
        assert source.moveToComponent(folder)
    for o in root.allOccurrences:
        if o.component.name.startswith('RLS '):o.isLightBulbOn=True
    for o in root.occurrences:
        if o.component.name.startswith(('SOURCE |','C |')):o.isLightBulbOn=False
    shell=next(o for o in a.component.occurrences if o.component.name.startswith('07 |'))
    lid_screws=[o for o in a.component.occurrences if o.component.name.startswith('FASTENER | lid')]
    def camera(eye,target,extent):
        cam=app.activeViewport.camera
        cam.eye=adsk.core.Point3D.create(*eye);cam.target=adsk.core.Point3D.create(*target)
        cam.upVector=adsk.core.Vector3D.create(0,0,1)
        cam.isPerspective=False;cam.isFitView=False;cam.viewExtents=extent
        app.activeViewport.camera=cam;app.activeViewport.refresh()
    a.isLightBulbOn=True;b.isLightBulbOn=False;shell.isLightBulbOn=True
    for o in lid_screws:o.isLightBulbOn=True
    camera((7,12,7),(0,4.2,1.1),7)
    assert app.activeViewport.saveAsImageFile(OUT+'/Reader_cartridge_closed.png',1600,1100)
    shell.isLightBulbOn=False
    for o in lid_screws:o.isLightBulbOn=False
    assert app.activeViewport.saveAsImageFile(OUT+'/Reader_cartridge_detail.png',1600,1100)
    a.isLightBulbOn=False;b.isLightBulbOn=True
    camera((9,7,11),(0,-4.2,2.5),11)
    assert app.activeViewport.saveAsImageFile(OUT+'/Reader_cartridge_exploded.png',1600,1200)
    # STEP is the assembled mechanical cartridge, not the exploded/source copies.
    a.isLightBulbOn=True;b.isLightBulbOn=False;shell.isLightBulbOn=True
    for o in lid_screws:o.isLightBulbOn=True
    em=d.exportManager
    original=a.transform2.copy()
    try:
        # Fusion exports a component's nested occurrence overrides in root space.
        # Normalise its parent to the origin for the export, then restore display.
        a.transform2=adsk.core.Matrix3D.create()
        assert em.execute(em.createSTEPExportOptions(OUT+'/Reader_cartridge.step',a.component))
    finally:
        a.transform2=original
    shell.isLightBulbOn=False
    for o in lid_screws:o.isLightBulbOn=False
    camera((7,12,7),(0,4.2,1.1),7)
    assert em.execute(em.createFusionArchiveExportOptions(OUT+'/Reader_cartridge.f3d'))
    # Close only the failed intermediate created in this task; preserve all user
    # documents and earlier completed designs.
    for old in list(app.documents):
        if old.name=='Telemetry v6 | guided reader cartridge':old.close(False)
    doc.activate()
    print(json.dumps({'fusionArchive':'Reader_cartridge.f3d','assembledSTEP':'Reader_cartridge.step','views':['Reader_cartridge_detail.png','Reader_cartridge_closed.png','Reader_cartridge_exploded.png']}))
