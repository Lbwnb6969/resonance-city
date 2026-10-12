"""Reproducible project-authored miniature buildings and trees for the live valley.

Geometry is authored in the retained 2:1 projection, ordered with the existing BSP,
then baked as transparent PNG plus editable SVG and physical cast/contact masks.
No downloaded assets, source overwrites, gameplay RNG or Blender runtime required.
"""
from pathlib import Path
import argparse
import hashlib
import itertools
import json
import math
import re
import xml.etree.ElementTree as ET

import numpy as np
from PIL import Image, ImageDraw

import build_classical_svg as b
from build_art_direction_foliage import ellipsoid, ring_volume, calibrate
from demo_lighting import face_normal, masks, shade_hex

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "资源/精制河湾"
WALL = ["#E4D3B1", "#BDAE92", "#F0E0BF"]
STONE = ["#D3C0A0", "#AF9E84", "#F1E3C7"]
WOOD = ["#88674D", "#604E40", "#AF8B64"]
OPENING = "#42483E"
LEAF = "#4D7960"
ROOFS = {
    "tile": ["#B97859", "#8D5747", "#D39170"],
    "deep": ["#597A83", "#3E5B66", "#79949A"],
    "warm": ["#728A72", "#536C5D", "#92A089"],
}


def block(out, center, size, palette=WALL):
    b.box(out, center, size, palette)
    # Complete rear and left faces are needed for genuine four-angle bakes.
    x,y,z=center;a,h,c=[v/2 for v in size]
    b.face(out,[(x-a,y-h,z-c),(x-a,y+h,z-c),(x+a,y+h,z-c),(x+a,y-h,z-c)],palette[0])
    b.face(out,[(x-a,y-h,z-c),(x-a,y-h,z+c),(x-a,y+h,z+c),(x-a,y+h,z-c)],palette[1])


def plane(out, x, y, z, width, height, color, side=False):
    vertices = [(x-width/2, y, z), (x+width/2, y, z),
                (x+width/2, y+height, z), (x-width/2, y+height, z)]
    if side:
        vertices = [(z, py, px) for px, py, _ in vertices]
    b.face(out, vertices, color)


def framed_window(out, x, bottom, front, width=.22, height=.28, side=False, arch=False):
    def edge(cx, cy, cz, sx, sy, sz, palette):
        block(out, (cz, cy, cx) if side else (cx, cy, cz),
              (sz, sy, sx) if side else (sx, sy, sz), palette)
    # Classical aperture: deep shaded opening, dressed-stone lintel/sill,
    # and opened timber shutters. No reflective glass or modern pane grid.
    edge(x, bottom+height/2, front+.008, width+.075, height+.065, .032, STONE)
    if arch:
        b.arch(out, x, bottom, front+.028, width, height, OPENING, side)
    else:
        plane(out, x, bottom, front+.028, width, height, OPENING, side)
    edge(x, bottom-.025, front+.038, width+.10, .044, .10, STONE)
    for sign in [-1,1]:
        edge(x+sign*(width/2+.024), bottom+height/2, front+.033, .049, height*.92, .024, WOOD)
        for slat in range(5):
            plane(out,x+sign*(width/2+.024),bottom+.032+slat*height*.16,front+.047,.043,.011,"#B29670",side)


def arched_door(out, x, bottom, z, width=.21, height=.39, side=False):
    b.arch(out, x, bottom-.006, z+.012, width+.09, height+.065, STONE[0], side)
    b.arch(out, x, bottom, z+.030, width, height, WOOD[1], side)
    # Individual voussoirs and planks remain geometric surfaces, not texture decals.
    spring = bottom+height-width/2
    for index in range(7):
        a, c = index*math.pi/7, (index+1)*math.pi/7-.018
        vertices = [(x+radius*math.cos(t), spring+radius*math.sin(t), z+.038)
                    for radius,t in [(width/2,a),(width/2,c),(width/2+.044,c),(width/2+.044,a)]]
        if side: vertices = [(pz,py,px) for px,py,pz in vertices]
        b.face(out, vertices, STONE[2] if index%2 else STONE[0])
    for offset in [-.29,-.08,.13,.34]:
        plane(out, x+width*offset, bottom+.018, z+.033, width*.19, height-width/2-.025, WOOD[0], side)
    plane(out, x+.04, bottom+.16, z+.040, .022, .013, "#D9B77C", side)


def reflected_details(out,source,axis):
    for _,vertices,color in source:
        points=[tuple(-value if i==axis else value for i,value in enumerate(p)) for p in vertices]
        b.face(out,points,color)


def rear_and_left_windows(out,width,length,bottom=.18,height=.23):
    rear=[];left=[]
    for x in [-width*.22,width*.22]: framed_window(rear,x,bottom,length/2+.006,.20,height)
    for z in [-length*.22,length*.22]: framed_window(left,z,bottom,width/2+.006,.20,height,True)
    reflected_details(out,rear,2)
    reflected_details(out,left,0)


def classical_column(out,x,z,bottom,top,radius=.040):
    block(out,(x,bottom+.026,z),(radius*3.0,.052,radius*3.0),STONE)
    rings=[]
    for y,r in [(bottom+.06,radius),(bottom+.25,radius*1.015),(top-.12,radius*.82)]:
        rings.append([(x+r*(1.0 if i%2==0 else .87)*math.cos(i*math.tau/20),y,
                       z+r*(1.0 if i%2==0 else .87)*math.sin(i*math.tau/20)) for i in range(20)])
    for lower,upper in zip(rings,rings[1:]):
        for i in range(20): b.face(out,[lower[i],lower[(i+1)%20],upper[(i+1)%20],upper[i]],STONE[0])
    capital=[]
    ring_volume(capital,[(top-.12,radius*.86,radius*.86),(top-.08,radius*.88,radius*.88),
                         (top-.036,radius*1.40,radius*1.40)],STONE[2],20)
    for _,vertices,tint in capital: b.face(out,[(vx+x,vy,vz+z) for vx,vy,vz in vertices],tint)
    block(out,(x,top-.018,z),(radius*3.25,.036,radius*3.25),STONE)


