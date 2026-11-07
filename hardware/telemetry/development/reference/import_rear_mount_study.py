import adsk.core,adsk.fusion,json
OUT='/Users/simonmoritzfranke/code/bikesetupapp/hardware/telemetry/development'
def run(_context: str):
    app=adsk.core.Application.get();doc=app.activeDocument
    assert doc.name in ('Telemetry v7 | fork placement reference','Telemetry v8 | rear mounts and exploded fork'),doc.name
    design=adsk.fusion.Design.cast(app.activeProduct);root=design.rootComponent
    for o in list(root.occurrences):
        if o.component.name.startswith(('E | REAR MOUNTED','F | REAR EXPLODED')):
            o.deleteMe()
        else:o.isLightBulbOn=False
    views=[]
    for file,label in [('Rear_fork_assembled.step','E | REAR MOUNTED | upper crown saddle + lower reader'),('Rear_fork_exploded.step','F | REAR EXPLODED | fork stays assembled')]:
        opts=app.importManager.createSTEPImportOptions(OUT+'/../exports/'+file)
        result=app.importManager.importToTarget2(opts,root)
        assert result and result.count
        o=adsk.fusion.Occurrence.cast(result.item(0));o.component.name=label
        o.component.attributes.add('Engineering','Status','Approximate fork. Crown saddle contacts crown socket only; no stanchion clamp. Nominal retaining bands, compliance spacer and fasteners require physical fitting and retention tests. No frame or steering clearance check.')
        views.append(o);o.isLightBulbOn=False
    assembled,exploded=views
    doc.name='Telemetry v8 | rear mounts and exploded fork'
    def camera(eye,target,extent):
        cam=app.activeViewport.camera
        cam.eye=adsk.core.Point3D.create(*eye);cam.target=adsk.core.Point3D.create(*target)
        cam.upVector=adsk.core.Vector3D.create(0,0,1)
        cam.isPerspective=False;cam.isFitView=False;cam.viewExtents=extent
        app.activeViewport.camera=cam;app.activeViewport.refresh()
    assembled.isLightBulbOn=True
    camera((110,-150,95),(0,1,40),98)
    assert app.activeViewport.saveAsImageFile(OUT+'/../previews/Rear_fork_overview.png',1200,1500)
    camera((100,-130,78),(7,-2,40),40)
    assert app.activeViewport.saveAsImageFile(OUT+'/../previews/Rear_mounts_assembled.png',1400,1400)
    assembled.isLightBulbOn=False;exploded.isLightBulbOn=True
    camera((130,-110,90),(7,-6,40),44)
    assert app.activeViewport.saveAsImageFile(OUT+'/../previews/Rear_mounts_exploded.png',1600,1500)
    camera((130,-130,95),(0,-4,40),98)
    assert app.activeViewport.saveAsImageFile(OUT+'/../previews/Rear_fork_exploded_overview.png',1200,1500)
    # Leave the requested exploded fork/mount view visible in Fusion.
    camera((130,-110,90),(7,-6,40),44)
    assert design.exportManager.execute(design.exportManager.createFusionArchiveExportOptions(OUT+'/../design/Fork_telemetry.f3d'))
    print(json.dumps({'document':doc.name,'assembled_component':assembled.component.name,'exploded_component':exploded.component.name,'archive':'Fork_telemetry.f3d'}))
