<!--
title:      Equip Operation
author:     Rick Jennings
created:    2 Mar 2026
copyright:  Copyright (c) 2026, Project-Haystack
-->

# Overview

Equipment operation is modeled using four base point specs:
[ph.points::RunCmd], [ph.points::RunSensor], [ph.points::EnableCmd], and
[ph.points::ModulatingPoint].

The first three are Boolean points that use the [ph.points::RunEnum]
enumeration, where `false` represents the *off* state and `true` represents
the *on* (or *enabled*) state.  Together they express how equipment is
commanded on and off, how its running state is measured, and how safety or
supervisory interlocks are applied.

[ph.points::ModulatingPoint] complements these with continuous variable
control, expressing capacity, speed, or valve position as a percentage
from 0% (fully off or fully closed) to 100% (fully on or fully open).

# RunCmd

[ph.points::RunCmd] is the primary on/off command for a piece of equipment.

# RunSensor

While `RunCmd` expresses what the controller has *commanded*, `RunSensor`
expresses what the equipment is *actually doing*.  A discrepancy between the
two can indicate a fault — for example, a motor that was commanded on but is
not running.

# EnableCmd

Equipment will only run when **both** the `RunCmd` and the `EnableCmd` are
true.  The `RunCmd` expresses local or scheduled intent to run, while the
`EnableCmd` expresses permission from a higher-level system or safety logic.
When `EnableCmd` is false, the equipment is prohibited from running regardless
of the `RunCmd` state.

A common example is a chilled water plant controller that writes `EnableCmd`
on a fan or pump only when chilled water is available.  The local AHU
controller may be commanding the fan on (`RunCmd = true`), but the fan will
not run until the plant controller also sets `EnableCmd = true`.

# ModulatingPoint

Unlike the on/off Boolean points above, modulating points represent a
continuously variable output or measurement:
- **0%** — fully off or fully closed
- **100%** — fully on or fully open

# Summary

| Spec | Kind | Function | Description |
|---|---|---|---|
| [ph.points::RunCmd] | Bool | cmd | Primary on/off command to run equipment |
| [ph.points::RunSensor] | Bool | sensor | Feedback sensor for actual on/off run state |
| [ph.points::EnableCmd] | Bool | cmd | Supervisory interlock — permits or prohibits the run command |
| [ph.points::ModulatingPoint] | Number | cmd/sensor | Variable capacity or speed as a percentage 0–100% |

Equipment will only be running when `RunCmd = on` **and** `EnableCmd = on`,
and `RunSensor` should read `on` to confirm it.