def steps(out, x=0, z=.59, width=.34, count=3, base=.018):
    for index in range(count):
        block(out, (x, base+.018+index*.025, z-index*.035),
              (width-.025*index, .036, .18-.035*index), STONE)


def masonry(out, width, length, bottom, height, cx=0, cz=0):
    # A sparse, staggered seam course and a few raised corner stones.
    for row in range(3):
        y = bottom+.10+row*.14
        plane(out, cx, y, cz+length/2+.004, width-.04, .005, "#C4B69B")
        plane(out, cz, y, cx+width/2+.004, length-.04, .005, "#A89982", True)
        for index in range(4):
            x = cx-width/2+.12+(index+row*.5)*.23
            if x < cx+width/2-.08: plane(out, x, y-.12, cz+length/2+.004, .005, .12, "#CCBDA1")
    for row in range(4):
        y = bottom+.07+row*.125
        for x in [cx-width/2+.045,cx+width/2-.045]:
            block(out, (x,y,cz+length/2+.014),(.085,.07,.045),STONE)


def cornice(out, width, length, y, cx=0, cz=0):
    block(out,(cx,y-.016,cz),(width,.026,length),["#A7957C"]*3)
    block(out,(cx,y+.009,cz),(width+.055,.034,length+.055),STONE)
    block(out,(cx,y+.033,cz),(width+.075,.014,length+.075),WALL)
    for x in np.linspace(cx-width*.40,cx+width*.40,5):
        block(out,(float(x),y-.05,cz+length/2+.007),(.027,.052,.042),STONE)


def tiled_roof(out, width, length, y, rise, palette, cx=0, cz=0):
    a,c = width/2,length/2
    b.face(out,[(cx-a,y,cz+c),(cx+a,y,cz+c),(cx,y+rise,cz+c)],WALL[0])
    b.face(out,[(cx-a,y,cz-c),(cx,y+rise,cz-c),(cx+a,y,cz-c)],WALL[0])
    for sign in [-1,1]:
        b.face(out,[(cx,y+rise,cz-c),(cx+sign*a,y,cz-c),
                    (cx+sign*a,y,cz+c),(cx,y+rise,cz+c)],palette[0 if sign<0 else 1])
        for row in range(5):
            inner,outer = row*a/5,(row+1)*a/5
            for tile in range(8):
                z0=cz-c+tile*length/8+.007
                z1=cz-c+(tile+1)*length/8-.007
                tint=palette[0 if (tile+row)%4 else 2]
                vertices=[(cx+sign*inner,y+rise*(1-inner/a)+.007,z0),
                          (cx+sign*outer,y+rise*(1-outer/a)+.011,z0),
                          (cx+sign*outer,y+rise*(1-outer/a)+.011,z1),
                          (cx+sign*inner,y+rise*(1-inner/a)+.007,z1)]
                b.face(out,vertices,tint)
                b.face(out,[vertices[1],vertices[2],(vertices[2][0],vertices[2][1]-.014,z1),
                            (vertices[1][0],vertices[1][1]-.014,z0)],palette[1])
    block(out,(cx,y+rise+.020,cz),(.055,.038,length+.025),palette)
    for index in range(8):
        block(out,(cx,y+rise+.042,cz-c+(index+.5)*length/8),(.065,.012,length/8-.013),palette)


def planter(out, x, z, y, width=.18):
    block(out,(x,y+.037,z),(width,.073,.13),ROOFS["tile"])
    block(out,(x,y+.080,z),(width+.018,.017,.147),STONE)
    ellipsoid(out,(x-.033,y+.11,z),(.062,.058,.055),LEAF,8,3)
    ellipsoid(out,(x+.030,y+.12,z),(.055,.068,.052),"#6D9270",8,3)


def house_shell(out,width=1.02,length=.90,height=.48):
    block(out,(0,.022,0),(width+.12,.044,length+.12),STONE)
    block(out,(0,.044+height/2,0),(width,height,length),WALL)
    block(out,(0,.089,0),(width+.023,.052,length+.023),STONE)
    masonry(out,width,length,.044,height)
    cornice(out,width+.04,length+.04,.044+height)


def terrace(palette):
    out=[]
    house_shell(out,height=.47)
    arched_door(out,-.26,.052,.456,.20,.34)
    framed_window(out,.24,.17,.456,.26,.23)
    for z in [-.21,.22]: framed_window(out,z,.17,.516,.21,.23,True)
    rear_and_left_windows(out,1.02,.90,.17,.23)
    steps(out,-.26,.54,.29)
    block(out,(0,.567,0),(1.15,.072,1.03),palette)
    # Recessed roof garden inside a real stone balustrade; a shaded pergola
    # and a small clerestory produce a different silhouette from the pitched roof.
    block(out,(0,.61,0),(.90,.026,.78),["#8FA0A0"]*3)
    for x in [-.54,.54]: block(out,(x,.655,0),(.055,.14,1.02),STONE)
    for z in [-.485,.485]: block(out,(0,.655,z),(1.02,.14,.055),STONE)
    for x in [-.50,.50]: block(out,(x,.739,0),(.09,.029,1.04),palette)
    for z in [-.49,.49]: block(out,(0,.739,z),(1.05,.029,.09),palette)
    for x in [-.26,.20]:
        for z in [-.22,.18]: block(out,(x,.73,z),(.030,.25,.030),WOOD)
    for z in np.linspace(-.25,.21,6): block(out,(-.03,.866,float(z)),(.56,.030,.027),WOOD)
    planter(out,.36,.28,.605,.21)
    block(out,(-.36,.67,-.33),(.24,.13,.22),WALL)
    block(out,(-.36,.744,-.33),(.27,.023,.25),palette)
    return out


