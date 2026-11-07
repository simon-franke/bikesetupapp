# Reader cartridge source

This component is the input to the current rear-mounted fork assembly.
Its standalone carrier is extended and remounted by the rear-mount builder.

Use `Reader_cartridge.f3d` for the editable assembly and exploded view.
`Reader_cartridge.step` contains the assembled cartridge only. The default
Fusion view has the cover and lid screws hidden to expose the mechanism.
Current assembly images are kept in `../previews/`.

This revision replaces the incorrect flat PCB envelope with the RLS through-hole
manufacturer STEP, standing upright with its 20 mm edge parallel to travel.
The supplied vendor CAD is the A18 mechanical revision; confirm it against the
ordered B00 encoder before manufacturing. The source file is preserved under
`vendor/`. The support seats follow the two slotted mounting pads: 15 mm pitch,
2.1 mm slot width, 2.8 mm centre-to-centre slot travel. Two M2 screw envelopes
hold the encoder against these seats. The slots permit gap adjustment; the
0.30 mm setup gauge is represented as a separate component.

The rigid chassis and two replaceable POM inserts establish the mechanical
reference. Each insert is 6 mm long; their centres are 30 mm apart. The guide
opening is 8.20 x 1.60 mm for an 8.00 x 1.50 mm smooth carrier: nominal total
clearances are 0.20 mm lateral and 0.10 mm vertical. Guide lips run only on the
carrier edges, with an open central relief for the magnetic scale and foil.
These are machining targets, not reliable as-printed FDM tolerances. Deburr and
finish all bearing edges. Confirm actual fit and thermal clearance on the bench.

The bonded scale stack is 1.43 mm plus 0.05 mm foil adhesive and 0.076 mm foil.
Nominal gap above the foil is 0.30 mm; set it after measuring the real bonded
stack. The 224 mm scale on a 240 mm carrier is a 160 mm stroke test specimen,
not a complete fork installation. The moving-end attachment is still separate
work, as are fork/shock mounts and full-system flex analysis.

The tapered shell is 48 x 22 x 23 mm excluding screw heads and the curved shoe.
The shoe radius is a provisional 22 mm, NOT a measurement of a Fox 36 lower.
Its mounting screws are accessible after removing the shell. Recessed backup
strap passages remain in the shoe. The adhesive itself is not modelled in v6.
A small two-screw cable bar provides a route toward remote electronics. Cable
routing from solder pads, bend radius and real jacket compression need a wiring
mock-up. Open entry ports and drain holes mean the housing is NOT waterproof;
contact wipers, a weather seal and breakaway/end-stop details are not included.

### Verification and fabrication boundary

`reader_cartridge_validation.json` reports no invalid custom solids, no unhealthy
features, and no non-fastener inter-part interference at -80, 0 and +80 mm.
Internal duplicate copper-pad overlaps in the original vendor STEP are excluded
explicitly; screw envelopes are excluded because threads are not modelled.
This is a three-position geometry check, not a continuous dynamic simulation or
proof of smooth sliding. No friction, force, grit, water, wear, vibration or
actual-bike test has been performed. The original v6 intermediate had unscoped
Fusion cuts; the revised build explicitly restricts every cut to its own part.

Chassis geometry is intended for machined aluminium with tapped holes; POM guide
inserts are intended to be machined. The thin shell and shoe are candidates for
printed prototypes. No STL is offered as a ride-ready part. Screw dimensions
are envelopes; final standards, lengths, materials and torque must be confirmed.
No actual fork or shock CAD is part of this revision.

Rebuild: run `build_reader_cartridge.py` through Fusion's script API, then
`check_reader_cartridge.py` and `export_reader_cartridge.py`. Build presets are
Python constants and editable native features, not fully linked user parameters.

Manufacturer sources:
- https://cdn.rls.si/documents/cad-models/RLC2ICAxxxxxxA18.zip
- https://www.rls.si/eng/rlc2ic-miniature-linear-and-rotary-pcb-level-incremental-magnetic-encoder
- https://cdn.rls.si/documents/datasheets/MSD01_10.pdf
