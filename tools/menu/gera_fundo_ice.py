"""Gera o fundo do menu: prédio do ICE à noite, pixel art 320x180.
Uso: python3 tools/menu/gera_fundo_ice.py   (requer Pillow e numpy)
Saída: assets/ui/menu/fundo_ice.png"""
from PIL import Image, ImageFilter
import numpy as np, colorsys, random, sys
from collections import deque

W, H = 320, 180
import os
AQUI = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(AQUI, 'ice_foto.png')
SAIDA = os.path.join(AQUI, '..', '..', 'assets', 'ui', 'menu', 'fundo_ice.png')
OFF_Y = int(sys.argv[1]) if len(sys.argv) > 1 else 10   # px de céu gerado acima da foto
random.seed(7); rng = np.random.default_rng(7)

src = Image.open(SRC).convert('RGB')
s = W / src.width
ph = int(src.height * s)
foto = src.resize((W, ph), Image.LANCZOS)
a = np.asarray(src).astype(int)

# máscara do céu: flood fill a partir do topo em pixels claros
bri = a.mean(2); sat = a.max(2) - a.min(2)
ok = (bri > 236) & (sat < 30)
sky = np.zeros_like(ok)
q = deque((0, x) for x in range(src.width) if ok[0, x])
for p in q: sky[p] = True
while q:
    y, x = q.popleft()
    for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
        ny, nx = y+dy, x+dx
        if 0 <= ny < src.height and 0 <= nx < src.width and ok[ny,nx] and not sky[ny,nx]:
            sky[ny,nx] = True; q.append((ny,nx))
skym = np.asarray(Image.fromarray((sky*255).astype(np.uint8)).resize((W, ph), Image.BOX)) > 128

# canvas
out = np.zeros((H, W, 3), float)
skymask = np.ones((H, W), bool)
f = np.asarray(foto).astype(float)
for y in range(H):
    sy = y - OFF_Y
    if 0 <= sy < ph:
        out[y] = f[sy]; skymask[y] = skym[sy]

# --- céu noturno com dither (bayer 4x4) ---
bayer = np.array([[0,8,2,10],[12,4,14,6],[3,11,1,9],[15,7,13,5]])/16
top = np.array([6,8,20]); bot = np.array([34,30,62])
sky_img = np.zeros((H, W, 3))
for y in range(H):
    t = min(1, y / 75)
    for x in range(W):
        tt = t + (bayer[y%4, x%4]-0.5)*0.12
        tt = min(1, max(0, tt))
        sky_img[y, x] = top*(1-tt) + bot*tt
# estrelas
for _ in range(70):
    x, y = random.randrange(W), random.randrange(0, 60)
    c = random.choice([(150,150,190),(200,200,230),(110,110,150)])
    sky_img[y, x] = c
for x, y in [(41,9),(270,14),(205,6),(120,22)]:  # estrelas maiores (cruz)
    sky_img[y,x] = (235,235,255)
    for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)): sky_img[y+dy,x+dx] = (120,120,170)
# lua
mx, my, r = 278, 26, 8
for y in range(my-r-1, my+r+2):
    for x in range(mx-r-1, mx+r+2):
        d = ((x-mx)**2+(y-my)**2)**.5
        d2 = ((x-mx+4)**2+(y-my+2)**2)**.5
        if d <= r and d2 > r-1: sky_img[y,x] = (232,226,190)
        elif d <= r+1.5 and d2 > r-1: sky_img[y,x] = sky_img[y,x]*0.6 + np.array([90,90,120])*0.4

# --- noite na parte da foto ---
night = np.zeros_like(out)
for y in range(H):
    for x in range(W):
        r_, g_, b_ = out[y,x]/255
        h, l, sa = colorsys.rgb_to_hls(r_, g_, b_)
        orange = (h < 0.08 or h > 0.95) and sa > 0.25
        green = 0.15 < h < 0.45 and sa > 0.12
        if orange:      l2, s2 = l*0.50, min(1, sa*1.25)
        elif green:     l2, s2 = l*0.30, sa*0.65; h = h*0.7 + 0.42*0.3
        else:           l2, s2 = l*0.27, 0.30; h = 0.65   # concreto/vidro -> azul-acinzentado
        rr, gg, bb = colorsys.hls_to_rgb(h, l2, s2)
        night[y,x] = (rr*255, gg*255, bb*255)