def gabled(palette):
    out=[]
    house_shell(out,width=1.03,length=.92,height=.49)
    arched_door(out,-.25,.055,.466,.20,.35)
    framed_window(out,.24,.18,.466,.24,.24)
    framed_window(out,-.20,.20,.521,.22,.22,True)
    framed_window(out,.23,.20,.521,.22,.22,True)
    rear_and_left_windows(out,1.03,.92,.20,.22)
    steps(out,-.25,.555,.30)
    tiled_roof(out,1.20,1.10,.574,.26,palette)
    framed_window(out,0,.608,.555,.145,.14)
    block(out,(.30,.78,-.25),(.13,.36,.14),STONE)
    block(out,(.30,.974,-.25),(.17,.037,.18),palette)
    plane(out,.30,.974,-.25+.093,.075,.012,"#4B4D44")
    planter(out,.30,.57,.072,.20)
    return out


def courtyard(palette):
    out=[]
    block(out,(0,.018,0),(1.16,.036,1.04),STONE)
    # Three masonry wings create an open, visible court. It is inside the
    # sprite footprint and does not pretend to reserve gameplay space.
    for cx,cz,w,l in [(-.39,0,.34,.91),(.39,0,.34,.91),(0,-.32,.50,.30)]:
        block(out,(cx,.25,cz),(w,.46,l),WALL)
        cornice(out,w+.02,l+.02,.50,cx,cz)
        tiled_roof(out,w+.10,l+.07,.552,.115,palette,cx,cz)
    block(out,(0,.062,.12),(.42,.029,.60),["#CDBF9D"]*3)
    for z in [-.13,.04,.21,.38]:
        plane(out,0,.073,z,.39,.004,"#A89C83")
    arched_door(out,0,.05,-.164,.16,.31)
    framed_window(out,-.39,.17,.461,.17,.22)
    framed_window(out,.39,.17,.461,.17,.22)
    for z in [-.18,.20]: framed_window(out,z,.19,.566,.17,.21,True)
    rear=[];left=[]
    for x in [-.39,.39]: framed_window(rear,x,.17,.461,.17,.22)
    for z in [-.18,.20]: framed_window(left,z,.19,.566,.17,.21,True)
    reflected_details(out,rear,2);reflected_details(out,left,0)
    steps(out,0,.48,.29,2)
    planter(out,-.10,.31,.08,.17)
    # A light timber trellis defines the courtyard entry without filling it.
    for x in [-.20,.20]: block(out,(x,.19,.42),(.029,.24,.029),WOOD)
    for x in [-.19,-.08,.03,.14]: block(out,(x,.327,.405),(.025,.024,.16),WOOD)
    block(out,(0,.319,.43),(.47,.028,.036),WOOD)
    # A small peristyle inside the true open court, not an extra reserved lot.
    for x in [-.20,.20]:
        for z in [-.13,.20]: classical_column(out,x,z,.086,.48,.025)
        block(out,(x,.495,.035),(.087,.035,.45),STONE)
    return out


def shop(palette):
    out=[]
    house_shell(out,width=1.08,length=.85,height=.52)
    # Roman taberna: broad open timber shopfront, a dressed-stone lintel,
    # shutters stacked beside the entrance and jars on the shop counter.
    block(out,(0,.257,.439),(.91,.38,.032),STONE)
    plane(out,0,.068,.460,.78,.35,OPENING)
    block(out,(0,.077,.478),(.83,.045,.13),STONE)
    for x in [-.44,.44]:
        block(out,(x,.26,.475),(.068,.38,.068),WOOD)
        for z in [.49,.52,.55]: block(out,(x,.24,z),(.045,.31,.018),WOOD)
    block(out,(0,.45,.48),(.98,.056,.066),STONE)
    framed_window(out,-.18,.21,.546,.27,.26,True)
    framed_window(out,.22,.21,.546,.23,.26,True)
    rear_and_left_windows(out,1.08,.85,.20,.23)
    tiled_roof(out,1.20,1.01,.607,.17,palette,cz=-.03)
    # Fabric awning, shaped valance, cornice sign frame, shelf and urns.
    for index in range(8):
        x0=-.55+index*1.10/8;x1=x0+1.10/8
        tint="#D5B985" if index%2 else "#BD8E5F"
        b.face(out,[(x0,.51,.46),(x1,.51,.46),(x1,.37,.63),(x0,.37,.63)],tint)
        b.face(out,[(x0,.37,.63),(x1,.37,.63),(x1-.014,.326,.644),(x0+.014,.326,.644)],tint)
    for x in [-.52,.52]: block(out,(x,.20,.61),(.036,.30,.036),WOOD)
    block(out,(0,.561,.466),(.57,.091,.045),WOOD)
    plane(out,0,.539,.494,.48,.045,"#DBC59B")
    for x in [-.17,-.05,.08,.20]: plane(out,x,.554,.495,.047,.012,"#877553")
    steps(out,0,.55,.25,2)
    block(out,(-.39,.102,.575),(.20,.13,.15),WOOD)
    for x in [-.44,-.36]: ellipsoid(out,(x,.20,.60),(.048,.060,.048),"#D1AB67",8,3)
    planter(out,.41,.59,.05,.18)
    return out


