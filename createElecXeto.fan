/*
TODO:
1. Determine what AC freq leaf specs to create
2. Implement community feedback
*/


enum class PointKind { sensor, sp }
enum class PrimaryQuantity { volt, current, power, energy, demand, pf, freq }
enum class LocKind { phasePower, linePower, phaseCurrent, lineCurrent,
                     phaseVolt, lineVolt, phaseEnergy, lineEnergy,
                     phasePf, linePf, phaseDemand, lineDemand, aggregate }


class CreateElecXeto
{
    File file := File.make(`src/xeto/ph.points/elec.xeto`)

    // AC subtypes
    List acPowerSubtypes := ["active", "reactive", "apparent"]
    List acVoltOrCurrentSubtypes := ["magnitude", "angle", "thd", "imbalance"]

    // AC aggregate locs
    List acPowerAggregateLocs := ["lineAvg", "phaseAvg", "total"]
    List acVoltOrCurrentAggregateLocs := ["lineAvg", "phaseAvg"]

    Void main()
    {
        // open as an empty file
        out := this.file.out
        out.close

        // temp specs - in the future we plan to have these in a trio file
        createTempSpecs

        // elec and elec type specs
        PointKind.vals.each |v| { createElecAndElecTypeSpecs(v) }

        // setpoint type specs
        createSetpointTypes()

        // primary quantity specs
        PointKind.vals.each |v| { createPrimaryQuantitySpecs(v) }

        // DC specs
        PointKind.vals.each |v| { createDcSpecs(v) }

        // AC power specs
        createAcSpecs(PointKind.sensor, PrimaryQuantity.power,
                      acPowerSubtypes, acPowerAggregateLocs)
        createAcSpecs(PointKind.sp, PrimaryQuantity.power,
                      acPowerSubtypes, acPowerAggregateLocs[-1..-1])

        // AC energy specs
        createAcSpecs(PointKind.sensor, PrimaryQuantity.energy,
                      acPowerSubtypes, ["total", "avg"])

        // AC current specs
        createAcSpecs(PointKind.sensor, PrimaryQuantity.current,
                      acVoltOrCurrentSubtypes, acVoltOrCurrentAggregateLocs)
        createAcSpecs(PointKind.sp, PrimaryQuantity.current,
                      acVoltOrCurrentSubtypes[0..0], [,])

        // AC voltage specs
        createAcSpecs(PointKind.sensor, PrimaryQuantity.volt,
                      acVoltOrCurrentSubtypes, acVoltOrCurrentAggregateLocs)

        // AC demand specs
        createAcSpecs(PointKind.sensor, PrimaryQuantity.demand,
                      acPowerSubtypes, acPowerAggregateLocs[-1..-1])

        // AC power factor specs
        createAcSpecs(PointKind.sensor, PrimaryQuantity.pf,
                      [,], acPowerAggregateLocs)
    }


    Void createSetpointTypes() {

        out := this.file.out(true)
        out.printLine(makeSeparator)
        out.printLine("// Setpoint types for electricity")
        out.printLine(makeSeparator)
        out.printLine

        out.printLine("// Setpoint for maximum electric primary quantity")
        out.printLine("ElecMaxSp : ElecSp { max }")

        out.close
    }



    Void createTempSpecs() {

        out := this.file.out(true)
        out.printLine(makeSeparator)
        out.printLine("// Temporary defs - later we will put them in def trio")
        out.printLine(makeSeparator)
        out.printLine

        out.printLine("ElecLine : Enum {")
        out.printLine("  pL1 <key:\"L1\">")
        out.printLine("  pL2 <key:\"L2\">")
        out.printLine("  pL3 <key:\"L3\">")
        out.printLine("}")
        out.printLine

        out.printLine("ElecLineToLine : Enum {")
        out.printLine("  pL1L2 <key:\"L1-L2\">")
        out.printLine("  pL2L3 <key:\"L2-L3\">")
        out.printLine("  pL3L1 <key:\"L3-L1\">")
        out.printLine("}")
        out.printLine

        out.printLine("ElecLineToNeutral : Enum {")
        out.printLine("  pL1N <key:\"L1-N\">")
        out.printLine("  pL2N <key:\"L2-N\">")
        out.printLine("  pL3N <key:\"L3-N\">")
        out.printLine("}")
        out.printLine


        out.close
    }


