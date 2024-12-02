<?xml version="1.0" encoding="utf-8"?>
<?AutomationStudio FileVersion="4.9"?>
<SwConfiguration CpuAddress="SL1" xmlns="http://br-automation.co.at/AS/SwConfiguration">
  <TaskClass Name="Cyclic#1">
    <Task Name="VibratorCo" Source="modules.main.vibrator.VibratorControl.prg" Memory="UserROM" Language="IEC" Debugging="true" />
  </TaskClass>
  <TaskClass Name="Cyclic#2">
    <Task Name="sineWaveGe" Source="modules.main.vibrator.sineWaveGen.prg" Memory="UserROM" Language="IEC" Debugging="true" Disabled="true" />
    <Task Name="belt" Source="modules.main.belt.belt.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="sampling" Source="modules.sampling.prg" Memory="UserROM" Language="IEC" Debugging="true" />
  </TaskClass>
  <TaskClass Name="Cyclic#3">
    <Task Name="main" Source="modules.main.main.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="feeder" Source="modules.feeder.feeder.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="vibrator" Source="modules.main.vibrator.vibrator.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="EM_vibrat" Source="modules.main.vibrator.EM_Vibrator.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="capcon" Source="modules.main.capcon.capcon.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="wing" Source="modules.main.wing.wing.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="upperFlap" Source="modules.main.wing.upperFlap.upperFlap.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="middleFlap" Source="modules.main.wing.middleFlap.middleFlap.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="bottomFlap" Source="modules.main.wing.bottomFlap.bottomFlap.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="cassette" Source="modules.main.wing.cassette.cassette.prg" Memory="UserROM" Language="IEC" Debugging="true" />
  </TaskClass>
  <TaskClass Name="Cyclic#4">
    <Task Name="ethIp" Source="services.EthernetIP.ethIp.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="udpClient" Source="services.machine.udpClient.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="simulation" Source="simulation.simulation.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="lampCtrl" Source="services.machine.lampCtrl.prg" Memory="UserROM" Language="IEC" Debugging="true" Disabled="true" />
  </TaskClass>
  <TaskClass Name="Cyclic#5">
    <Task Name="alarm" Source="services.alarm.alarm.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="file" Source="services.file.file.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="recipe" Source="services.recipe.recipe.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="recipeCurr" Source="services.recipe.recipeCurrent.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="machine" Source="services.machine.machine.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="config" Source="services.config.config.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="updateCM" Source="services.machine.updateCM.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="updateEWU" Source="services.machine.updateEWU.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="elementImg" Source="services.elementImg.elementImg.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="simCapcon" Source="simulation.capcon.simCapcon.prg" Memory="UserROM" Language="IEC" Debugging="true" Disabled="true" />
    <Task Name="recipeCtrl" Source="services.recipeCtrl.recipeCtrl.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="transferCo" Source="services.machine.transferConfigToT50.prg" Memory="UserROM" Language="IEC" Debugging="true" />
    <Task Name="FAT" Source="services.FAT.FAT.prg" Memory="UserROM" Language="IEC" Debugging="true" />
  </TaskClass>
  <DataObjects>
    <DataObject Name="eipconf" Source="services.EthernetIP.eipconf.dob" Memory="UserROM" Language="Simple" />
    <DataObject Name="Acp10sys" Source="" Memory="UserROM" Language="Binary" />
  </DataObjects>
  <NcDataObjects>
    <NcDataObject Name="acp10etxen" Source="acp10etxen.dob" Memory="UserROM" Language="Ett" />
    <NcDataObject Name="gAxisVibCi" Source="gAxisVibCobj.gAxisVibCi.dob" Memory="UserROM" Language="Ax" />
    <NcDataObject Name="cfCurCtr" Source="gAxisVibCobj.cfCurCtr.dob" Memory="UserROM" Language="Apt" />
    <NcDataObject Name="gAxisVibLi" Source="gAxisVibLobj.gAxisVibLi.dob" Memory="UserROM" Language="Ax" />
    <NcDataObject Name="lfCurCtr" Source="gAxisVibLobj.lfCurCtr.dob" Memory="UserROM" Language="Apt" />
    <NcDataObject Name="gAxisBelta" Source="gAxisBeltobj.gAxisBelta.dob" Memory="UserROM" Language="Apt" />
    <NcDataObject Name="gAxisBelti" Source="gAxisBeltobj.gAxisBelti.dob" Memory="UserROM" Language="Ax" />
    <NcDataObject Name="lfNew" Source="gAxisVibLobj.lfNew.dob" Memory="UserROM" Language="Apt" />
  </NcDataObjects>
  <Binaries>
    <BinaryObject Name="mvLoader" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="udbdef" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="FWRules" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="TCData" Source="" Memory="SystemROM" Language="Binary" />
    <BinaryObject Name="TCLang" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="OpcUaSrv" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="arsvcreg" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="acp10cfg" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="Acp10map" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="arconfig" Source="" Memory="SystemROM" Language="Binary" />
    <BinaryObject Name="User" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="iomap" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="asfw" Source="" Memory="SystemROM" Language="Binary" />
    <BinaryObject Name="ashwac" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="ashwd" Source="" Memory="SystemROM" Language="Binary" />
    <BinaryObject Name="sysconf" Source="" Memory="SystemROM" Language="Binary" />
    <BinaryObject Name="Role" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="mp_recipe" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="mp_recipeC" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="asiol1" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="User_1" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="mp_config" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="mp_data" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="alarm_hist" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="TC" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="mp_user" Source="" Memory="UserROM" Language="Binary" />
    <BinaryObject Name="mp_alarm" Source="" Memory="UserROM" Language="Binary" />
  </Binaries>
  <Libraries>
    <LibraryObject Name="Acp10man" Source="Libraries.Acp10man.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="Acp10par" Source="Libraries.Acp10par.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="NcGlobal" Source="Libraries.NcGlobal.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="VibCtrl" Source="modules.main.vibrator.VibCtrl.lby" Memory="UserROM" Language="IEC" Debugging="true" />
    <LibraryObject Name="LookupTbl" Source="modules.main.vibrator.LookupTbl.lby" Memory="UserROM" Language="IEC" Debugging="true" />
    <LibraryObject Name="MpRecipe" Source="Libraries.MpRecipe.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="MpBase" Source="Libraries.MpBase.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="sys_lib" Source="Libraries.sys_lib.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="runtime" Source="Libraries.runtime.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="MpAlarmX" Source="Libraries.MpAlarmX.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="astime" Source="Libraries.astime.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="brdkMC" Source="Libraries.brdkMC.lby" Memory="UserROM" Language="IEC" Debugging="true" />
    <LibraryObject Name="Acp10_MC" Source="Libraries.Acp10_MC.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="AsBrMath" Source="Libraries.AsBrMath.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="standard" Source="Libraries.standard.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="AsBrStr" Source="Libraries.AsBrStr.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="brsystem" Source="Libraries.brsystem.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="brdkMU" Source="Libraries.brdkMU.lby" Memory="UserROM" Language="ANSIC" Debugging="true" />
    <LibraryObject Name="brdkSIM" Source="Libraries.brdkSIM.lby" Memory="UserROM" Language="ANSIC" Debugging="true" />
    <LibraryObject Name="brdkCSV" Source="Libraries.brdkCSV.lby" Memory="UserROM" Language="ANSIC" Debugging="true" />
    <LibraryObject Name="brdkPV" Source="Libraries.brdkPV.lby" Memory="UserROM" Language="ANSIC" Debugging="true" />
    <LibraryObject Name="legoCM20" Source="Libraries.legoCM20.lby" Memory="UserROM" Language="IEC" Debugging="true" />
    <LibraryObject Name="legoSTR" Source="Libraries.legoSTR.lby" Memory="UserROM" Language="ANSIC" Debugging="true" />
    <LibraryObject Name="DataObj" Source="Libraries.DataObj.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="brdkOPCUA" Source="Libraries.brdkOPCUA.lby" Memory="UserROM" Language="ANSIC" Debugging="true" />
    <LibraryObject Name="AsOpcUas" Source="Libraries.AsOpcUas.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="brdkUpdate" Source="Libraries.brdkUpdate.lby" Memory="UserROM" Language="ANSIC" Debugging="true" />
    <LibraryObject Name="ArProject" Source="Libraries.ArProject.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="brdkFile" Source="Libraries.brdkFile.lby" Memory="UserROM" Language="ANSIC" Debugging="true" />
    <LibraryObject Name="AsSem" Source="Libraries.AsSem.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="AsIO" Source="Libraries.AsIO.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="AsOpcUac" Source="Libraries.AsOpcUac.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="FileIO" Source="Libraries.FileIO.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="AsIODiag" Source="Libraries.AsIODiag.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="AsUSB" Source="Libraries.AsUSB.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="brdkREST" Source="Libraries.brdkREST.lby" Memory="UserROM" Language="ANSIC" Debugging="true" />
    <LibraryObject Name="brdkJSON" Source="Libraries.brdkJSON.lby" Memory="UserROM" Language="ANSIC" Debugging="true" />
    <LibraryObject Name="brdkSTR" Source="Libraries.brdkSTR.lby" Memory="UserROM" Language="ANSIC" Debugging="true" />
    <LibraryObject Name="RandomLib" Source="Libraries.RandomLib.lby" Memory="UserROM" Language="ANSIC" Debugging="true" />
    <LibraryObject Name="AsHttp" Source="Libraries.AsHttp.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="AsARCfg" Source="Libraries.AsARCfg.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="AsMath" Source="Libraries.AsMath.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="asstring" Source="Libraries.asstring.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="AsEthIP" Source="Libraries.AsEthIP.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="MTFilter" Source="Libraries.MTFilter.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="MTTypes" Source="Libraries.MTTypes.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="MTBasics" Source="Libraries.MTBasics.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="MTLookUp" Source="Libraries.MTLookUp.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="MTData" Source="Libraries.MTData.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="MpData" Source="Libraries.MpData.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="MpServer" Source="Libraries.MpServer.lby" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="Goertzel" Source="Libraries.Goertzel.lby" Memory="UserROM" Language="IEC" Debugging="true" />
    <LibraryObject Name="EasyUaClnt" Source="Libraries.EasyUaClnt.lby" Memory="UserROM" Language="IEC" Debugging="true" />
    <LibraryObject Name="AsIOLink" Source="Libraries.AsIOLink.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="AsIOAcc" Source="Libraries.AsIOAcc.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="AsUDP" Source="Libraries.AsUDP.lby" Memory="UserROM" Language="binary" Debugging="true" />
    <LibraryObject Name="powerlnk" Source="" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="arssl" Source="" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="asieccon" Source="" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="aruser" Source="" Memory="UserROM" Language="Binary" Debugging="true" />
    <LibraryObject Name="MpReport" Source="Libraries.MpReport.lby" Memory="UserROM" Language="Binary" Debugging="true" />
  </Libraries>
</SwConfiguration>