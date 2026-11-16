#!/usr/bin/env python3
"""Original vector cartography for fictional Leth; no external source artwork."""
from pathlib import Path
import random
random.seed(151126)
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="1000" viewBox="0 0 1600 1000">', '''<defs>
<pattern id="water" width="54" height="32" patternUnits="userSpaceOnUse"><path d="M3 10 Q12 4 21 10 T39 10 M27 26 Q36 20 45 26" fill="none" stroke="#456b6d" stroke-width="1" opacity=".38"/></pattern>
<pattern id="earth" width="23" height="23" patternUnits="userSpaceOnUse"><path d="M2 7h3 M13 18h4" stroke="#a18f68" stroke-width=".8" opacity=".3"/></pattern>
<pattern id="marsh" width="25" height="23" patternUnits="userSpaceOnUse"><path d="M5 19l-2-8m2 8l3-12m10 6l-1-8m1 8l3-5" fill="none" stroke="#738b69" stroke-width="1.4"/></pattern>
<filter id="shadow"><feDropShadow dx="3" dy="5" stdDeviation="2" flood-color="#092f36" flood-opacity=".25"/></filter>
</defs>
<rect width="1600" height="1000" fill="#244b54"/><rect width="1600" height="1000" fill="url(#water)"/>
<path id="land" d="M0 0H1290 L1280 180 Q1320 280 1250 375 L1270 478 Q1220 550 1228 615 L1190 707 1230 755 1140 790 1088 833 960 845 874 802 780 834 702 794 570 837 460 810 350 829 250 788 134 825 0 795Z" fill="#cbb98c" stroke="#8a9b79" stroke-width="8"/>
<path d="M0 0H1290 L1280 180 Q1320 280 1250 375 L1270 478 Q1220 550 1228 615 L1190 707 1230 755 1140 790 1088 833 960 845 874 802 780 834 702 794 570 837 460 810 350 829 250 788 134 825 0 795Z" fill="url(#earth)"/>
<path d="M1390 332 Q1430 300 1469 336 L1520 380 1511 440 1565 494 1557 574 1537 626 1556 686 1530 745 1475 780 1444 821 1360 801 1329 747 1349 689 1320 625 1336 568 1328 508 1359 446 1351 390Z" fill="#bcc09a" stroke="#78937d" stroke-width="7"/>
<path d="M1390 332 Q1430 300 1469 336 L1520 380 1511 440 1565 494 1557 574 1537 626 1556 686 1530 745 1475 780 1444 821 1360 801 1329 747 1349 689 1320 625 1336 568 1328 508 1359 446 1351 390Z" fill="url(#marsh)"/>
<path d="M-30 340C150 300 216 340 340 366S560 340 660 395 807 470 906 512 1035 583 1090 688 1130 791 1152 870" fill="none" stroke="#6e8e82" stroke-width="58"/>
<path d="M-30 340C150 300 216 340 340 366S560 340 660 395 807 470 906 512 1035 583 1090 688 1130 791 1152 870" fill="none" stroke="#315e65" stroke-width="45"/>
<path d="M-30 340C150 300 216 340 340 366S560 340 660 395 807 470 906 512 1035 583 1090 688 1130 791 1152 870" fill="none" stroke="#91aaa0" stroke-width="1.4" stroke-dasharray="9 12"/>
<path d="M340 22L340 274Q340 308 375 338L460 400Q510 450 510 505V747L557 836" fill="none" stroke="#8b9f82" stroke-width="31"/>
<path d="M340 22L340 274Q340 308 375 338L460 400Q510 450 510 505V747L557 836" fill="none" stroke="#39676a" stroke-width="23"/>
<path d="M740 10L730 195 786 307 825 452" fill="none" stroke="#8b9f82" stroke-width="26"/>
<path d="M740 10L730 195 786 307 825 452" fill="none" stroke="#39676a" stroke-width="18"/>
''']
def path(d,stroke,width,fill='none',extra=''):
 svg.append(f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" {extra}/>')
def rect(x,y,w,h,fill,stroke='#617360',sw=2,extra=''):
 svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" {extra}/>')
def circle(x,y,r,fill,stroke='#60715c',sw=1):
 svg.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>')
# Raised roads follow dry ground; paths connect the six map districts.
roads=['M80 180L260 180 280 95 555 95 650 185 720 245 830 245 1040 210 1210 135',
'M100 500L280 500 295 615 430 620 570 590 660 490 745 540 945 570 1040 725 1180 740',
'M180 755L260 685 295 615 280 500 290 420 280 295 260 180',
'M430 620L430 738 650 733 790 760 915 715 1040 725',
'M580 95L605 300 660 395 660 490 650 733',
'M830 245L905 345 940 415 945 570',
'M1040 210L1120 290 1165 420 1080 470 945 570',
'M1348 746L1410 668 1430 570 1395 450 1440 370',
'M1430 570L1510 528 1495 710']
for d in roads:
 path(d,'#aa9870',15);path(d,'#e8d7ae',10)
# Neighbourhood blocks: roofs, courtyards and engraved roof seams.
def block(x,y,w,h,rot=0,fill='#738370'):
 svg.append(f'<g transform="translate({x} {y}) rotate({rot})">')
 rect(3,4,w,h,'#9b9875','none',0)
 rect(0,0,w,h,fill,'#415d52',2)
 path(f'M0 0L{w/2} {h/2} {w} 0 M{w/2} {h/2}V{h}', '#a4aa88',1.3)
 svg.append('</g>')
clusters=[(75,400,4,3,35,28),(70,590,4,3,31,28),(325,435,4,3,32,24),(360,640,3,2,35,26),
(560,450,2,3,30,23),(655,80,2,3,28,24),(850,315,3,2,32,24),(1015,365,4,3,31,24),
(750,610,4,3,33,23),(790,785,3,1,36,22),(1150,580,2,2,28,24)]
for x,y,cols,rows,w,h in clusters:
 for row in range(rows):
  for col in range(cols):
   block(x+col*(w+8),y+row*(h+10),w,h,random.choice([-3,0,2]))
# Reservoir and three intake channels.
rect(60,40,220,75,'#3c6b6d','#587f70',5, 'rx="12"')
for y in [58,75,92]:path(f'M78 {y}H265','#89a69a',1)
for x in [125,180,235]:path(f'M{x} 115V155','#315e65',12)
# Waterworks roofs and circular settling tanks.
for x,y,w,h in [(95,175,95,65),(405,158,120,77),(510,65,82,55),(130,70,45,35)]:block(x,y,w,h)
for x,y in [(400,70),(455,70),(240,250)]:circle(x,y,29,'#839383','#415d52',3);circle(x,y,18,'#426e6c','#9bad93',2)
rect(288,274,116,32,'#a69b79','#4f6e60',3)
for x in range(300,398,14):path(f'M{x} 277V303','#5a6b5d',3)
# Archive quadrangle, bell tower and boarding house on the old harbour road.
for x,y,w,h in [(165,472,82,60),(272,481,80,46),(169,550,180,27),(462,455,95,57),(362,694,99,49),(203,710,82,48)]:block(x,y,w,h)
rect(208,521,72,24,'#cbb98c','#8a9774',2)
rect(452,578,60,61,'#6c7e69','#3c5a50',3);circle(482,609,20,'#9b9e7b','#415d52',2);circle(482,609,6,'#d1be91')
# Harbour piers, moorings, sailboats and ferry route.
for x in [165,245,355,440]:
 path(f'M{x} 775V865','#405e59',16);path(f'M{x} 775V865','#baa77f',10)
 for y in [806,840]:circle(x,y,3,'#526f63')
for x,y,rot in [(215,888,12),(384,873,-18),(730,893,35),(1186,873,18)]:
 svg.append(f'<g transform="translate({x} {y}) rotate({rot})">')
 path('M0 -25Q21 3 0 32Q-19 3 0 -25','#b3b697',2,'#796f55');path('M0 -22V26','#dfd2aa',2);path('M2 -17L18 14H2Z','#8c9b86',1,'#d9c8a1');svg.append('</g>')
path('M420 886Q810 950 1160 929T1390 808','#b6c2a5',2,extra='stroke-dasharray="7 10"')
# Observatory on contours, including dome, transit wing and instruments.
for radius in [145,175,205]:
 svg.append(f'<ellipse cx="1040" cy="155" rx="{radius}" ry="{radius*.62}" fill="none" stroke="#a69d76" stroke-width="1.5"/>')
for x,y,w,h in [(826,225,72,42),(939,155,120,62),(1095,222,76,55),(1167,92,43,70),(896,64,57,53)]:block(x,y,w,h)
circle(1053,91,46,'#859285','#425f57',4);circle(1053,91,33,'#587d77','#b3b79a',2)
path('M1012 88H1094 M1053 49V134','#c2c4a0',3)
path('M823 272L875 272 M826 282L872 282 M829 292L869 292','#7c8467',4)
# Civic complex: square, chamber, vault and print courtyard.
rect(723,383,180,139,'#d7c8a0','#b2a27c',2)
for x in range(742,900,26):path(f'M{x} 388V515','#b9ac83',1)
for y in range(403,520,24):path(f'M730 {y}H896','#b9ac83',1)
circle(813,451,23,'#6f9686','#9eaf8e',4);circle(813,451,9,'#c8c5a0')
for x,y,w,h in [(740,340,145,47),(955,387,69,66),(685,520,63,58),(1005,500,71,60),(905,610,78,46)]:block(x,y,w,h)
# Public waterfront: forum colonnade, signal house and record annexe.
for x,y,w,h in [(650,686,73,53),(772,645,67,50),(1088,636,69,45),(1118,748,61,41),(838,723,90,58),(970,751,83,50)]:block(x,y,w,h)
for x in range(843,930,14):circle(x,716,4,'#718777','#345950',1)
path('M1120 690L1175 715','#b7a77d',12)
# Island settlement with a glasshouse, clinic and memorial garden.
for x,y,w,h in [(1377,611,82,59),(1348,416,63,44),(1470,689,68,47)]:block(x,y,w,h)
rect(1464,475,58,82,'#89a69a','#527c70',3)
for x in [1477,1492,1507]:path(f'M{x} 480V551','#cbd1ae',2)
for y in [494,513,532]:path(f'M1468 {y}H1518','#cbd1ae',2)
path('M1345 749L1305 788','#c1ae80',9)
for x,y in [(1400,369),(1420,380),(1440,369),(1460,382),(1425,350)]:rect(x,y,10,16,'#d9c9a1','#718167',1,'rx="4"')
# Small tree groves express the hill and island edges without obscuring roads.
for cx,cy,rx,ry,n in [(1120,50,65,22,9),(1200,330,46,55,13),(85,130,25,23,6),(1370,540,15,30,8),(1500,610,18,34,8),(685,280,25,40,8)]:
 for _ in range(n):
  x=cx+random.uniform(-rx,rx);y=cy+random.uniform(-ry,ry)
  circle(round(x,1),round(y,1),random.randint(7,12),'#8f9c75','#738867',1)
# Timber and stone crossings align with the road network and canal banks.
for x,y,rot,w in [(285,339,6,90),(510,619,0,63),(654,395,-10,89),(827,452,-28,85),(1090,724,-22,81),(735,244,-15,62)]:
 svg.append(f'<g transform="translate({x} {y}) rotate({rot})">')
 rect(-w/2,-10,w,20,'#b9aa86','#4f6f61',2)
 path(f'M{-w/2} -6H{w/2} M{-w/2} 6H{w/2}','#e4d1a3',2)
 svg.append('</g>')
# Compass rose and frame.
svg.append('<g transform="translate(88 915)">')
for rot in [0,90,180,270]:
 svg.append(f'<path transform="rotate({rot})" d="M0 -40L8 0 0 10 -8 0Z" fill="#b4bda0" stroke="#829d90" stroke-width="1"/>')
circle(0,0,7,'#244b54','#d3c7a1',2);svg.append('</g>')
rect(15,15,1570,970,'none','#aeb692',2);rect(23,23,1554,954,'none','#6c8c7d',1)
svg.append('</svg>')
Path(__file__).with_name('leth-city.svg').write_text('\n'.join(svg)+'\n')
