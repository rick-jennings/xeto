<!--
title:      EquipTemplates
author:     Rick Jennings
created:    9 Sep 2026
copyright:  Copyright (c) 2026, Project-Haystack
-->

# Equip Templates
An equip template models a piece of equipment from a manufacturer as an extension of
[ph::Equip] using attributes and points. The site-specific tags defined in the
[Equips](Equips.md) chapter, such as `siteRef` and `spaceRef`, are not part of
an equip template because it is not bound to a location.

# Attributes
An attribute is a single piece of static information about a piece of equipment,
such as its manufacturer, model, or physical dimensions, modeled as a subtype
of [ph::Attr]. At this time, only `Attr` subtypes already defined in the core
`ph.attrs` library should be used in an equip template to avoid overwhelming
reviewers.

# Points
Project Haystack supports modeling all data points made available by a manufacturer,
including those outside Haystack's standard vocabulary, by applying the `notHaystack`
marker tag to the applicable points. These points still extend [ph::PhEntity]
even though their meaning is not fully expressed by a standard spec required
for interoperability.

Each point should include every protocol address available for it, modeled as a
[ph.protocols::ProtocolAddr] such as [ph.protocols::ModbusAddr] or
[ph.protocols::BacnetAddr].

Every point in an equip template must have a `dis` tag defined according to the
manufacturer's documentation. When the documentation gives conflicting definitions
(for example, a point available via both Modbus and BACnet with mismatched
descriptions), resolving the conflict is the responsibility of the tool creating
the template.

# Example

```xeto
// Sample device model for a generic manufacturer's power meter
ExampleAcElecMeter : AcElecMeter {
  attrs: {
    ManufacturerAttr { val: "Example Manufacturer" }
    ModelSeriesAttr { val: "Example Series 100" }
  }
  points: {
    // non-standard point
    NumberPoint {
      sensor
      dis: "Real Part of Voltage Positive Sequence"
      unit: Unit <invariant> "%"
      notHaystack
      modbusAddr: { addr: "416385", encoding: "f4" }
      bacnetAddr: { addr: "AI3" }
    }
    // standard point
    ElecAcPhaseRmsVoltageSensor {
      phase: "L1"
      dis: "L1 Voltage"
      modbusAddr: { addr: "416387", encoding: "f4" }
      bacnetAddr: { addr: "AI4" }
    }
  }
}
```
