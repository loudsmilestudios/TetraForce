<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.2" tiledversion="1.2.1" name="objects" tilewidth="16" tileheight="16" tilecount="13" columns="0">
 <grid orientation="orthogonal" width="1" height="1"/>
 <tile id="0">
  <properties>
   <property name="path" value="res://entities/enemies/stalfos/stalfos.tscn"/>
  </properties>
  <image width="16" height="16" source="images/objects/stalfos.png"/>
 </tile>
 <tile id="1">
  <properties>
   <property name="collider_height" type="float" value="1"/>
   <property name="collider_width" type="float" value="1"/>
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
 <tile id="8">
  <image width="16" height="16" source="images/objects/bombable_rock.png"/>
 </tile>
 <tile id="9">
  <properties>
   <property name="path" value="res://tiles/cliff.tscn"/>
  </properties>
  <image width="16" height="16" source="images/objects/cliff.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="0" y="4" width="16" height="12"/>
  </objectgroup>
 </tile>
 <tile id="10">
  <properties>
   <property name="def" value="weapon_def"/>
   <property name="item" value="Bow"/>
   <property name="path" value="res://tiles/chest.tscn"/>
  </properties>
  <image width="16" height="16" source="images/objects/chest.png"/>
 </tile>
 <tile id="11">
  <properties>
   <property name="dialogue" value="npc"/>
   <property name="direction" value="Down"/>
   <property name="path" value="res://entities/npcs/npc.tscn"/>
   <property name="texture" value="girl"/>
  </properties>
  <image width="16" height="16" source="images/objects/npc.png"/>
 </tile>
 <tile id="12">
  <properties>
   <property name="dialogue" value="dungeon_sign"/>
   <property name="path" value="res://tiles/sign.tscn"/>
  </properties>
  <image width="16" height="16" source="images/objects/sign.png"/>
 </tile>
</tileset>