def civic(palette):
    out=[]
    for index in range(3): block(out,(0,.028+index*.038,.07),(2.02-index*.09,.056,1.66-index*.09),STONE)
    block(out,(0,.52,-.15),(1.54,.77,1.04),WALL)
    masonry(out,1.54,1.04,.135,.77,cz=-.15)
    arched_door(out,0,.135,.377,.34,.58)
    for x in [-.53,.53]: framed_window(out,x,.42,.377,.20,.28)
    for z in [-.44,-.03,.28]: framed_window(out,z,.43,.775,.22,.29,True)
    rear=[];left=[]
    for x in [-.46,.46]: framed_window(rear,x,.43,.677,.25,.30)
    for z in [-.44,-.03,.28]: framed_window(left,z,.43,.775,.22,.29,True)
    reflected_details(out,rear,2);reflected_details(out,left,0)
    # Hexastyle Greek portico: fluted Doric shafts, entasis, echinus and
    # abacus, continuous architrave, alternating triglyphs/metopes, pediment.
    for x in [-.80,-.48,-.16,.16,.48,.80]: classical_column(out,x,.70,.13,.955,.047)
    block(out,(0,.982,.67),(1.96,.072,.40),STONE)
    block(out,(0,1.043,.67),(1.98,.050,.42),WALL)
    for x in np.linspace(-.88,.88,11):
        block(out,(float(x),1.045,.894),(.048,.063,.028),STONE)
        for line in [-.012,.012]: plane(out,float(x)+line,1.025,.910,.004,.038,"#A8987F")
    cornice(out,1.97,1.55,1.095,cz=-.02)
    tiled_roof(out,2.10,1.66,1.16,.33,palette,cz=-.02)
    # Full-width exposed tympanum with a raised raking geison and inset relief.
    b.face(out,[(-1.015,1.136,.862),(1.015,1.136,.862),(0,1.48,.862)],STONE[2])
    b.face(out,[(-.82,1.18,.874),(.82,1.18,.874),(0,1.438,.874)],WALL[1])
    for sign in [-1,1]:
        b.face(out,[(0,1.49,.887),(sign*1.045,1.154,.887),(sign*1.035,1.122,.887),(0,1.456,.887)],STONE[2])
    block(out,(0,1.155,.882),(2.12,.044,.064),STONE)
    # A stone disk and two stylized relief figures belong to the tympanum.
    relief=[]
    ring_volume(relief,[(0,.06,.06),(.020,.06,.06)],STONE[2],20)
    for _,vertices,tint in relief: b.face(out,[(vx,1.292+vz,.891+vy) for vx,vy,vz in vertices],tint)
    for x in [-.24,.24]:
        block(out,(x,1.27,.888),(.037,.11,.023),STONE)
        ellipsoid(out,(x,1.343,.888),(.030,.032,.018),STONE[2],8,3)
    for x in [-.70,.70]: planter(out,x,.77,.13,.19)
    return out


def branch(out,nodes,color="#877B64",sides=10):
    """A continuous bent/tapering woody limb, with real forks and bark facets."""
    rings=[]
    for band,(x,y,z,radius) in enumerate(nodes):
        rings.append([(x+radius*(1+.08*math.sin(i*2.7+band))*math.cos(i*math.tau/sides),y,
                       z+radius*(1+.06*math.cos(i*2.1-band))*math.sin(i*math.tau/sides)) for i in range(sides)])
    b.face(out,list(reversed(rings[0])),color)
    for band,(lower,upper) in enumerate(zip(rings,rings[1:])):
        for i in range(sides):
            tint=color if i%4 else "#A2947B"
            b.face(out,[lower[i],lower[(i+1)%sides],upper[(i+1)%sides],upper[i]],tint)
    b.face(out,rings[-1],color)


def leaf_mass(out,center,radii,color,phase,leaves=True):
    """An asymmetric lobed solid crown; uneven sprays break the outer contour."""
    cx,cy,cz=center;rx,ry,rz=radii
    sides,bands=14,7;rings=[]
    for band in range(bands+1):
        latitude=-math.pi/2+band*math.pi/bands
        radial=max(.006,math.cos(latitude))
        rings.append([(cx+rx*radial*(1+.13*math.sin(i*2.3+phase)+.05*math.cos(band*3+i))*math.cos(i*math.tau/sides),
                       cy+ry*math.sin(latitude)+ry*.05*math.sin(i*2.1+phase)*radial,
                       cz+rz*radial*(1+.11*math.cos(i*2.7+phase))*math.sin(i*math.tau/sides)) for i in range(sides)])
    b.face(out,list(reversed(rings[0])),color)
    for band,(lower,upper) in enumerate(zip(rings,rings[1:])):
        for i in range(sides):
            tint=color
            if (i+band*3+round(phase))%9==0: tint="#A4AD91" if cy>1.0 else "#899780"
            b.face(out,[lower[i],lower[(i+1)%sides],upper[(i+1)%sides],upper[i]],tint)
    b.face(out,rings[-1],color)
    if leaves:
        # Lancet olive leaves are slender folded solids, not painted speckles.
        for spray in range(13):
            angle=spray*2.399+phase
            elevation=.15+.47*(.5+.5*math.sin(spray*1.73+phase))
            at=np.array([cx+rx*.82*math.cos(angle),cy+ry*elevation,cz+rz*.82*math.sin(angle)])
            along=np.array([math.cos(angle),.28,math.sin(angle)])*.061
            across=np.array([-math.sin(angle),.05,math.cos(angle)])*.013
            ridge=at+np.array([0,.014,0])
            b.face(out,[at-along,at+across,ridge,at+along],"#A9B298")
            b.face(out,[at-along,at-across,ridge,at+along],"#7B8B72")