    Void createElecAndElecTypeSpecs(PointKind pointKind) {

        OutStream out := this.file.out(true)

        pointKindDis := findPointKindDis(pointKind)

        out.printLine(makeSeparator)
        out.printLine("// ${pointKindDis} for electricity (abstract)")
        out.printLine(makeSeparator)
        out.printLine

        out.printLine("// ${pointKindDis} for electricity")
        out.printLine("Elec${pointKind.name.capitalize} : NumberPoint & "
                      + "${pointKind.name.capitalize} <abstract> "
                      + "{ elec }")
        out.printLine

        out.printLine(makeSeparator)
        out.printLine("// ${pointKindDis}s for electricity type (abstract)")
        out.printLine(makeSeparator)
        out.printLine

        ["ac", "dc"].each |v| {
            out.printLine("// ${pointKindDis} for ${v.upper} electricity")
            out.printLine("Elec${v.capitalize}${pointKind.name.capitalize} : "
                        + "Elec${pointKind.name.capitalize} <abstract> { ${v} }")
            out.printLine
        }
        out.close
    }


    Str findBaseUnit(PrimaryQuantity x) {

        unit := ""
        if (x == PrimaryQuantity.volt) { unit = "V" }
        else if (x == PrimaryQuantity.current) { unit = "A" }
        else if (x == PrimaryQuantity.power || x == PrimaryQuantity.demand) {
            unit = "kW"
        }
        else if (x == PrimaryQuantity.energy) { unit = "kWh" }
        else if (x == PrimaryQuantity.pf) { unit = "" } // maybe make null instead?
        else if (x == PrimaryQuantity.freq) {unit = "Hz"}

        return unit
    }


    Str findUnitQuantity(PrimaryQuantity x) {

        unitQuantity := ""
        if (x == PrimaryQuantity.volt) { unitQuantity = "electricPotential" }
        else if (x == PrimaryQuantity.current) { unitQuantity = "electricCurrent" }
        else if (x == PrimaryQuantity.power || x == PrimaryQuantity.demand) {
            unitQuantity = "power"
        }
        else if (x == PrimaryQuantity.energy) { unitQuantity = "energy" }
        else if (x == PrimaryQuantity.pf) { unitQuantity = "" } // maybe make null instead?
        else if (x == PrimaryQuantity.freq) {unitQuantity = "frequency"}

        return unitQuantity
    }

    // TODO: combine applyMax() and applyMaxDis()
    Str applyMax(PointKind pointKind, PrimaryQuantity primaryQuantity)
    {
        applyMax := ""

        if (pointKind == PointKind.sp) {
            if (primaryQuantity == PrimaryQuantity.current ||
                primaryQuantity == PrimaryQuantity.power ||
                primaryQuantity == PrimaryQuantity.demand ||
                primaryQuantity == PrimaryQuantity.energy
                ) {
                    applyMax = "Max"
                }
            }

        return applyMax
    }


    Str applyMaxDis(PointKind pointKind, PrimaryQuantity primaryQuantity)
    {
        applyMax := ""

        if (pointKind == PointKind.sp) {
            if (primaryQuantity == PrimaryQuantity.current ||
                primaryQuantity == PrimaryQuantity.power ||
                primaryQuantity == PrimaryQuantity.demand ||
                primaryQuantity == PrimaryQuantity.energy
                ) {
                    applyMax = "maximum "
                }
            }

        return applyMax
    }


