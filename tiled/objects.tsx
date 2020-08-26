<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.2" tiledversion="1.2.5" name="objects" tilewidth="16" tileheight="16" tilecount="8" columns="0">
 <grid orientation="orthogonal" width="1" height="1"/>
 <tile id="0">
  <properties>
   <property name="path" value="res://entities/enemies/stalfos/stalfos.tscn"/>
  </properties>
  <image width="16" height="16" source="images/objects/stalfos.png"/>
 </tile>
 <tile id="1">
  <properties>
   <property name="entrance" value=""/>
   <property name="map" value=""/>
   <property name="path" value="res://tiles/exit.tscn"/>
   <property name="player_position" value=""/>
  </properties>
  <image width="16" height="16" source="images/objects/exit.png"/>
 </tile>
 <tile id="2">
  <properties>
   <property name="path" value="res://tiles/block.tscn"/>
  </properties>
  <image width="16" height="16" source="images/objects/block.png"/>
 </tile>
 <tile id="3">
  <properties>
   <property name="path" value="res://tiles/decor/flower_white.tscn"/>
  </properties>
  <image width="16" height="16" source="images/objects/flower_white.png"/>
 </tile>
 <tile id="4">
  <properties>
   <property name="path" value="res://tiles/decor/flower_blue.tscn"/>
  </properties>
  <image width="16" height="16" source="images/objects/flower_blue.png"/>
 </tile>
 <tile id="5">
  <properties>
   <property name="color" value="green"/>
   <property name="path" value="res://entities/enemies/slime/slime.tscn"/>
  </properties>
  <image width="16" height="16" source="images/objects/greenslime.png"/>
 </tile>
 <tile id="6">
  <properties>
   <property name="color" value="red"/>
   <property name="path" value="res://entities/enemies/slime/slime.tscn"/>
  </properties>
  <image width="16" height="16" source="images/objects/redslime.png"/>
 </tile>
 <tile id="7">
  <image width="16" height="16" source="images/objects/blueslime.png"/>
 </tile>
</tileset>
