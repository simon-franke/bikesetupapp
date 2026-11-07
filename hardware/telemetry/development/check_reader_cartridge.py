"""Geometric checks only; not a friction, manufacturing or durability test."""
import adsk.core
import adsk.fusion
import json
OUT='/Users/simonmoritzfranke/code/bikesetupapp/hardware/telemetry/development'

def run(_context: str):
    app=adsk.core.Application.get()
    d=adsk.fusion.Design.cast(app.activeProduct)
    assert app.activeDocument.name=='Telemetry v6 | guided reader cartridge | revised'
    root=d.rootComponent
    unhealthy=[]
    for i in range(d.timeline.count):
        t=d.timeline.item(i)
        if t.objectType != 'adsk::fusion::TimelineGroup' and t.healthState!=adsk.fusion.FeatureHealthStates.HealthyFeatureHealthState:
            unhealthy.append({'name':t.name,'message':t.errorOrWarningMessage})
    invalid_solids=[]
    for o in root.allOccurrences:
        if o.fullPathName.startswith('A | ASSEMBLED') and not o.component.name.startswith('RLS '):
            for b in o.component.bRepBodies:
                if not b.isSolid or b.volume<=1e-9:invalid_solids.append(o.fullPathName)
    moving=next(o for o in root.allOccurrences if o.fullPathName.startswith('A | ASSEMBLED') and o.component.name.startswith('MOVING |'))
    original=moving.transform2.copy()
    samples=[]
    try:
        for position in (-80,0,80):
            t=original.copy();tr=t.translation;tr.x+=position/10;t.translation=tr
            moving.transform2=t
            entities=adsk.core.ObjectCollection.create()
            for occ in root.allOccurrences:
                if occ.fullPathName.startswith('A | ASSEMBLED') and occ.component.bRepBodies.count and not occ.component.name.startswith('FASTENER |'):
                    entities.add(occ)
            inp=d.createInterferenceInput(entities)
            inp.areCoincidentFacesIncluded=False
            result=d.analyzeInterference(inp)
            pairs=[{'a':r.entityOne.parentComponent.name,'b':r.entityTwo.parentComponent.name,'volume_mm3':r.interferenceBody.volume*1000} for r in result if r.interferenceBody.volume>1e-8 and not (r.entityOne.parentComponent.name.startswith('RLS ') and r.entityTwo.parentComponent.name.startswith('RLS '))]
            samples.append({'position_mm':position,'interferences':pairs})
    finally:
        moving.transform2=original
    report={'timeline_features':d.timeline.count,'invalid_solids':invalid_solids,'unhealthy_features':unhealthy,'stroke_samples':samples,'excluded':'Screw envelopes, exploded display and original vendor source occurrence. Threads are not modelled. Internal overlaps between duplicate copper pads in the manufacturer STEP are separately excluded.','not_tested':'Physical friction, material tolerances, debris, cable forces, shock/fork mounting and flex.'}
    with open(OUT+'/reader_cartridge_validation.json','w') as f:json.dump(report,f,indent=2)
    app.activeViewport.fit()
    app.activeViewport.saveAsImageFile(OUT+'/Reader_cartridge_overview.png',1600,1100)
    print(json.dumps(report))