    Void createPrimaryQuantitySpecs(PointKind pointKind) {

        out := this.file.out(true)

        pointKindDis := findPointKindDis(pointKind)

        // add section title
        out.printLine(makeSeparator)
        out.printLine("// ${pointKindDis}s for primary quantities "
                      + "(all specs, except freq, are abstract)")
        out.printLine(makeSeparator)
        out.printLine

        // create each spec
        PrimaryQuantity.vals.each |v| {

            // only on current, power, and demand setpoints apply "max"
            applyMax := applyMax(pointKind, v)
            applyMaxDis := applyMaxDis(pointKind, v)

            primaryQuantityDis := findPrimaryQuantityDis(v)
            unitQuantity := findUnitQuantity(v)
            baseUnit := findBaseUnit(v)

            specType := "<abstract> "
            if (v.name == "freq") { specType = "& ElecAc" + pointKind.name.capitalize
                                    + " " }

            out.printLine("// ${pointKindDis} for " + applyMaxDis
                            + "electric " + primaryQuantityDis)

            x1 := "Elec" + v.name.capitalize + applyMax
                            + pointKind.name.capitalize + " : "
                            + "Elec" + applyMax + pointKind.name.capitalize + " "
                            + specType + "{"

            if (v == PrimaryQuantity.pf) {
                out.printLine(x1 + " " + v.name + " }")
            }
            else {
                out.printLine(x1)
                out.printLine("  " + v.name)
                out.printLine("  unit: Unit<quantity:\"${unitQuantity}\""
                                + "> \"${baseUnit}\"")
                out.printLine("}")
            }
            out.printLine
        }

        out.close
    }


    Void createDcSpecs(PointKind pointKind) {

        OutStream out := this.file.out(true)

        pointKindDis := findPointKindDis(pointKind)

        out.printLine(makeSeparator)
        out.printLine("// ${pointKindDis}s for DC electricity type (leaves)")
        out.printLine(makeSeparator)
        out.printLine

        dcPrimaryQuantities := [ PrimaryQuantity.current,
                                 PrimaryQuantity.volt,
                                 PrimaryQuantity.power,
                                 PrimaryQuantity.energy ]

        dcPrimaryQuantities.each |v| {
            // do not create setpoints for energy
            if ((pointKind == PointKind.sp) && (v == PrimaryQuantity.energy)) {
                echo()
                // would be nice to continue instead
            }
            else {

                // only on current, power, and demand setpoints apply "max"
                applyMax := applyMax(pointKind, v)
                applyMaxDis := applyMaxDis(pointKind, v)

                out.printLine("// ${pointKindDis} for " + applyMaxDis + "DC electric "
                            + findPrimaryQuantityDis(v))
                out.printLine("ElecDc" + v.name.capitalize + applyMax
                                + pointKind.name.capitalize
                                + " : Elec" + v.name.capitalize + applyMax
                                + pointKind.name.capitalize
                                + " & ElecDc" + pointKind.name.capitalize)
                out.printLine
            }
        }

        out.close
    }


    Void createAcSpecs(PointKind pointKind,
                       PrimaryQuantity primaryQuantity,
                       List subtypes,
                       List aggregateLocs) {

        // map created loc spec names to their docs to later create direction specs
        Str:Str specNameToDocMap := [:] { ordered = true }

        // create subtype specs
        if (subtypes.size > 0) {
            createAcSubtypes(pointKind, primaryQuantity, subtypes)
        }

        // create single location specs
        if (primaryQuantity != PrimaryQuantity.demand) {
            // AC phase locs
            locKind := LocKind("phase" + primaryQuantity.name. capitalize)
            s1 := createAcSingleLocSpecs(pointKind, primaryQuantity,
                                         locKind, subtypes)
            specNameToDocMap = specNameToDocMap.addAll(s1)

            // AC line locs
            locKind = LocKind("line" + primaryQuantity.name.capitalize)
            s2 := createAcSingleLocSpecs(pointKind, primaryQuantity,
                                         locKind, subtypes)
            specNameToDocMap = specNameToDocMap.addAll(s2)
        }

        // create aggregate location specs
        if (aggregateLocs.size != 0) {
            a1 := createAcAggregateLocSpecs(pointKind, primaryQuantity,
                                            subtypes, aggregateLocs)
            specNameToDocMap = specNameToDocMap.addAll(a1)
        }

        // create direction specs
        if (hasDirection(primaryQuantity)) {
            createAcDirectionSpecs(pointKind, primaryQuantity, specNameToDocMap)
        }
    }


