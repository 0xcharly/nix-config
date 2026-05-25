# Daedalus - Minisforum N5 Pro

Japan NAS primary node.

# Hardware Stability Note — ZFS Transfer Reboots

During testing across several builds, identical NixOS + ZFS configurations
exhibited **unexpected, silent reboots during heavy ZFS send/receive transfers**
on multiple systems that used **consumer-grade SATA controllers** (MSI B650I
Edge Wi-Fi, Intel NUC Skull).

## Root Cause (probable)

These boards use **desktop-class AHCI controllers** integrated into the chipset.
Under sustained multi-disk I/O load, ZFS drives high queue depths and continuous
DMA traffic. This can trigger:

- SATA firmware or power-management faults (ALPM, ASP)
- Transient 12 V dips under HDD load (especially 4× 24 TB HDDs in SFF cases)
- Chipset-level IOMMU or PCIe bus errors, causing a platform reset before the
  kernel can log anything

## Resolution

Migrating to purpose-built NAS hardware (Minisforum N5 Pro NAS base, with
dedicated SATA backplane and stable power delivery) **completely eliminated the
reboots**.

Same OS, same kernel, same ZFS version — only the storage controller changed.

## Recommended Practices

If you build or clone this setup elsewhere:

- Prefer **NAS-grade or server-grade SATA / HBA controllers** (ASMedia 1166,
  Marvell 88SE92xx, Broadcom HBA series, etc.)
- Avoid consumer motherboard SATA ports for 24/7 multi-disk ZFS workloads
- Use a **reliable PSU** sized for all-disk spin-up current
- Optionally add these kernel parameters to reduce SATA power quirks (untested):

```nix
boot.kernelParams = [
  "libata.force=noncq"      # disable NCQ (avoids buggy AHCI firmware)
  "libata.noacpi=1"         # ignore ACPI link power mgmt
];
```

## Enable persistent journald and panic-on-oops to capture future kernel-level issues:

```nix
services.journald.extraConfig = "Storage=persistent";
boot.kernel.sysctl = {
  "kernel.panic_on_oops" = 1;
  "kernel.panic" = 10;
};
```

## Summary

ZFS wasn’t the problem — the hardware was.

Sustained ZFS I/O exposes flaws in consumer SATA implementations; NAS-grade
controllers or HBAs resolve the issue entirely.
