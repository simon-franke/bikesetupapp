# Approximate fork reference

The fork is an original simplified reference model created for this project,
not manufacturer CAD or a measured reproduction of the user's fork.

Source: FOX 2021-2022 36mm User Specifications, 29-inch Rev B drawing:
https://tech.ridefox.com/bike/spec-sheets/1090/2021-2022-36mm-user-specifications

Published dimensions used: 36 mm stanchions, 160 mm travel, 571 mm extended
axle-to-crown (411 mm compressed), 44 mm offset, 15 x 110 mm axle/hub interface,
and 263 mm uncut steerer. Wheel size and offset are assumptions for this study.
Leg spacing, lower-casting diameter/contours, arch, crown and brake bosses are
illustrative estimates. No manufacturer logos or styling accuracy claim.

## Rear-mounted assembly and exploded fork

`../../design/Fork_telemetry.f3d` contains both:
- E: assembled rear-mounted reader and upper crown attachment.
- F: exploded sensor and mounts, with the fork left assembled.

The reader is now behind the positive-X fork leg; its outward direction is
negative fork Y. Existing native cartridge designs and the v7 reference remain
in the project, hidden. The new placement assemblies are imported STEP solids.
They are not linked parametrically to the earlier native cartridge features.

New upper attachment:
- Curved 26 mm-wide, 19 mm-high crown-socket saddle, located Z510.5–529.5.
- Nominal 0.5 mm compliant liner against the stationary crown socket, clear of
  the exposed stanchion on the approximate fork.
- Two nominal 2.5 mm retaining bands around the socket, with lock-head envelopes.
- M2.5 insert, retaining screw and washer through the extended carrier tip.
- A 2.5 mm TPU spacer between carrier and saddle for limited compliance. This
  is NOT a spherical bearing or a verified misalignment/breakaway mechanism.

The carrier has a 20 mm extension beyond the previous tip and a 2.7 mm hole at
fork Z520. The magnetic portion remains unchanged. The lower curved shoe has
two 4.5 mm nominal retaining bands routed through the existing strap passages,
plus a 0.35 mm adhesive allowance. Bands and screw heads are geometry envelopes,
not selected purchased hardware; confirm actual widths, locking and tension.

Images: ../../previews/Rear_fork_overview.png, ../../previews/Rear_mounts_assembled.png,
../../previews/Rear_mounts_exploded.png and ../../previews/Rear_fork_exploded_overview.png.
STEP exports: ../../exports/Rear_fork_assembled.step and ../../exports/Rear_fork_exploded.step.

rear_mount_validation.json records valid custom shapes, accessory-versus-fork
clearance at 0/80/160 mm compression and band-versus-shoe overlap checks. It does
not validate dynamic fork flex, friction, upper-joint compliance, thread/insert
strength, strap retention, full accessory-to-accessory motion or actual bike
clearance. No frame, wheel, hose or steering envelope is present. Rear placement
requires a frame/down-tube check before riding. All crown and casting surfaces
remain approximations; measure the user's actual fork before fabrication.