    Void createAcSubtypes(PointKind pointKind,
                          PrimaryQuantity primaryQuantity,
                          List subtypes) {

        out := this.file.out(true)

        pointKindDis := findPointKindDis(pointKind)
        primaryQuantityDis := findPrimaryQuantityDis(primaryQuantity)

        // add section title
        out.printLine(makeSeparator)
        out.printLine("// ${pointKindDis}s for AC " + primaryQuantityDis
                      + " subtypes (abstract)")
        out.printLine(makeSeparator)
        out.printLine

        // only on current, power, and demand setpoints apply "max"
        applyMax := applyMax(pointKind, primaryQuantity)
        applyMaxDis := applyMaxDis(pointKind, primaryQuantity)

        // create each spec
        subtypes.each |v| {

            out.printLine("// ${pointKindDis} for ${applyMaxDis}AC "
                          + findSubtypeDis(v) + " "
                          + primaryQuantityDis)
            out.printLine("Elec" + v.toStr.capitalize + primaryQuantity.name.capitalize
                          + applyMax
                          + pointKind.name.capitalize + " : "
                          + "Elec" + primaryQuantity.name.capitalize
                          + applyMax
                          + pointKind.name.capitalize + " & ElecAc"
                          + pointKind.name.capitalize
                          + " <abstract> { ${v} }")
            out.printLine
        }

        out.close

    }


    Str:Str createAcSingleLocSpecs(PointKind pointKind,
                                   PrimaryQuantity primaryQuantity,
                                   LocKind locKind,
                                   List subtypes)
    {
        out := this.file.out(true)

        // define display names
        pointKindDis := findPointKindDis(pointKind)
        primaryQuantityDis := findPrimaryQuantityDis(primaryQuantity)

        locTypeDis := ""
        if (locKind.name.contains("phase")) { locTypeDis = "phase" }
        else if (locKind.name.contains("line")) { locTypeDis = "line" }

        // only on current, power, and demand setpoints apply "max"
        applyMax := applyMax(pointKind, primaryQuantity)
        applyMaxDis := applyMaxDis(pointKind, primaryQuantity)

        // create a spec based on line or line to line location enum
        out.printLine(makeSeparator)
        out.printLine("// ${pointKindDis}s for the ${locTypeDis} location of AC " +
                                "electric ${primaryQuantityDis} (abstract)")
        out.printLine(makeSeparator)
        out.printLine
        out.printLine("// ${pointKindDis} for " + locTypeDis + " "
                    + applyMaxDis + "AC electric ${primaryQuantityDis}")
        out.printLine("Elec${locTypeDis.capitalize}"
                    + primaryQuantity.name.capitalize
                    + applyMax
                    + "${pointKind.name.capitalize} : Elec"
                    + primaryQuantity.name.capitalize
                    + applyMax
                    + pointKind.name.capitalize
                    + " & ElecAc" + pointKind.name.capitalize + " "
                    + "<abstract> "
                    + "{ ${locTypeDis}"
                    + primaryQuantity.name.capitalize
                    + ": "
                    + findLineConfig(locTypeDis, primaryQuantity)
                    + " }")
        out.printLine
        out.close

        // create AC location specs
        specsMap := createAcLocSpecs(pointKind,
                                     primaryQuantity,
                                     subtypes,
                                     findAcPhaseLocs(primaryQuantity, locKind),
                                     locKind)
        return specsMap
    }


    Str:Str createAcAggregateLocSpecs(PointKind pointKind,
                                      PrimaryQuantity primaryQuantity,
                                      List subtypes, List locs) {
        // AC Aggregate Power Locations (Abstract Classes)
        aggregateSectionText := findPointKindDis(pointKind)
                        + "s for the aggregate location of AC electric "
                        + "${findPrimaryQuantityDis(primaryQuantity)} "

        if (hasDirection(primaryQuantity)) { aggregateSectionText += "(abstract)" }
        else                               { aggregateSectionText += "(leaves)" }

        out := this.file.out(true)
        out.printLine(makeSeparator)
        out.printLine("// ${aggregateSectionText}")
        out.printLine(makeSeparator)
        out.printLine
        out.close

        specNameToDocMap := createAcLocSpecs(pointKind,
                                             primaryQuantity,
                                             subtypes,
                                             locs,
                                             LocKind.aggregate)

        return specNameToDocMap
    }