def tree(kind):
    out=[]
    if kind=="canopy":
        # The olive is low, broad and gnarled; five limbs carry unequal crowns,
        # while two deliberate crown windows reveal the branching structure.
        branch(out,[(0,0,0,.065),(-.02,.18,.018,.056),(.025,.40,-.010,.047),
                    (-.020,.61,-.026,.034),(-.072,.81,-.020,.022)],sides=12)
        limbs=[[(.004,.35,.006,.042),(-.14,.59,.08,.032),(-.29,.83,.085,.020),(-.43,1.035,.070,.008)],
               [(.025,.40,-.01,.037),(.18,.63,.12,.029),(.32,.88,.16,.017),(.46,1.09,.18,.007)],
               [(-.015,.57,-.02,.028),(-.12,.76,-.19,.023),(-.23,.99,-.26,.013),(-.27,1.18,-.25,.006)],
               [(-.005,.59,-.02,.027),(.12,.79,-.15,.021),(.23,1.04,-.25,.013),(.18,1.24,-.28,.006)],
               [(.13,.61,.10,.024),(.12,.85,.28,.016),(.035,1.05,.35,.009)]]
        for limb in limbs: branch(out,limb,sides=9)
        branch(out,[(-.17,.65,.08,.016),(-.34,.81,-.04,.009),(-.40,.97,-.14,.004)],sides=7)
        branch(out,[(.25,.77,.14,.014),(.38,.88,.02,.010),(.47,1.015,-.04,.004)],sides=7)
        clusters=[(-.43,1.11,.07,.25,.18,.21,"#748367"),(.46,1.17,.18,.24,.20,.20,"#839173"),
                  (-.29,1.25,-.26,.23,.22,.19,"#75896E"),(.18,1.32,-.29,.22,.21,.19,"#8A987D"),
                  (.025,1.14,.37,.22,.15,.19,"#687B61"),(-.12,1.20,.15,.18,.16,.17,"#879477"),
                  (-.47,1.02,-.17,.16,.13,.15,"#748168"),(.48,1.09,-.05,.16,.15,.16,"#98A187"),
                  (-.11,1.41,-.15,.15,.14,.13,"#A0AB90")]
        for index,(x,y,z,rx,ry,rz,tint) in enumerate(clusters): leaf_mass(out,(x,y,z),(rx,ry,rz),tint,index*.73)
    else:
        # Mediterranean cypress: one narrow rising axis, oblique branches and
        # unequal vertical foliage fingers. No repeated horizontal cone tiers.
        branch(out,[(0,0,0,.047),(.006,.28,.003,.040),(-.015,.63,-.009,.029),
                    (.016,1.02,-.006,.023),(.008,1.40,.014,.015),(-.018,1.92,.0,.004)],"#857A62",10)
        crowns=[(-.08,.59,.015,.14,.28,.11,"#5C7159"),(.08,.83,-.035,.13,.31,.11,"#667D61"),
                (-.06,1.07,-.09,.125,.32,.10,"#74876C"),(.085,1.20,.075,.115,.31,.10,"#6B8165"),
                (-.065,1.45,.04,.105,.33,.087,"#7D9073"),(.035,1.62,-.065,.085,.29,.070,"#8A9A7D"),
                (-.020,1.87,.00,.057,.22,.051,"#96A58A"),(.07,.64,.10,.10,.23,.089,"#536D55"),
                (-.12,.87,.03,.074,.20,.07,"#6C8066"),(.115,1.04,.02,.068,.21,.063,"#7D8D73")]
        for index,(x,y,z,rx,ry,rz,tint) in enumerate(crowns):
            branch(out,[(0,max(.20,y-.27),0,.014),(x*.5,y-.11,z*.5,.009),(x,y+.08,z,.003)],"#91866D",7)
            leaf_mass(out,(x,y,z),(rx,ry,rz),tint,index*.87,False)
        # Smaller long sprays supply an irregular needle edge and inner slits.
        for index in range(9):
            y=.68+index*.125;angle=index*2.1
            x,z=.10*math.cos(angle),.07*math.sin(angle)
            leaf_mass(out,(x,y,z),(.045,.18+.04*math.sin(index),.040),"#819077",index,False)
    return out


def raster_svg(svg, target=None):
    doc=ET.fromstring(svg.read_text(encoding="utf-8"))
    left,top,width,height=map(float,doc.attrib["viewBox"].split())
    w,h=int(doc.attrib["width"]),int(doc.attrib["height"])
    sample=2
    result=Image.new("RGBA",(w*sample,h*sample))
    painter=ImageDraw.Draw(result)
    for element in doc:
        if not element.tag.endswith("path"): continue
        for contour in element.attrib["d"].split("M")[1:]:
            points=re.findall(r"(-?[\d.]+),(-?[\d.]+)",contour)
            painter.polygon([((float(x)-left)/width*w*sample,(float(y)-top)/height*h*sample) for x,y in points],fill=element.attrib["fill"])
    result=result.resize((w,h),Image.Resampling.LANCZOS)
    if target: result.save(target)
    return result


def write_texture_import(path):
    """Retain Godot UIDs, and prefilter the 1024px bake for the city scale."""
    settings=path.with_suffix(path.suffix+".import")
    if settings.exists():
        text=settings.read_text(encoding="utf-8")
        text=text.replace("mipmaps/generate=false","mipmaps/generate=true")
    else:
        source="res://"+path.relative_to(ROOT).as_posix()
        text=f'[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n\n[deps]\nsource_file="{source}"\n\n[params]\ncompress/mode=0\nmipmaps/generate=true\nprocess/fix_alpha_border=true\n'
    settings.write_text(text,encoding="utf-8",newline="\n")


def rotated_geometry(geometry,orientation):
    # Builders' entrance is +z. Canonical is -z, followed by true Y rotations
    # -90/-180/-270: orientation indices point north/east/south/west in World.
    angle=math.radians(180-orientation*90)
    c,s=math.cos(angle),math.sin(angle)
    return [(sum(b.depth(p) for p in vertices)/len(vertices),vertices,tint)
            for _,points,tint in geometry
            for vertices in [[(round(c*x+s*z,9),y,round(-s*x+c*z,9)) for x,y,z in points]]]


