"""Retrato da seleção do Stroele a partir do asset novo (tools/selecao/stroele_novo.png).

A imagem é um único quadro de 1024x1024, com pixels de ~21 px. O script volta para a
grade original (36 px de altura, mediana do centro de cada célula), remove o fundo
cinza, limpa pixels cinza soltos na borda, reduz a 32 cores e aplica alguns
retoques à mão (contorno das pernas e o olho direito).

Uso: python3 tools/selecao/gera_retrato_stroele.py   (requer Pillow, numpy e scipy)
Saída: assets/ui/selecao/stroele.png
"""
import os
from collections import deque
import numpy as np
from PIL import Image
from scipy import ndimage

AQUI = os.path.dirname(os.path.abspath(__file__))
FONTE = os.path.join(AQUI, 'stroele_novo.png')
SAIDA = os.path.join(AQUI, '..', '..', 'assets', 'ui', 'selecao', 'stroele.png')
CAIXA = (316, 124, 768, 880)   # área do personagem na imagem
ALTURA = 36                    # altura em pixels de pixel art

a = np.asarray(Image.open(FONTE).convert('RGB')).astype(float)
fundo = a[5, 5]
x0, y0, x1, y1 = CAIXA
s = (y1 - y0 + 1) / ALTURA
cols = int(round((x1 - x0 + 1) / s))
out = np.zeros((ALTURA, cols, 3))
for j in range(ALTURA):
    for i in range(cols):
        cx, cy, r = x0 + (i + 0.5) * s, y0 + (j + 0.5) * s, max(2, int(s * 0.2))
        out[j, i] = np.median(a[int(cy) - r:int(cy) + r + 1, int(cx) - r:int(cx) + r + 1].reshape(-1, 3), 0)

out = np.pad(out, ((1, 1), (1, 1), (0, 0)), mode='edge')
out[0, :] = out[-1, :] = out[:, 0] = out[:, -1] = fundo
H, W = out.shape[:2]
perto = np.abs(out - fundo).sum(2) < 45
fora = np.zeros((H, W), bool)
fila = deque((y, x) for y in range(H) for x in range(W) if (y in (0, H - 1) or x in (0, W - 1)) and perto[y, x])
for p in fila:
    fora[p] = True
while fila:
    y, x = fila.popleft()
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ny, nx = y + dy, x + dx
        if 0 <= ny < H and 0 <= nx < W and perto[ny, nx] and not fora[ny, nx]:
            fora[ny, nx] = True
            fila.append((ny, nx))
rot, n = ndimage.label(~fora)
if n > 1:
    tam = ndimage.sum(np.ones_like(rot), rot, range(1, n + 1))
    fora = rot != (np.argmax(tam) + 1)

cores = Image.fromarray(out.astype(np.uint8)).quantize(colors=32, method=Image.MEDIANCUT, dither=Image.NONE).convert('RGB')
img = np.dstack([np.asarray(cores), np.where(fora, 0, 255)]).astype(np.uint8)

# remove pixels acinzentados (sobra do fundo) que ficaram na borda do personagem
for _ in range(3):
    opaco = img[..., 3] > 0
    for y in range(H):
        for x in range(W):
            if not opaco[y, x]:
                continue
            borda = any(not (0 <= y + dy < H and 0 <= x + dx < W) or not opaco[y + dy, x + dx]
                        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if borda and np.abs(img[y, x, :3].astype(int) - fundo).sum() < 90:
                img[y, x, 3] = 0

ys, xs = np.where(img[..., 3] > 0)
img = img[ys.min():ys.max() + 1, xs.min():xs.max() + 1].copy()

# retoques à mão (coordenadas x, y no retrato recortado)
CONTORNO = img[31, 2].copy()
for x, y in [(2, 29), (2, 30), (16, 29), (11, 29)]:   # contorno das pernas que saiu cinza/faltando
    img[y, x] = CONTORNO
img[11, 13] = img[11, 8]   # olho direito com 2 px de altura, igual ao esquerdo

Image.fromarray(img, 'RGBA').save(SAIDA)
print('ok', SAIDA)