    Str:Str createAcLocSpecs(PointKind pointKind,
                             PrimaryQuantity primaryQuantity,
                             List subtypes,
                             List locs,
                             LocKind locKind) {

        // keep track of specs that are created
        Str:Str specsMap := [:] { ordered = true }

        // power factor specs have no subtypes
        if (primaryQuantity == PrimaryQuantity.pf) { subtypes = [""] }

        // create aggregate loc specs for each of the subtypes, except for power factor
        subtypes.each |v1| {
            locs.each |v2| {
                specMap := addAcLocSpec(pointKind, primaryQuantity,
                                        locKind, v1, v2)
                specsMap = specsMap.addAll(specMap)
            }
        }

        return specsMap
    }


    // creates a single location and returns the spec name
    Str:Str addAcLocSpec(PointKind pointKind,
                         PrimaryQuantity primaryQuantity,
                         LocKind locKind, Str subtype, Str loc)
    {
        out := this.file.out(true)

        // only on current, power, and demand setpoints apply "max"
        applyMax := applyMax(pointKind, primaryQuantity)
        applyMaxDis := applyMaxDis(pointKind, primaryQuantity)

        // add line to file for docs
        docLine := getAcLocDocs(pointKind, primaryQuantity, subtype, loc)
        out.printLine(docLine)

        // add line to file defining Class name and subclasses
        baseSubtypeClassName := "Elec" + subtype.capitalize
                                    + primaryQuantity.name.capitalize
                                    + applyMax
                                    + pointKind.name.capitalize

        newSpecName := "Elec" + loc.replace("-","").capitalize
                        + baseSubtypeClassName[4..-1]

        // define the spec name and what it inherits from
        x1 := newSpecName + " : "
        if (locKind != LocKind.aggregate) {
            baseLocClassName := "Elec" + locKind.name.capitalize
                                + applyMax
                                + pointKind.name.capitalize
            // handle the case where there is no subtype
            z1 := ""
            if (subtype != "") { z1 = baseSubtypeClassName + " & "}
            x1 += z1 + baseLocClassName + " "
        }
        else {
            x1 = x1 + "${baseSubtypeClassName} "
            // handle case there is a subtype
            if (subtype == "") { x1 = x1 + "& ElecAcSensor " }
        }

        // define whether the spec is abstract or not
        if (hasDirection(primaryQuantity)) { x1 = x1 + "<abstract> {" }
        else                               { x1 = x1 + "{" }

        // define the tag and if applicable it's value
        if (locKind != LocKind.aggregate) {
            x1 = x1 + " " + locKind.name + ": " + "\"" + loc + "\"" + " }"
        }
        else { x1 = x1 + " " + loc + " }" }

        out.printLine(x1)
        out.printLine
        out.close

        return [newSpecName: docLine]
    }


    Void createAcDirectionSpecs(PointKind pointKind,
                                PrimaryQuantity primaryQuantity,
                                Str:Str specDocMap) {

        // AC Power Directions (Leaf Classes)
        t1 := findPointKindDis(pointKind) + "s for the direction of AC electric "
                + findPrimaryQuantityDis(primaryQuantity) + " (leaves)"
        out := this.file.out(true)
        out.printLine(makeSeparator)
        out.printLine("// ${t1}")
        out.printLine(makeSeparator)
        out.printLine
        out.close

        List acDirections := ["import", "export", "net"]
        specDocMap.each |specDocLine, specName| {
            acDirections.each |direction| {
                addAcDirectionSpec(specName, specDocLine, direction)
            }
        }
    }


    Void addAcDirectionSpec(Str specName, Str specDocLine, Str direction)
    {
        out := this.file.out(true)

        z := " of "
        if (specDocLine.contains("power factor")) {
            z = " "
        }

        // acIndex := 0

        acIndex := specDocLine.index("AC ")
        if (specDocLine.contains("maximum")) {
            acIndex = specDocLine.index("maximum ")
        }

        newDocLine := specDocLine[0..(acIndex-1)] + direction + z
                        + specDocLine[acIndex..-1]

        newSpecName := specName[0..3] + direction.capitalize + specName[4..-1]

        // print lines to file
        out.printLine(newDocLine)
        out.printLine("$newSpecName : $specName { $direction }")
        out.printLine
        out.close
    }


