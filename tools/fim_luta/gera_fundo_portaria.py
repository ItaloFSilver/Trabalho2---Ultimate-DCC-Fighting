"""Gera o fundo da tela de fim de luta: portaria da UFJF à noite, pixel art 320x180.
Uso: python3 tools/fim_luta/gera_fundo_portaria.py   (requer Pillow e numpy)
Saída: assets/ui/fim_luta/fundo_portaria.png"""
import os, colorsys, random
from collections import deque
import numpy as np
from PIL import Image, ImageFilter

AQUI = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(AQUI, 'portaria_foto.png')
SAIDA = os.path.join(AQUI, '..', '..', 'assets', 'ui', 'fim_luta', 'fundo_portaria.png')
W, H = 320, 180
CROP_Y = 40                      # recorte 16:9 da foto (640x360 a partir de y=40)
random.seed(11)

src = Image.open(SRC).convert('RGB')
a = np.asarray(src).astype(int)
SH, SW = a.shape[:2]

# --- máscara do céu: azul ou nuvem, ligado ao topo ---
r_, g_, b_ = a[..., 0], a[..., 1], a[..., 2]
bri = a.mean(2); sat = a.max(2) - a.min(2)
ceu_ok = ((b_ > r_ + 25) & (b_ >= g_)) | ((bri > 175) & (sat < 70))
sky = np.zeros_like(ceu_ok)
q = deque((0, x) for x in range(SW) if ceu_ok[0, x])
for p in q: sky[p] = True
while q:
    y, x = q.popleft()
    for dy, dx in ((1,0),(-1,0),(0,1),(0,-1)):
        ny, nx = y+dy, x+dx
        if 0 <= ny < SH and 0 <= nx < SW and ceu_ok[ny,nx] and not sky[ny,nx] and ny < 300:
            sky[ny,nx] = True; q.append((ny,nx))

atras = np.zeros_like(sky)
atras[225:300, 355:505] = True
fundo_claro = atras & (bri > 140)
# nuvens/céu vistos entre galhos (não ligados ao topo)
yy0, xx0 = np.mgrid[0:SH, 0:SW]
borda_marquise = 250 - 0.17*(xx0 - 80) - 8     # topo das lajes do lado esquerdo
sky |= ceu_ok & (((xx0 < 370) & (yy0 < borda_marquise)) | ((xx0 >= 370) & (yy0 < 150)))

def reduz(arr):
    im = Image.fromarray(arr[CROP_Y:CROP_Y+360].astype(np.uint8))
    return np.asarray(im.resize((W, H), Image.BOX)).astype(float)

foto = reduz(a)
skym = reduz(sky*255)[...,0] > 128 if reduz(sky*255).ndim == 3 else reduz(sky*255) > 128

# --- céu noturno (degradê com dither Bayer, estrelas, lua) ---
bayer = np.array([[0,8,2,10],[12,4,14,6],[3,11,1,9],[15,7,13,5]])/16
top = np.array([6,8,20]); bot = np.array([34,30,62])
ceu = np.zeros((H, W, 3))
for y in range(H):
    t = min(1, y/90)
    for x in range(W):
        tt = min(1, max(0, t + (bayer[y%4, x%4]-0.5)*0.12))
        ceu[y,x] = top*(1-tt) + bot*tt
for _ in range(80):
    x, y = random.randrange(W), random.randrange(0, 75)
    ceu[y,x] = random.choice([(150,150,190),(200,200,230),(110,110,150)])
for x, y in [(30,12),(118,8),(232,20),(300,40)]:
    ceu[y,x] = (235,235,255)
    for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)): ceu[y+dy,x+dx] = (120,120,170)
mx, my, rr = 46, 30, 8          # lua do lado esquerdo (no menu ela fica à direita)
for y in range(my-rr-2, my+rr+3):
    for x in range(mx-rr-2, mx+rr+3):
        d = ((x-mx)**2+(y-my)**2)**.5; d2 = ((x-mx-4)**2+(y-my+2)**2)**.5
        if d <= rr and d2 > rr-1: ceu[y,x] = (232,226,190)
        elif d <= rr+1.5 and d2 > rr-1: ceu[y,x] = ceu[y,x]*0.6 + np.array([90,90,120])*0.4

# --- noite na foto ---
noite = np.zeros_like(foto)
for y in range(H):
    for x in range(W):
        r, g, b = foto[y,x]/255
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        if (h < 0.06 or h > 0.92) and s > 0.15:      # viga vinho e tijolos
            l2, s2 = l*0.55, min(1, s*1.2)
        elif 0.10 < h < 0.18 and s > 0.5 and 118 <= x <= 138 and 140 <= y <= 152:  # placa amarela
            l2, s2 = l*0.6, s
        elif 0.10 < h < 0.45 and s > 0.10:           # vegetação (inclui folhas amareladas)
            l2, s2 = l*0.28, s*0.6; h = h*0.7 + 0.42*0.3
        else:                                         # concreto, asfalto, vidro
            l2, s2 = l*0.36, 0.26; h = 0.65
        rr2, gg2, bb2 = colorsys.hls_to_rgb(h, l2, s2)
        noite[y,x] = (rr2*255, gg2*255, bb2*255)