img = np.where(skymask[...,None], sky_img, night)

# janelas acesas: retângulos marcados à mão na foto original (x0,y0,x1,y1, brilho)
JANELAS = [
    (428,175,470,265, 1.00), (542,180,578,285, 1.00),   # vidraças ao lado da torre
    (423,140,475,172, 0.55), (542,142,588,180, 0.55),   # claraboias do arco
    (100,287,172,330, 0.80), (100,355,172,385, 0.70),   # varandas à esquerda
    (0,305,82,345, 0.85),                               # prédio da esquerda
    (542,297,575,330, 0.90), (600,300,625,330, 0.75), (602,362,645,388, 0.80),
]
alpha = np.zeros(a.shape[:2]); 
for x0,y0,x1,y1,k in JANELAS:
    reg = a[y0:y1, x0:x1]
    r_, g_, b_ = reg[...,0], reg[...,1], reg[...,2]
    arvore = (g_ > r_+6) & (g_ > b_+2)
    moldura = reg.mean(2) > 205
    al = np.where(arvore, 0, np.where(moldura, 0.15, 1.0)) * k
    alpha[y0:y1, x0:x1] = np.maximum(alpha[y0:y1, x0:x1], al)
# janelinhas quadradas da fachada (fileiras)
for y0 in (302, 358):
    for x0 in range(184, 345, 17):
        reg = a[y0:y0+8, x0:x0+9]
        if ((reg[...,1] > reg[...,0]+6)).mean() < 0.3:
            alpha[y0:y0+8, x0:x0+9] = np.where((reg[...,1] > reg[...,0]+6), 0, 0.9)
# caixilhos (grade escura) nas vidraças grandes
for x0,y0,x1,y1,k in JANELAS[:2] + JANELAS[7:]:
    for x in range(x0, x1, 12): alpha[y0:y1, x:x+3] *= 0.15
    for y in range(y0, y1, 22): alpha[y:y+3, x0:x1] *= 0.15
am = np.asarray(Image.fromarray((alpha*255).astype(np.uint8)).resize((W, ph), Image.BOX))/255
lit = np.zeros((H, W)); 
for y in range(H):
    sy = y - OFF_Y
    if 0 <= sy < ph: lit[y] = am[sy]
quente = np.array([242,196,92]); 
img = img*(1-lit[...,None]) + (quente*(0.62+0.38*lit[...,None]))*lit[...,None]
# brilho leve em volta das janelas
glow = np.asarray(Image.fromarray((lit*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3)))/255
img = img + np.array([60,40,10])*glow[...,None]*0.6
# vinheta
yy, xx = np.mgrid[0:H, 0:W]
v = 1 - 0.45*(((xx-W/2)/(W/2))**2*0.6 + ((yy-H*0.45)/(H*0.6))**2*0.8)
img = img * np.clip(v, 0.45, 1)[...,None]
# escurece a base (área das opções)
grad = np.clip((yy - 100) / 80, 0, 1) * 0.35
img = img * (1 - grad)[...,None]

im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
# posteriza para paleta limitada (visual pixel art)
im = im.quantize(colors=32, method=Image.MEDIANCUT, dither=Image.NONE).convert('RGB')
q = np.asarray(im).copy()
# letreiro ICE na torre, desenhado à mão (pixel font 3x5)
SIGN = {"I":["111","010","010","010","111"],"C":["111","100","100","100","111"],"E":["111","100","110","100","111"]}
cx, cy = 159, 90
creme = np.array([238,232,210])
for i,ch in enumerate("ICE"):
    for dy,row in enumerate(SIGN[ch]):
        for dx,c in enumerate(row):
            if c=="1": q[cy+dy, cx+i*4+dx] = creme
for dx,dy in ((5,-3),(4,-2),(6,-2),(3,-1),(7,-1)):   # telhadinho do logo
    q[cy+dy-1, cx+dx] = creme
im = Image.fromarray(q)

im.save(SAIDA)
print('ok')
