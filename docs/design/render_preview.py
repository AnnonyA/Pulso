#!/usr/bin/env python3
"""Render the annotated design board, not an iOS simulator screenshot."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
S = 2
W, H = 1460, 1284
im = Image.new("RGB", (W*S, H*S), "#E9EEE7")
d = ImageDraw.Draw(im)
FONTS = Path("/usr/share/fonts/truetype/dejavu")
INK, BG, GREEN, MINT, MUTED = "#153B33", "#F4F8F4", "#116B53", "#B8F3D5", "#526A62"

def rect(x,y,w,h,fill,r=0,outline=None,width=1):
    d.rounded_rectangle((int(x*S),int(y*S),int((x+w)*S),int((y+h)*S)),radius=int(r*S),fill=fill,outline=outline,width=int(width*S))

def text(x,y,body,size=14,fill=INK,bold=False,spacing=1.25,anchor=None):
    font=ImageFont.truetype(str(FONTS/("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf")),int(size*S))
    for i,line in enumerate(body.split("\n")):
        d.text((int(x*S),int((y+i*size*spacing)*S)),line,font=font,fill=fill,anchor=anchor)

def line(points,fill,width=1):
    d.line([(int(x*S),int(y*S)) for x,y in points],fill=fill,width=int(width*S),joint="curve")

def wave(x,y,size=24,fill=GREEN):
    for n in (0.45,0.72,1.0):
        radius=size*n
        d.arc((int((x-radius)*S),int((y-radius)*S),int((x+radius)*S),int((y+radius)*S)),305,55,fill=fill,width=2*S)
    rect(x-1,y-1,2,2,fill,1)

def card_icon(x,y,fill=GREEN):
    rect(x,y,22,16,None,3,fill,1)
    line([(x,y+5),(x+22,y+5)],fill)
    line([(x+4,y+11),(x+9,y+11)],fill,2)

def clock_icon(x,y,fill=GREEN):
    d.ellipse((int(x*S),int(y*S),int((x+19)*S),int((y+19)*S)),outline=fill,width=2*S)
    line([(x+9.5,y+4),(x+9.5,y+10),(x+14,y+12)],fill,2)

def gear_icon(x,y,fill=GREEN):
    d.ellipse((int(x*S),int(y*S),int((x+19)*S),int((y+19)*S)),outline=fill,width=2*S)
    d.ellipse((int((x+6)*S),int((y+6)*S),int((x+13)*S),int((y+13)*S)),outline=fill,width=2*S)
    for px,py,qx,qy in [(9.5,-3,9.5,2),(9.5,17,9.5,22),(-3,9.5,2,9.5),(17,9.5,22,9.5)]:
        line([(x+px,y+py),(x+qx,y+qy)],fill,2)

def tabs(x,y,active=0):
    rect(x+14,y,350,63,"#F8FCF8",30,"#D4E4D9")
    for i,label in enumerate(["Tarjeta","Lecturas","Ajustes"]):
        xx=x+20+i*114
        if i==active: rect(xx,y+5,110,53,"#E0EDE3",25)
        f=GREEN if i==active else MUTED
        [card_icon,clock_icon,gear_icon][i](xx+44,y+12,f)
        text(xx+55,y+39,label,9,f,i==active,anchor="mt")

def phone(x,y,dark=False):
    rect(x+3,y+9,408,884,"#CFDCD1",54)
    rect(x,y,408,880,"#10221D",52)
    screen="#0A1716" if dark else BG
    rect(x+10,y+10,388,860,screen,43)
    fg="#ECF6EE" if dark else INK
    text(x+35,y+25,"9:41",12,fg,True)
    rect(x+117,y+10,174,28,"#10221D",0)
    rect(x+117,y+14,174,24,"#10221D",15)
    for i in range(3): rect(x+325+i*4,y+31-i*3,2,5+i*3,fg,1)
    rect(x+347,y+28,17,9,None,2,fg)
    rect(x+349,y+30,11,5,fg,1)
    rect(x+144,y+853,120,4,fg,2)
    return x+24,y+61

icon=Image.open(ROOT/"Sources/Pulso/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png").resize((46*S,46*S))
mask=Image.new("L",icon.size,0)
ImageDraw.Draw(mask).rounded_rectangle((0,0,icon.width-1,icon.height-1),radius=13*S,fill=255)
im.paste(icon,(68*S,49*S),mask)
text(128,57,"pulso",25,INK,True)
text(68,117,"Tu tarjeta, más cerca.",40,INK,True)
text(70,174,"Una app nativa para explorar tu tarjeta desde el iPhone.",15,MUTED)
text(70,199,"En español · Lectura NFC · Historial local · Sin cuenta",14,MUTED)
rect(1036,63,355,37,None,20,"#B7CFC0")
text(1213,74,"iPhone 11 y posteriores · iOS 26+",12,INK,True,anchor="mt")
text(1390,126,"VISTA DE DISEÑO",11,MUTED,True,anchor="rt")
text(1390,149,"Claro, oscuro y navegación nativa.",12,MUTED,anchor="rt")

# Initial dashboard. All transport fields remain unavailable.
x,y=phone(68,260)
rect(x+3,y,29,29,MINT,9); wave(x+12,y+14,10)
text(x+41,y-1,"pulso",23,INK,True); rect(x+321,y,29,29,"#FFFFFF",15,"#DCE7DF"); text(x+335,y+4,"?",16,INK,anchor="mt")
y+=58
text(x+3,y,"TU LECTOR PERSONAL",10,MUTED,True)
rect(x+274,y-5,77,27,"#E8F0EB",15); text(x+312,y+2,"iOS 26+",10,MUTED,anchor="mt")
text(x+3,y+34,"Tu tarjeta,\nmás cerca.",32,INK,True,1.07)
text(x+3,y+115,"Acercá tu SUBE y explorá lo que su chip\npermite leer.",12,MUTED,spacing=1.5)
cy=y+168
rect(x+3,cy,350,196,"#102B28",25)
text(x+25,cy+24,"TU TARJETA FÍSICA",10,MINT,True)
text(x+25,cy+49,"Lista para acercar",18,"#FFFFFF",True)
wave(x+302,cy+46,23,MINT)
text(x+25,cy+129,"Cerca. Simple. En tu iPhone.",10,MINT)
text(x+25,cy+151,"Lectura NFC",14,"#FFFFFF",True)
rect(x+299,cy+139,32,32,"#284B40",16); text(x+315,cy+141,"+",23,MINT,anchor="mt")
rect(x+3,cy+218,350,51,GREEN,18); wave(x+85,cy+243,13,"#FFFFFF"); text(x+194,cy+235,"Escanear tarjeta",14,"#FFFFFF",True,anchor="mt")
text(x+178,cy+283,"Apoyá la tarjeta en la parte superior del iPhone.",9,MUTED,anchor="mt")
py=cy+311
rect(x+3,py,350,139,"#FFFFFF",21,"#DCE7DF")
text(x+23,py+19,"DATOS DE TRANSPORTE",9,MUTED,True)
card_icon(x+23,py+45); text(x+53,py+45,"Saldo real",12,INK,True); text(x+332,py+45,"No disponible",12,MUTED,anchor="rt")
line([(x+23,py+73),(x+333,py+73)],"#E6EEE8")
clock_icon(x+24,py+85); text(x+53,py+86,"Último viaje",12,INK,True); text(x+332,py+86,"No disponible",12,MUTED,anchor="rt")
tabs(82,1051,0)

# Guided scanner, dark mode; shown before opening Apple's actual NFC sheet.
x,y=phone(526,260,True)
text(x+4,y+6,"Leer tarjeta",15,"#ECF6EE",True); rect(x+322,y,28,28,"#243B32",14); text(x+336,y+2,"×",19,"#B1C7BB",anchor="mt")
y+=61
text(x+4,y,"UN TOQUE, UNA LECTURA",10,"#B1C7BB",True)
text(x+4,y+29,"La señal está\nen la parte de arriba.",27,"#ECF6EE",True,1.12)
text(x+4,y+105,"Acercá la SUBE al borde superior trasero\ndel iPhone y mantenela quieta.",12,"#B1C7BB",spacing=1.5)
ay=y+175
for rad in [80,105]:
 d.ellipse((int((x+180-rad)*S),int((ay+100-rad)*S),int((x+180+rad)*S),int((ay+100+rad)*S)),outline="#264A3D",width=S)
rect(x+138,ay,108,200,"#1B362B",23,"#739F8B",2)
rect(x+172,ay+10,40,6,"#82A890",3)
wave(x+183,ay+59,25,MINT)
rect(x+40,ay+93,162,100,MINT,15)
text(x+58,ay+113,"TU TARJETA",11,INK,True); wave(x+174,ay+118,15,INK)
rect(x+59,ay+153,63,5,"#6EA58D",3)
sy=ay+228
for i,label in enumerate(["Retirá otras tarjetas y accesorios metálicos.","Tocá Iniciar lectura y acercá una sola tarjeta.","Esperá la respuesta sin mover el iPhone."]):
 yy=sy+i*55; rect(x+5,yy,28,28,"#1C322C",14); text(x+19,yy+6,str(i+1),11,"#9AE8BC",True,anchor="mt")
 # Keep the purpose of each step readable at the preview's small size.
 pieces=[("Retirá otras tarjetas y","accesorios metálicos."),("Tocá Iniciar lectura y acercá","una sola tarjeta."),("Esperá la respuesta sin","mover el iPhone.")][i]
 text(x+45,yy+1,"\n".join(pieces),12,"#DFEEE4",spacing=1.45)
rect(x+3,sy+180,350,51,MINT,18); wave(x+88,sy+205,13,INK); text(x+195,sy+196,"Iniciar lectura",14,INK,True,anchor="mt")
text(x+178,sy+245,"Se abre el lector NFC del sistema.",10,"#B1C7BB",anchor="mt")

# Empty history: no invented NFC reads.
x,y=phone(984,260)
text(x+4,y+6,"Lecturas",15,INK,True); clock_icon(x+325,y+6)
y+=63
text(x+3,y,"SOLO EN TU IPHONE",10,MUTED,True)
rect(x+271,y-7,80,29,None,15,"#C9DDCF"); text(x+311,y+2,"0 lecturas",10,MUTED,anchor="mt")
text(x+3,y+34,"Tus lecturas,\nen un solo lugar.",29,INK,True,1.13)
text(x+3,y+114,"Cada acercamiento, un poco más\nde información sobre tu tarjeta.",12,MUTED,spacing=1.5)
ay=y+218
rect(x+100,ay+8,117,130,"#E0EDE3",19,"#C9DDCE")
rect(x+120,ay-5,117,130,"#FBFDFB",19,"#C9DDCE")
for i,l in enumerate([35,70,58]): rect(x+143,ay+22+24*i,l,6,"#86B99E" if i==0 else "#CADCCF",3)
rect(x+208,ay+91,51,51,MINT,18); wave(x+226,ay+116,15,GREEN)
text(x+178,ay+171,"Tu primera lectura te espera",17,INK,True,anchor="mt")
text(x+178,ay+209,"Los escaneos que hagas aparecerán acá.",11,MUTED,anchor="mt")
text(x+178,ay+230,"Este es tu historial de lecturas NFC,",11,MUTED,anchor="mt")
text(x+178,ay+250,"no tu historial de viajes.",11,MUTED,anchor="mt")
rect(x+4,ay+290,349,49,"#E5F1E9",18,"#BCD4C4"); text(x+178,ay+305,"Ir al lector",13,GREEN,True,anchor="mt")
rect(x+4,ay+365,349,108,"#FFFFFF",22,"#DCE7DF"); text(x+25,ay+384,"Tus datos quedan con vos.",13,INK,True)
text(x+25,ay+413,"Hasta 50 lecturas guardadas en el iPhone.\nPodés borrarlas o desactivar el historial.",11,MUTED,spacing=1.55)
tabs(998,1051,1)

for x,label,detail in [(74,"01 / Tu tarjeta","Inicio · modo claro"),(532,"02 / Acercá tu SUBE","Guía · modo oscuro"),(990,"03 / Tus lecturas","Historial · estado inicial")]:
 text(x,1161,label,13,INK,True); text(x+395,1164,detail,10,MUTED,anchor="rt")
line([(68,1211),(1391,1211)],"#CBD9CE")
text(69,1231,"Maqueta visual. No es una captura del simulador ni una lectura NFC real.",11,MUTED)
text(1390,1231,"Pulso 0.1 · App independiente de SUBE",11,MUTED,anchor="rt")

out=ROOT/"docs/design/Pulso-design-preview.png"
im.resize((W,H),Image.Resampling.LANCZOS).save(out,optimize=True)
print(out)