    Str getAcLocDocs(PointKind pointKind, PrimaryQuantity primaryQuantity,
                     Str subtype, Str loc) {

        locDisplayName := loc.replace("Avg", " average")
                             .replace("-", " to ")
                             .replace("L1", "line 1")
                             .replace("L2", "line 2")
                             .replace("L3", "line 3")
                             .replace("N", "neutral")

        // only on current, power, and demand setpoints apply "max"
        applyMaxDis := applyMaxDis(pointKind, primaryQuantity)

        // define the spec docs
        doc := "// " + findPointKindDis(pointKind) + " for "
                    + locDisplayName + " " + applyMaxDis + "AC electric "

        // power factor specs do not have subtypes
        if (primaryQuantity == PrimaryQuantity.pf) {
            doc += findPrimaryQuantityDis(primaryQuantity)
        }
        else {
            doc += findSubtypeDis(subtype) + " "
                    + findPrimaryQuantityDis(primaryQuantity)
        }

        return doc
    }


    Bool hasDirection(PrimaryQuantity primaryQuantity) {

        return (primaryQuantity == PrimaryQuantity.power ||
                primaryQuantity == PrimaryQuantity.energy ||
                primaryQuantity == PrimaryQuantity.pf ||
                primaryQuantity == PrimaryQuantity.demand)
    }


    Str findLineConfig(Str locTypeDis, PrimaryQuantity primaryQuantity) {

        config := ""

        if (primaryQuantity == PrimaryQuantity.current) {
            if (locTypeDis == "phase") { config = "ElecLineToLine" }
            else if (locTypeDis == "line") { config = "ElecLine" }
        }

        else if (primaryQuantity == PrimaryQuantity.volt) {
            if (locTypeDis == "phase") { config = "ElecLineToNeutral" }
            else if (locTypeDis == "line") { config = "ElecLineToLine" }
        }

        else {
            if (locTypeDis == "phase") { config = "ElecLine" }
            else if (locTypeDis == "line") { config = "ElecLineToLine" }
        }

        return config
    }


    Str makeSeparator() {
        return "///////////////////////////////////////////////"
                        + "///////////////////////////"
    }


    List findAcPhaseLocs(PrimaryQuantity primaryQuantity, LocKind locKind) {

        List acLineLocs := ["L1", "L2", "L3"]
        List acLineToLineLocs := ["L1-L2", "L2-L3", "L3-L1"]

        if (primaryQuantity == PrimaryQuantity.volt) {
            acLineLocs = ["L1-N", "L2-N", "L3-N"]
        }

        List output := [,]

        if (primaryQuantity == PrimaryQuantity.current) {
            if (locKind.name.contains("phase")) {
                output = acLineToLineLocs
            }
            else {
                output = acLineLocs
            }
        }
        else if ((primaryQuantity == PrimaryQuantity.volt) ||
              (primaryQuantity == PrimaryQuantity.power) ||
              (primaryQuantity == PrimaryQuantity.energy) ||
              (primaryQuantity == PrimaryQuantity.pf)
              ) {
            if (locKind.name.contains("line")) {
                output = acLineToLineLocs
            }
            else {
                output = acLineLocs
            }
        }

        return output
    }


    Str findSubtypeDis(Str subtype) {
        x := ""
        if (subtype == "thd") { x = "THD" }
        else { x = subtype }
        return x
    }


    Str findPointKindDis(PointKind pointKind) {
        pointKindDis := ""
        if (pointKind == PointKind.sensor)  { pointKindDis = "Sensor" }
        else if (pointKind == PointKind.sp) { pointKindDis = "Setpoint" }
        return pointKindDis
    }


    Str findPrimaryQuantityDis(PrimaryQuantity primaryQuantity) {

        primaryQuantityDis := primaryQuantity.name
        if (primaryQuantityDis == "volt")      { primaryQuantityDis = "voltage" }
        else if (primaryQuantityDis == "pf")   { primaryQuantityDis = "power factor" }
        else if (primaryQuantityDis == "freq") { primaryQuantityDis = "frequency" }

        return primaryQuantityDis
    }
}
