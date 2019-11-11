<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.2" tiledversion="1.2.5" name="objects" tilewidth="16" tileheight="16" tilecount="6" columns="0">
 <grid orientation="orthogonal" width="1" height="1"/>
 <tile id="1">
  <properties>
   <property name="path" value="res://enemies/stalfos.tscn"/>
  </properties>
  <image width="16" height="16" source="images/objects/stalfos.png"/>
 </tile>
 <tile id="2">
  <properties>
   <property name="path" value="res://enemies/knawblin.tscn"/>
  </properties>
  <image width="16" height="16" source="images/objects/knawblin.png"/>
 </tile>
 <tile id="3">
  <properties>
   <property name="path" value="res://tiles/sign.tscn"/>
   <property name="text" value="I AM ERROR."/>
  </properties>
  <image width="16" height="16" source="images/objects/sign.png"/>
 </tile>
 <tile id="4">
  <properties>
   <property name="path" value="res://tiles/switch/weapon_switch.tscn"/>
  </properties>
  <image width="16" height="16" source="images/objects/weapon_switch.png"/>
 </tile>
 <tile id="5">
  <properties>
   <property name="path" value="res://tiles/switch/pressure_plate.tscn"/>
  </properties>
  <image width="16" height="16" source="images/objects/pressure_plate.png"/>
 </tile>
 <tile id="6">
  <properties>
   <property name="patchdirection" value=""/>
   <property name="path" value="res://tiles/blastable_wall.tscn"/>
  </properties>
  <image width="16" height="16" source="../tiles/cracked.png"/>
 </tile>
</tileset>