def bake(identifier,label,role,geometry,expression="",orientation=0,canonical_id=""):
    plot_span=.8
    if role=="tree":
        geometry,plot_span=calibrate(geometry,15 if "pine" in identifier else 30,42 if "pine" in identifier else 36)
    if role=="civic": plot_span=1.0
    points3=np.asarray([p for _,vertices,_ in geometry for p in vertices])
    points2=np.asarray([b.project(p) for p in points3])
    left,top=points2.min(axis=0)-.026
    width,height=points2.max(axis=0)-(left,top)+.026
    ppu=1024/max(width,height)
    w,h=round(width*ppu),round(height*ppu)
    shaded=[(depth,vertices,shade_hex(color,vertices)) for depth,vertices,color in geometry]
    parts=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{left:.6f} {top:.6f} {width:.6f} {height:.6f}">',f'<title>{label}</title>']
    ordered=b.painter_order(shaded)
    for color,items in itertools.groupby(ordered,key=lambda item:item[2]):
        contours=[]
        for _,vertices,_ in items:
            projected=[b.project(p) for p in vertices]
            area=sum(a[0]*c[1]-c[0]*a[1] for a,c in zip(projected,projected[1:]+projected[:1]))
            if area<0: projected.reverse()
            contours.append("M"+" L".join(f"{x:.6f},{y:.6f}" for x,y in projected)+" Z")
        parts.append(f'<path d="{" ".join(contours)}" fill="{color}" fill-rule="nonzero"/>')
    parts.append("</svg>")
    svg=OUTPUT/"SVG"/f"{identifier}.svg"
    svg.write_text("\n".join(parts)+"\n",encoding="utf-8",newline="\n")
    png=OUTPUT/"整图"/f"{identifier}.png"
    raster_svg(svg,png)
    bounds=np.ptp(points3,axis=0)
    entry={"id":identifier,"display_name":label,"category":"historical_building_candidate",
           "role":role,"texture":png.relative_to(ROOT).as_posix(),"editable_source":svg.relative_to(ROOT).as_posix(),
           "origin":[-left*ppu,-top*ppu],"pixels_per_world":ppu,"plot_span":plot_span,
           "image_bounds":{"width":w,"height":h,"crop":[0,0,w,h]},
           "model_bounds":{"position":points3.min(axis=0).tolist(),"size":bounds.tolist()},
           "source":"tools/build_refined_valley_art.py; original project geometry",
           "license":"Project-authored geometry","source_url":"","availability":"production_refined_valley",
           "era":1,"historical_language":"Classical Greek / Roman stone, terracotta, timber; no modern glass grids",
           "camera":{"azimuth":45,"elevation":30,"projection":"orthogonal"},
           "geometry_faces":len(geometry),"texture_sha256":hashlib.sha256(png.read_bytes()).hexdigest(),
           "source_sha256":hashlib.sha256(svg.read_bytes()).hexdigest(),"refined_valley":True}
    if role != "tree":
        entry.update({"canonical_id":canonical_id or identifier,"orientation":orientation,
                      "rotation_y_degrees":-orientation*90,
                      "entrance_normal":[round(math.sin(orientation*math.pi/2)),round(-math.cos(orientation*math.pi/2))]})
    else:
        olive="canopy" in identifier
        entry.update({"tree_species":"olive" if olive else "mediterranean_cypress",
                      "morphology":"gnarled branching limbs, unequal grey-green lobed leaf masses and crown windows" if olive else "tapered rising trunk, oblique forks and uneven upright foliage fingers",
                      "historical_language":"First-era Mediterranean olive / cypress; project-authored botanical form",
                      "tree_revision":208,"stable_tone":0 if olive else 1})
    masks(entry,[(np.asarray(vertices),face_normal(vertices)) for _,vertices,_ in geometry],OUTPUT,OUTPUT)
    for path in [png,ROOT/entry["shadow_texture"],ROOT/entry["contact_texture"]]: write_texture_import(path)
    entry["category"]="residential" if role in ["terrace","gabled","courtyard"] else role
    if expression: entry["first_expression_style"]=expression
    if role in ["terrace","gabled","courtyard"]:
        entry.update({"variant":role,"roof_style":role,"roof_eave_y":.552 if role=="courtyard" else .574,
                      "roof_half_extents":[float(bounds[0])/2,float(bounds[2])/2]})
    scale=28*math.sqrt(2)*plot_span/max(bounds[0],bounds[2])/ppu
    entry["runtime_reference"]={"visible_size_px":[round(w*scale,3),round(h*scale,3)],"ground_anchor":"actual model foot (0,0,0)"}
    return entry


def validate(entries):
    records=[]
    for entry in entries:
        image=Image.open(ROOT/entry["texture"]).convert("RGBA")
        assert image.size==(entry["image_bounds"]["width"],entry["image_bounds"]["height"])
        assert image.getchannel("A").getextrema()==(0,255)
        assert entry["lighting"]["ground_anchor_world"]==[0.0,0.0,0.0]
        for kind in ["texture","shadow","contact"]:
            path=ROOT/entry[kind if kind=="texture" else kind+"_texture"]
            key="texture_sha256" if kind=="texture" else kind+"_sha256"
            assert hashlib.sha256(path.read_bytes()).hexdigest()==entry[key]
        assert entry["geometry_faces"]>=90
        records.append({"id":entry["id"],"faces":entry["geometry_faces"],"alpha_contour":"PASS",
                        "anchor":"PASS","hashes":"PASS","visible_size_px":entry["runtime_reference"]["visible_size_px"]})
    (OUTPUT/"validation.json").write_text(json.dumps({"passed":True,"entries":records,"source":"Actual baked PNG/SVG plus geometric shadow/contact; visual sheet still requires live-window review."},ensure_ascii=False,indent=2)+"\n",encoding="utf-8")


