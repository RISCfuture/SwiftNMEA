#defineAlarms([
  (
    name: "steeringGear", id: "SG",
    subsystems: [
      (
        name: "powerUnit", id: "PU",
        codes: [
          "stop": 1,
          "powerFail": 2,
          "overload": 3,
          "phaseFail": 4,
          "hydFluidLo": 5,
          "run": 10
        ]
      ),
      (
        name: "control", id: "CL",
        codes: [
          "powerFail": 1
        ]
      )
    ]
  ),
  (
    name: "propulsionControl", id: "PC",
    subsystems: [
      (
        name: "propulsionControl", id: "PC",
        codes: [
          "startInhibit": 1,
          "autoShutdown": 2,
          "autoSlowdown": 3,
          "safetyOverride": 4,
          "barredSpeedRange": 5,
          "feederPowerFail": 6,
          "CPPOilPress": 7,
          "CPPOilTemp": 8,
          "systemPowerFail": 9
        ]
      ),
      (
        name: "remoteControl", id: "RC",
        codes: [
          "powerFail": 1,
          "systemAbnormal": 2,
          "governorControlAbnormal": 3,
          "propPitchAbnormal": 4
        ]
      ),
      (
        name: "monitoring", id: "MN",
        codes: [
          "powerSourceFail": 1,
          "individualPowerSupplyFail": 2,
          "dataHiwayAbnormal": 3,
          "duplicatedDatalinkFail": 4
        ]
      ),
      (
        name: "groupAlarm", id: "AL",
        codes: [
          "powerFail": 1,
          "personnelAlarm": 2,
          "deadManAlarm": 3,
          "requestBackupOOW": 4
        ]
      ),
      (
        name: "systemPowerSource", id: "SP",
        codes: [
          "mainFeederFail": 1,
          "emerFeederFail": 2
        ]
      ),
      (name: "others", id: "OT", codes: [:])
    ]
  ),
  (
    name: "auxiliaryMachinery", id: "AM",
    subsystems: [
      (
        name: "electricPowerGenerator", id: "EP",
        codes: [
          "voltageAbnormal": 1,
          "currentHi": 2,
          "freqAbnrmal": 3,
          "onlineGenFail": 4,
          "bearingLubOilInletPressLo": 5,
          "genCoolingInletPumpOrFanMotorFail": 6,
          "genCoolantTempHi": 7
        ]
      ),
      (
        name: "highVoltageRotatingMachine", id: "RM",
        codes: [
          "stationaryWindingsTempHi": 1
        ]
      ),
      (
        name: "fuelOil", id: "FO",
        codes: [
          "settingServiceTankLevelAbnormal": 1,
          "oveflowDrainTankLevelAbnormal": 2
        ]
      ),
      (
        name: "sternTubeLubOil", id: "ST",
        codes: [
          "levelLo": 1
        ]
      ),
      (
        name: "boiler", id: "BL",
        codes: [
          "autoShutdown": 1
        ]
      ),
      (
        name: "propulsionMachinerySpace", id: "MS",
        codes: [
          "bilgeLevelHi": 1,
          "acFail": 2,
          "fire": 3
        ]
      ),
      (name: "others", id: "OT", codes: [:])
    ]
  ),
  (
    name: "dieselPlant", id: "DE",
    subsystems: [
      (
        name: "fuelOil", id: "FO",
        codes: [
          "tankTempHi": 1,
          "engineInletPressLo": 2,
          "preInjunctionPumpTempAbnormal": 3,
          "highPressPipeLeak": 4
        ]
      ),
      (
        name: "lubricatingOil", id: "LO",
        codes: [
          "mainBearingPressLo": 1,
          "thrustBearingPressLo": 2,
          "crossheadBearingPressLo": 3,
          "camshaftPressLo": 4,
          "camshaftTempHi": 5,
          "inletTempHi": 6,
          "thrustBearingPadsTempHi": 7,
          "mainCrankCrossheadOutletTempHi": 8,
          "cylinderLubFlowRateLo": 9,
          "tankLevelLo": 10
        ]
      ),
      (
        name: "turbocharger", id: "TC",
        codes: [
          "oilInletPressLo": 1,
          "oilOutletTempHi": 2
        ]
      ),
      (
        name: "pistonCooling", id: "PS",
        codes: [
          "inletPressLo": 1,
          "outletTempHi": 2,
          "outletFlowLo": 3,
          "expansionTankLevelLo": 4
        ]
      ),
      (
        name: "seawaterCooling", id: "SC",
        codes: [
          "pressLo": 1
        ]
      ),
      (
        name: "freshwaterCooling", id: "FW",
        codes: [
          "waterInletPressLo": 1,
          "waterOutletFromCylinderTempHi": 2,
          "oilContamination": 3,
          "expansionTankLevelLo": 4
        ]
      ),
      (
        name: "compressedAir", id: "CA",
        codes: [
          "startingAirPressLo": 1,
          "controlAirPressLo": 2,
          "safetyAirPressLo": 3
        ]
      ),
      (
        name: "scavengeAir", id: "SA",
        codes: [
          "boxTempHi": 1,
          "receiverWaterLevelHi": 2
        ]
      ),
      (
        name: "exhaustGas", id: "EH",
        codes: [
          "tempHi": 1,
          "tempDeviationHi": 2,
          "tempBeforeTurbochargerHi": 3,
          "tempAfterTurbochargerHi": 4
        ]
      ),
      (
        name: "fuelValveCoolant", id: "FV",
        codes: [
          "coolantPressLo": 1,
          "coolantTempHi": 2,
          "coolantExpansionTankLevelLo": 3
        ]
      ),
      (
        name: "engine", id: "EG",
        codes: [
          "incorrectRotation": 1,
          "overspeed": 2
        ]
      ),
      (
        name: "others", id: "OT",
        codes: [
          "reductionGearLubOilInletPressLo": 1
        ]
      )
    ]
  ),
  (
    name: "steamTurbinePlant", id: "ST",
    subsystems: [
      (
        name: "lubricationOil", id: "LO",
        codes: [
          "bearingInletPressAbnormal": 1,
          "bearingOutletTempHi": 2,
          "filterDiffPressHi": 3,
          "gravityTankLevelLo": 4
        ]
      ),
      (
        name: "lubricatingOilCooling", id: "LC",
        codes: [
          "pressLo": 1,
          "outletTempHi": 2,
          "expansionTankLevelLo": 3
        ]
      ),
      (
        name: "seawater", id: "SW",
        codes: [
          "pressLo": 1
        ]
      ),
      (
        name: "steam", id: "SM",
        codes: [
          "throttlePressLo": 1,
          "glandSealExhaustFanFail": 2,
          "asternGuardianValveOpeningFail": 3
        ]
      ),
      (
        name: "condensate", id: "CD",
        codes: [
          "condenserLevelAbnormal": 1,
          "pumpPressLo": 2,
          "vacuumLo": 3,
          "salinityHi": 4
        ]
      ),
      (
        name: "rotor", id: "RT",
        codes: [
          "vibrationHi": 1,
          "axialDisplacementLarge": 2,
          "overspeed": 3,
          "shaftStopped": 4
        ]
      ),
      (
        name: "power", id: "PW",
        codes: [
          "throttleControlSystemPowerFail": 1
        ]
      ),
      (name: "others", id: "OT", codes: [:])
    ]
  ),
  (
    name: "gasTurbinePlant", id: "GT",
    subsystems: [
      (
        name: "fuelOil", id: "FO",
        codes: [
          "pressLo": 1,
          "tempAbnormal": 2
        ]
      ),
      (
        name: "lubricatingOil", id: "LO",
        codes: [
          "inletPressLo": 1,
          "inletTempHi": 2,
          "mainBearingOutletTempHi": 3,
          "filterDiffPressHi": 4,
          "tankLevelLo": 5
        ]
      ),
      (
        name: "coolingMedium", id: "CM",
        codes: [
          "pressLo": 1,
          "tempHi": 2
        ]
      ),
      (
        name: "starting", id: "SA",
        codes: [
          "storedEnergyLo": 1,
          "autoStartingFail": 2
        ]
      ),
      (
        name: "combustion", id: "CB",
        codes: [
          "flameFail": 1
        ]
      ),
      (
        name: "exhaustGas", id: "EH",
        codes: [
          "tempHi": 1
        ]
      ),
      (
        name: "turbine", id: "TB",
        codes: [
          "vibrationHi": 1,
          "rotorAxialDisplacementLarge": 2,
          "overspeed": 3,
          "compressorInletVacuumHi": 4
        ]
      ),
      (name: "others", id: "OT", codes: [:])
    ]
  ),
  (
    name: "electricPlant", id: "EP",
    subsystems: [
      (
        name: "propulsionGenerator", id: "PG",
        codes: [
          "bearingLubOilInletPressLo": 1,
          "voltageOffLimit": 2,
          "freqOffLimit": 3,
          "stationaryWindingsTempHi": 4,
          "onlineGenFail": 5,
          "standbyGenTransferFail": 6,
          "coolingTempHi": 7,
          "coolingPumpFail": 8,
          "interpoleWindingsTempHi": 9
        ]
      ),
      (
        name: "ACPropulsionMotor", id: "PA",
        codes: [
          "bearingLubOilInletPressLo": 1,
          "armatureVoltageOffLimit": 2,
          "freqOffLimit": 3,
          "stationaryWindingsTempHi": 4,
          "onlineGenFail": 5,
          "standbyGenTransferFail": 6,
          "coolingTempHi": 7,
          "coolingPumpFail": 8
        ]
      ),
      (
        name: "DCPropulsionMotor", id: "PD",
        codes: [
          "bearingLubOilInletPressLo": 1,
          "armatureVoltageOffLimit": 2,
          "freqOffLimit": 3,
          "stationaryWindingsTempHi": 4,
          "onlineGenFail": 5,
          "standbyGenTransferFail": 6,
          "coolingTempHi": 7,
          "coolingPumpFail": 8
        ]
      ),
      (
        name: "propulsionSCR", id: "PS",
        codes: [
          "overload": 1,
          "coolingTempHi": 2,
          "coolingPumpFail": 3
        ]
      ),
      (
        name: "transformer", id: "TF",
        codes: [
          "windingTempHi": 1
        ]
      ),
      (name: "others", id: "OT", codes: [:])
    ]
  ),
  (
    name: "propulsionBoiler", id: "PB",
    subsystems: [
      (
        name: "feedWater", id: "FW",
        codes: [
          "atmosphericDrainTankLevelAbnormal": 1,
          "deaeratorLevelAbnormal": 2,
          "deaeratorPressAbnormal": 3,
          "pumpPressLo": 4,
          "tempHi": 5,
          "outletSalinityHi": 6
        ]
      ),
      (
        name: "boilerDrum", id: "BD",
        codes: [
          "waterLevelAbnormal": 1,
          "waterLevelLoLo": 2
        ]
      ),
      (
        name: "steam", id: "SM",
        codes: [
          "pressAbnormal": 1,
          "superheaterOutletTempHi": 2
        ]
      ),
      (
        name: "air", id: "AR",
        codes: [
          "forcedDraftFanFail": 1,
          "rotatingAirHeaterMotorFail": 2,
          "boilerCasingFire": 3
        ]
      ),
      (
        name: "fuelOil", id: "FO",
        codes: [
          "outletPumpPressLo": 1,
          "tempAbnormal": 2
        ]
      ),
      (
        name: "burner", id: "BN",
        codes: [
          "atomizingMediumPressOffLimit": 1,
          "flameFail": 2,
          "flameSensorFail": 3,
          "uptakeGasTempHi": 4
        ]
      ),
      (
        name: "power", id: "PW",
        codes: [
          "controlSystemPowerFail": 1
        ]
      ),
      (name: "others", id: "OT", codes: [:])
    ]
  ),
  (
    name: "auxiliaryBoiler", id: "AB",
    subsystems: [
      (
        name: "feedWater", id: "FW",
        codes: [
          "outletSalinityHi": 1
        ]
      ),
      (
        name: "boilerDrum", id: "PD",
        codes: [
          "waterLevelAbnormal": 1
        ]
      ),
      (
        name: "steam", id: "SM",
        codes: [
          "pressAbnormal": 1,
          "superheaterOutletTempHi": 2
        ]
      ),
      (
        name: "air", id: "AR",
        codes: [
          "supplyAirPressFail": 1,
          "boilerCasingFire": 2
        ]
      ),
      (
        name: "fuelOil", id: "FO",
        codes: [
          "outletPumpPress": 1,
          "tempAbnormal": 2
        ]
      ),
      (
        name: "burner", id: "BN",
        codes: [
          "flameFail": 1,
          "flameSensorFail": 2,
          "uptakeGasTempHi": 3
        ]
      ),
      (
        name: "power", id: "PW",
        codes: [
          "controlSystemPowerFail": 1
        ]
      ),
      (name: "others", id: "OT", codes: [:])
    ]
  ),
  (
    name: "auxiliaryDiesel", id: "AD",
    subsystems: [
      (
        name: "fuelOil", id: "FO",
        codes: [
          "injunctionPipeLeakage": 1,
          "tempAbnormal": 2,
          "serviceTankLevelLo": 3
        ]
      ),
      (
        name: "lubricatingOil", id: "LO",
        codes: [
          "bearingOilInletPressLo": 1,
          "bearingOilInletTempHi": 2,
          "crankcaseOilMistConcentrationHi": 3
        ]
      ),
      (
        name: "coolingMedium", id: "CM",
        codes: [
          "pressLo": 1,
          "tempHi": 2,
          "expansionTankLevelLo": 3
        ]
      ),
      (
        name: "startingMedium", id: "ST",
        codes: [
          "energyLo": 1
        ]
      ),
      (
        name: "exhaustGas", id: "EH",
        codes: [
          "tempHi": 1
        ]
      ),
      (
        name: "engine", id: "EG",
        codes: [
          "overspeed": 1
        ]
      ),
      (name: "others", id: "OT", codes: [:])
    ]
  ),
  (
    name: "auxiliaryTurbine", id: "AT",
    subsystems: [
      (
        name: "lubricationOil", id: "LO",
        codes: [
          "bearingInletPressLo": 1,
          "bearingInletTempHi": 2,
          "bearingOutletTempHi": 3
        ]
      ),
      (
        name: "lubricatingOilCooling", id: "LC",
        codes: [
          "pressLo": 1,
          "outletTempHi": 2,
          "expansionTankLevelLo": 3
        ]
      ),
      (
        name: "seawater", id: "SW",
        codes: [
          "pressLo": 1
        ]
      ),
      (
        name: "steam", id: "ST",
        codes: [
          "inletPressLo": 1
        ]
      ),
      (
        name: "condensate", id: "CO",
        codes: [
          "pumpPressLo": 1,
          "vacuumLo": 2
        ]
      ),
      (
        name: "rotor", id: "RT",
        codes: [
          "axialDisplacementLarge": 1,
          "overspeed": 2
        ]
      ),
      (name: "others", id: "OT", codes: [:])
    ]
  ),
  (
    name: "auxiliaryGasTurbine", id: "AG",
    subsystems: [
      (
        name: "fuelOil", id: "FO",
        codes: [
          "pressLo": 1,
          "tempAbnormal": 2
        ]
      ),
      (
        name: "lubricatingOil", id: "LO",
        codes: [
          "inletPressLo": 1,
          "inletTempHi": 2,
          "bearingOilOutletTempHi": 3,
          "filterDiffPressHi": 4
        ]
      ),
      (
        name: "coolingMedium", id: "CM",
        codes: [
          "pressLo": 1,
          "tempHi": 2
        ]
      ),
      (
        name: "starting", id: "SA",
        codes: [
          "storedEnergyLo": 1,
          "ignitionFail": 2
        ]
      ),
      (
        name: "combustion", id: "CN",
        codes: [
          "flameFail": 1
        ]
      ),
      (
        name: "exhaustGas", id: "EH",
        codes: [
          "tempHi": 1
        ]
      ),
      (
        name: "rotor", id: "RT",
        codes: [
          "vibrationHi": 1,
          "axialDisplacementLarge": 2,
          "overspeed": 3,
          "compressorInletVacuumHi": 4
        ]
      ),
      (name: "others", id: "OT", codes: [:])
    ]
  ),
  (
    name: "cargoControlPlant", id: "CG",
    subsystems: [
      (
        name: "chemicalCargo", id: "CH",
        codes: [
          "cargoTempAbnormal": 1,
          "tankTempHi": 2,
          "voidSpaceOxyContentration": 3,
          "coolingSystemTempControlMalfunction": 4,
          "cargoTankMechanicalVentilationFail": 5,
          "inertedCargoTankTempLo": 6
        ]
      ),
      (
        name: "LPG_LNGCargo", id: "LG",
        codes: [
          "cargoTankTempAbnormal": 1,
          "gasDetection": 2,
          "hullInsulationTempHi": 3,
          "cargoPressHi": 4,
          "chlorineConcentration": 5,
          "chlorineCargoTankPressHi": 6,
          "liquidCargoVentilationSystemFail": 7,
          "cargoTankVacuumProtectionFail": 8,
          "inertGasPressHi": 9,
          "gasDetectionFail": 10,
          "chlorineBurstDiskGasDetectionFail": 11
        ]
      ),
      (
        name: "inertGas", id: "OL",
        codes: [
          "waterPressLo": 1,
          "scrubberWaterLevelHi": 2,
          "gasTempHi": 3,
          "IGBlowerFail": 4,
          "oxyContentVolumeHi": 5,
          "autoControlPowerSupplyFail": 6,
          "waterSealLevelLo": 7,
          "gasPressAbnormal": 8,
          "fuelOilSupplyLo": 9,
          "powerSupplyFail": 10
        ]
      )
    ]
  ),
  (
    name: "watertightDoorController", id: "WD",
    subsystems: [
      (
        name: "", id: "",
        codes: [
          "hydReservoirLevelLo": 1,
          "gasPressLo": 2,
          "electricPowerLoss": 3
        ]
      )
    ]
  ),
  (
    name: "hullDoorController", id: "HD",
    subsystems: [
      (
        name: "", id: "",
        codes: [
          "notSecured": 1,
          "powerFail": 2
        ]
      )
    ]
  ),
  (
    name: "fireDoorController", id: "FD",
    subsystems: [
      (
        name: "", id: "",
        codes: [
          "systemAbnormal": 1,
          "powerFail": 2
        ]
      )
    ]
  ),
  (
    name: "fireDetection", id: "FR",
    subsystems: [
      (
        name: "heatDetection", id: "HT",
        codes: [
          "systemFail": 1,
          "powerFail": 2
        ]
      ),
      (
        name: "smokeDetection", id: "SM",
        codes: [
          "systemFail": 1,
          "powerFail": 2
        ]
      ),
      (name: "others", id: "OT", codes: [:])
    ]
  ),
  (
    name: "other", id: "OT",
    subsystems: [
      (name: "", id: "", codes: [:])
    ]
  )
])

/// Situations that result in the creation of an alarm state.
///
/// - SeeAlso: ``Message/Payload-swift.enum/detailAlarm(time:alarm:instance:condition:acknowledgementState:description:)``
public enum AlarmCondition: Character, Sendable, Codable, Equatable {
  case normal = "N"
  case high = "H"
  case extremeHigh = "J"
  case low = "L"
  case extremeLow = "K"
  case other = "X"
}

/// Whether an alarm was acknowledged and how.
///
/// - SeeAlso: ``Message/Payload-swift.enum/detailAlarm(time:alarm:instance:condition:acknowledgementState:description:)``
public enum AlarmAcknowledgementState: Character, Sendable, Codable, Equatable {
  case acknowledged = "A"
  case notAcknowledged = "V"
  case broadcast = "B"
  case harborMode = "H"
  case override = "O"
}