img = np.where(skym[...,None], ceu, noite)
fc = reduz(fundo_claro*255); fc = (fc[...,0] if fc.ndim == 3 else fc)/255
img = img*(1-fc[...,None]) + np.array([22,24,40])*fc[...,None]

# --- luzes (coordenadas na foto original) ---
def caixa_para_tela(x0, y0, x1, y1):
    return x0*W/SW, (y0-CROP_Y)*H/360, x1*W/SW, (y1-CROP_Y)*H/360
luz = np.zeros(a.shape[:2])  # (só para o brilho em volta)
for x0,y0,x1,y1,k in [(272,297,300,360,1.0), (312,295,355,360,0.85), (160,330,176,341,0.8)]:
    reg = a[y0:y1, x0:x1]
    moldura = reg.mean(2) < 45                       # caixilhos escuros
    luz[y0:y1, x0:x1] = np.where(moldura, 0.15, 1.0) * k
for x in range(272, 300, 9): luz[297:360, x:x+2] *= 0.2
for x in range(312, 355, 10): luz[295:360, x:x+2] *= 0.2
lm = reduz(luz*255)
lm = (lm[...,0] if lm.ndim == 3 else lm)/255
quente = np.array([242,196,92])


# luminárias sob a marquise + poças de luz no chão
brilho = np.zeros((H, W))
for ox, oy in [(417,246),(475,236),(532,226)]:
    tx, ty = ox*W/SW, (oy-CROP_Y)*H/360
    ix, iy = int(round(tx)), int(round(ty))
    img[iy, ix-1:ix+2] = (255,240,190)
    yy, xx = np.mgrid[0:H, 0:W]
    brilho += np.exp(-(((xx-tx)/7)**2 + ((yy-ty-2)/4)**2))
    chao_y = 158
    brilho += 0.5*np.exp(-(((xx-tx)/14)**2 + ((yy-chao_y)/3)**2)) * (yy > 150)
# brilho da guarita
yy, xx = np.mgrid[0:H, 0:W]
brilho += 0.45*np.exp(-(((xx-152)/18)**2 + ((yy-150)/14)**2))
img = img + np.array([70,48,14])*np.clip(brilho,0,1.2)[...,None]*0.7

# vinheta + base escurecida (área das opções)
v = 1 - 0.45*(((xx-W/2)/(W/2))**2*0.6 + ((yy-H*0.45)/(H*0.6))**2*0.8)
img = img*np.clip(v, 0.45, 1)[...,None]
img = img*(1 - np.clip((yy-120)/60, 0, 1)*0.35)[...,None]

im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
im = im.quantize(colors=32, method=Image.MEDIANCUT, dither=Image.NONE).convert('RGB')
q = np.asarray(im).astype(float)
QUENTE, QUENTE2, CAIXILHO = (242,198,96), (205,150,64), (40,28,24)
def vidraca(x0, y0, x1, y1, passo, travessas=True):
    """Vidro aceso com caixilhos (coordenadas na tela 320x180).
    travessas=False tira as barras horizontais (em janela pequena elas viram um "=")."""
    for y in range(y0, y1):
        for x in range(x0, x1):
            borda = x == x0 or x == x1-1 or y == y0 or y == y1-1
            horiz = travessas and y in (y0 + (y1-y0)//3, y0 + 2*(y1-y0)//3)
            caix = (x - x0) % passo == 0 or horiz
            q[y, x] = CAIXILHO if (borda or caix) else (QUENTE if y < y0 + (y1-y0)//3 or (x+y) % 7 else QUENTE2)
vidraca(136, 129, 150, 160, 5)      # guarita (vidro esquerdo)
vidraca(156, 128, 178, 160, 6)      # porta de vidro
vidraca(81, 145, 88, 151, 99, travessas=False)  # guarita pequena à esquerda
# painel com o brasão da UFJF (desenhado à mão)
CREME, CREME2, VINHO = (214,198,160), (178,160,124), (92,30,36)
for y in range(108, 128):
    for x in range(136, 150):
        q[y, x] = CREME2 if x in (136, 149) or y in (108, 127) else CREME
ESCUDO = ["..#..",
          ".###.",
          "#####",
          "#####",
          "#####",
          ".###.",
          "..#.."]
for dy, linha in enumerate(ESCUDO):
    for dx, c in enumerate(linha):
        if c == '#': q[113+dy, 141+dx] = VINHO
im = Image.fromarray(q.astype(np.uint8))
os.makedirs(os.path.dirname(SAIDA), exist_ok=True)
im.save(SAIDA)
print('ok', SAIDA)