def preview(entries):
    entries=[entry for entry in entries if int(entry.get("orientation",0)) == 2 or entry["role"] == "tree"]
    sheet=Image.new("RGB",(1500,1120),"#DED5BA")
    draw=ImageDraw.Draw(sheet)
    draw.text((28,18),"CLASSICAL VALLEY / actual south-facing templates / city scale x5",fill="#415E57")
    for index,entry in enumerate(entries):
        x=(index%5)*300;y=(index//5)*520+50
        draw.rounded_rectangle((x+12,y,x+288,y+484),12,fill="#F3EAD3")
        draw.text((x+22,y+15),entry["id"].replace("refined_",""),fill="#475B52")
        image=Image.open(ROOT/entry["texture"]).convert("RGBA")
        scale=28*math.sqrt(2)*entry["plot_span"]/max(entry["model_bounds"]["size"][0],entry["model_bounds"]["size"][2])/entry["pixels_per_world"]*5
        image.thumbnail((round(image.width*scale),round(image.height*scale)),Image.Resampling.LANCZOS)
        sheet.paste(image,(x+150-image.width//2,y+90),image)
        draw.text((x+22,y+448),f'{entry["geometry_faces"]} geometry faces / PNG alpha',fill="#6E7967")
    sheet.save(OUTPUT/"资产接触表.png")


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--trees-only",action="store_true",help="Bake only two trees; preserve every building entry and file byte for byte")
    args=parser.parse_args()
    for folder in ["SVG","整图","阴影"]: (OUTPUT/folder).mkdir(parents=True,exist_ok=True)
    if args.trees_only:
        rebuild_trees()
        return
    makers=[("refined_house_terrace","石檐露台住宅","terrace",terrace(ROOFS["tile"]),""),
            ("refined_house_gabled","陶瓦坡屋住宅","gabled",gabled(ROOFS["tile"]),""),
            ("refined_house_courtyard","开庭连翼住宅","courtyard",courtyard(ROOFS["tile"]),""),
            ("refined_shop_arcade","遮檐拱窗商铺","commercial",shop(ROOFS["tile"]),""),
            ("refined_civic_loggia","柱廊文化馆","civic",civic(ROOFS["tile"]),""),
            ("refined_deep_terrace","深流石蓝露台","terrace",terrace(ROOFS["deep"]),"deep"),
            ("refined_weave_shop","织机陶瓦商铺","commercial",shop(ROOFS["tile"]),"weave"),
            ("refined_warm_courtyard","暖庭绿灰庭院","courtyard",courtyard(ROOFS["warm"]),"warm"),
            ("refined_tree_canopy","分叉灰绿橄榄树","tree",tree("canopy"),""),
            ("refined_tree_pine","细长地中海柏","tree",tree("pine"),"")]
    entries=[];orientations={}
    for identifier,label,role,geometry,expression in makers:
        indices=range(4) if role != "tree" else [0]
        ids=[]
        for orientation in indices:
            name=identifier if orientation == 0 else identifier+f"_o{orientation}"
            print("BAKE",name,len(geometry),flush=True)
            oriented=rotated_geometry(geometry,orientation) if role != "tree" else geometry
            entries.append(bake(name,label,role,oriented,expression,orientation,identifier))
            ids.append(name)
        if role != "tree": orientations[identifier]=ids
    manifest={"schema_version":2,"era":1,"direction":"第一时代 · 古典希腊/罗马精制河湾 · 暖石/陶瓦/石蓝/绿灰/深松绿",
              "entries":entries,"residential_ids":["refined_house_terrace","refined_house_gabled","refined_house_courtyard"],
              "commercial_id":"refined_shop_arcade","civic_id":"refined_civic_loggia",
              "tree_ids":["refined_tree_canopy","refined_tree_pine"],
              "authored_ids":{"deep":"refined_deep_terrace","weave":"refined_weave_shop","warm":"refined_warm_courtyard"},
              "orientations":orientations,"orientation_contract":{"0":[0,-1],"1":[1,0],"2":[0,1],"3":[-1,0],"construction":"Actual geometry rotated around (0,0,0) before shading, BSP, raster and physical shadow projection"},
              "ground_anchor":"actual foot (0,0,0), common to texture and physical masks",
              "palette":{"wall":"#E4D3B1","stone":"#F1E3C7","tile":"#B97859","deep":"#597A83","warm":"#728A72","tree":"#4D7960"},
              "production":"Presentation replacement only; retained original resources remain available."}
    (OUTPUT/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    validate(entries)
    preview(entries)
    print("REFINED_VALLEY_ART",len(entries),"assets / alpha, origin and hashes PASS")


def rebuild_trees():
    manifest=json.loads((OUTPUT/"manifest.json").read_text(encoding="utf-8"))
    buildings=[entry for entry in manifest["entries"] if entry["role"]!="tree"]
    before={}
    for entry in buildings:
        for key in ["texture","editable_source","shadow_texture","contact_texture"]:
            path=ROOT/entry[key]
            for file in [path,path.with_suffix(path.suffix+".import")]:
                if file.exists(): before[file.relative_to(ROOT).as_posix()]=hashlib.sha256(file.read_bytes()).hexdigest()
    replacements={}
    for identifier,label,kind in [("refined_tree_canopy","分叉灰绿橄榄树","canopy"),("refined_tree_pine","细长地中海柏","pine")]:
        geometry=tree(kind)
        print("BAKE_TREE",identifier,len(geometry),flush=True)
        replacements[identifier]=bake(identifier,label,"tree",geometry)
    manifest["entries"]=[replacements.get(entry["id"],entry) for entry in manifest["entries"]]
    manifest["vegetation_revision"]=208
    (OUTPUT/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    after={path:hashlib.sha256((ROOT/path).read_bytes()).hexdigest() for path in before}
    assert before==after and buildings==[entry for entry in manifest["entries"] if entry["role"]!="tree"]
    validate(manifest["entries"])
    preview(manifest["entries"])
    evidence=ROOT/"验证记录/round208_古典植被"
    evidence.mkdir(parents=True,exist_ok=True)
    (evidence/"building_unchanged.json").write_text(json.dumps({"passed":True,"building_entries":len(buildings),"building_files":len(before),"hashes":after,"command":"python tools/build_refined_valley_art.py --trees-only"},ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    tree_evidence(manifest)
    print("TREES_ONLY 2 bakes /",len(buildings),"building entries and",len(before),"building files unchanged / PASS")


def tree_evidence(manifest):
    """Check BSP visibility against a separate triangle depth raster, and show
    old/new silhouettes at their real runtime scale without rebuilding houses.
    """
    archive=ROOT/"废弃/美术/round208_树形替换前"
    evidence=ROOT/"验证记录/round208_古典植被"
    evidence.mkdir(parents=True,exist_ok=True)
    old=json.loads((archive/"manifest.json").read_text(encoding="utf-8"))
    old_entries={entry["id"]:entry for entry in old["entries"] if entry["role"]=="tree"}
    entries={entry["id"]:entry for entry in manifest["entries"] if entry["role"]=="tree"}
    sheet=Image.new("RGB",(1200,680),"#DED5BA");draw=ImageDraw.Draw(sheet)
    draw.text((24,18),"CLASSICAL TREES / same runtime ground scale x7 / old and new",fill="#415E57")
    results=[]
    for species,identifier in [("canopy","refined_tree_canopy"),("pine","refined_tree_pine")]:
        entry=entries[identifier]
        geometry,_=calibrate(tree(species),15 if species=="pine" else 30,42 if species=="pine" else 36)
        size=np.array([entry["image_bounds"]["width"],entry["image_bounds"]["height"]])
        ratio=192/max(size);wh=np.maximum(1,np.rint(size*ratio).astype(int))
        depth=np.full((wh[1],wh[0]),-np.inf);reference=np.zeros((wh[1],wh[0],3))
        for _,vertices,color in geometry:
            projected=np.asarray([b.project(v) for v in vertices])*entry["pixels_per_world"]*ratio+np.asarray(entry["origin"])*ratio
            distance=np.asarray([b.depth(v) for v in vertices]);rgb=np.array(list(bytes.fromhex(shade_hex(color,vertices)[1:])))
            for index in range(1,len(vertices)-1):
                tri=projected[[0,index,index+1]];d=distance[[0,index,index+1]]
                lo=np.maximum(0,np.ceil(tri.min(0)).astype(int));hi=np.minimum(wh-1,np.floor(tri.max(0)).astype(int))
                if np.any(hi<lo): continue
                xx,yy=np.meshgrid(np.arange(lo[0],hi[0]+1)+.5,np.arange(lo[1],hi[1]+1)+.5)
                (ax,ay),(bx,by),(cx,cy)=tri;den=(by-cy)*(ax-cx)+(cx-bx)*(ay-cy)
                if abs(den)<1e-8: continue
                a=((by-cy)*(xx-cx)+(cx-bx)*(yy-cy))/den
                c=((cy-ay)*(xx-cx)+(ax-cx)*(yy-cy))/den;f=1-a-c
                dd=a*d[0]+c*d[1]+f*d[2]
                region=depth[lo[1]:hi[1]+1,lo[0]:hi[0]+1]
                mask=(a>.01)&(c>.01)&(f>.01)&(dd>=region-1e-6)
                region[mask]=dd[mask];reference[lo[1]:hi[1]+1,lo[0]:hi[0]+1][mask]=rgb
        actual=np.asarray(Image.open(ROOT/entry["texture"]).resize(tuple(wh),Image.Resampling.LANCZOS)).astype(float)
        visible=np.isfinite(depth)&(actual[:,:,3]>250)
        agreement=float((np.abs(actual[:,:,:3]-reference).max(-1)[visible]<24).mean())
        assert agreement>.93
        old_alpha=np.asarray(Image.open(archive/old_entries[identifier]["texture"]).resize((128,128)).getchannel("A"))>127
        new_alpha=np.asarray(Image.open(ROOT/entry["texture"]).resize((128,128)).getchannel("A"))>127
        difference=float(np.logical_xor(old_alpha,new_alpha).sum()/np.logical_or(old_alpha,new_alpha).sum())
        assert difference>.15
        results.append({"id":identifier,"species":entry["tree_species"],"faces":len(geometry),"nearest_surface_samples":int(visible.sum()),"bsp_depth_agreement":round(agreement,6),"rgb_tolerance":24,"silhouette_change_fraction":round(difference,6),"runtime_size":entry["runtime_reference"]["visible_size_px"]})
        column=0 if species=="canopy" else 2
        for version,item,base in [(0,old_entries[identifier],archive),(1,entry,ROOT)]:
            x=(column+version)*300
            draw.rounded_rectangle((x+12,50,x+288,654),12,fill="#F3EAD3")
            title=("OLD / ROUND CANOPY" if species=="canopy" else "OLD / LAYERED PINE") if version==0 else ("NEW / OLIVE" if species=="canopy" else "NEW / CYPRESS")
            draw.text((x+26,71),title,fill="#415E57")
            image=Image.open(base/item["texture"]).convert("RGBA")
            factor=28*math.sqrt(2)*item["plot_span"]/max(item["model_bounds"]["size"][0],item["model_bounds"]["size"][2])/item["pixels_per_world"]*7
            rendered=image.resize((round(image.width*factor),round(image.height*factor)),Image.Resampling.LANCZOS)
            ground=(x+150,430)
            at=(round(ground[0]-item["origin"][0]*factor),round(ground[1]-item["origin"][1]*factor))
            sheet.paste(rendered,at,rendered)
            draw.line((x+24,430,x+276,430),fill="#BCAF8F",width=1)
            draw.text((x+26,476),f'Geometry: {item["geometry_faces"]} faces',fill="#596A57")
            draw.text((x+26,498),f'City: {item["runtime_reference"]["visible_size_px"]} px',fill="#596A57")
            # Actual city-size cutout is also shown, not only an enlarged tree.
            small=image.resize((max(1,round(image.width*factor/7)),max(1,round(image.height*factor/7))),Image.Resampling.LANCZOS)
            sheet.paste(small,(x+150-small.width//2,540),small)
    sheet.save(evidence/"树形旧新对照.png")
    (evidence/"geometry.json").write_text(json.dumps({"passed":True,"trees":results,"scope":"Independent triangle nearest-depth check against BSP PNG; edge antialias pixels excluded. No human aesthetic approval."},ensure_ascii=False,indent=2)+"\n",encoding="utf-8")


if __name__=="__main__": main()
