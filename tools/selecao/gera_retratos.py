"""Gera as imagens da seleção de personagem a partir dos sprite sheets.

Os sheets (tools/selecao/<nome>_sheet.jpg) estão ampliados ~6,22x e em JPEG.
O script volta cada um para a grade original (1 pixel por quadrado), recorta o
primeiro quadro parado, remove o fundo cinza e limpa as cores.

Uso: python3 tools/selecao/gera_retratos.py   (requer Pillow, numpy e scipy)
Saída: assets/ui/selecao/<id>.png
"""
import os
from collections import deque
import numpy as np
from PIL import Image
from scipy import ndimage

AQUI = os.path.dirname(os.path.abspath(__file__))
SAIDA = os.path.join(AQUI, '..', '..', 'assets', 'ui', 'selecao')
# (nome do sheet, id do personagem no jogo) — Igor = Knop, Victor = Stroele
NOMES = [('caniato', 'caniato'), ('gleiph', 'gleiph'), ('igor', 'knop'), ('victor', 'stroele')]
ESCALA = 1194 / 192            # sheet de 1194 px de largura = 192 px originais
RECORTE = (10, 5, 41, 50)      # área do 1º quadro (idle) na grade original


def melhor_deslocamento(a):
    melhor = None
    H, W = a.shape[:2]
    for ox in np.arange(0, ESCALA, 0.25):
        for oy in np.arange(0, ESCALA, 0.25):
            xs = np.arange(ox + ESCALA / 2, W, ESCALA).astype(int)
            ys = np.arange(oy + ESCALA / 2, H, ESCALA).astype(int)
            peq = a[ys][:, xs]
            xi = np.clip(((np.arange(W) - ox) // ESCALA).astype(int), 0, len(xs) - 1)
            yi = np.clip(((np.arange(H) - oy) // ESCALA).astype(int), 0, len(ys) - 1)
            erro = np.abs(peq[yi][:, xi] - a).mean()
            if melhor is None or erro < melhor[0]:
                melhor = (erro, ox, oy)
    return melhor[1], melhor[2]


def para_grade_original(caminho):
    a = np.asarray(Image.open(caminho).convert('RGB')).astype(float)
    ox, oy = melhor_deslocamento(a[0:320, 0:320])
    H, W = a.shape[:2]
    cols, rows = int((W - ox) // ESCALA), int((H - oy) // ESCALA)
    out = np.zeros((rows, cols, 3))
    for j in range(rows):
        for i in range(cols):
            cx, cy = ox + (i + 0.5) * ESCALA, oy + (j + 0.5) * ESCALA
            bloco = a[int(cy) - 1:int(cy) + 2, int(cx) - 1:int(cx) + 2].reshape(-1, 3)
            out[j, i] = np.median(bloco, 0)       # mediana tira o ruído do JPEG
    return out.astype(np.uint8)


def recorta_idle(nativo):
    a = np.asarray(Image.fromarray(nativo).crop(RECORTE)).astype(int)
    H, W = a.shape[:2]
    borda = np.concatenate([a[0], a[-1], a[:, 0], a[:, -1]])
    fundo = np.median(borda, 0)
    perto = np.abs(a - fundo).sum(2) < 45
    fora = np.zeros((H, W), bool)
    fila = deque((y, x) for y in range(H) for x in (0, W - 1) if perto[y, x])
    fila.extend((y, x) for x in range(W) for y in (0, H - 1) if perto[y, x])
    for p in fila:
        fora[p] = True
    while fila:                                    # flood fill do fundo pelas bordas
        y, x = fila.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < H and 0 <= nx < W and perto[ny, nx] and not fora[ny, nx]:
                fora[ny, nx] = True
                fila.append((ny, nx))
    rot, n = ndimage.label(~fora)                  # só o maior pedaço (o personagem)
    if n > 1:
        tam = ndimage.sum(np.ones_like(rot), rot, range(1, n + 1))
        fora = rot != (np.argmax(tam) + 1)
    cores = Image.fromarray(a.astype(np.uint8)).quantize(
        colors=32, method=Image.MEDIANCUT, dither=Image.NONE).convert('RGB')
    rgba = np.dstack([np.asarray(cores), np.where(fora, 0, 255)]).astype(np.uint8)
    ys, xs = np.where(~fora)
    return Image.fromarray(rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1], 'RGBA')


if __name__ == '__main__':
    os.makedirs(SAIDA, exist_ok=True)
    for sheet, nome in NOMES:
        img = recorta_idle(para_grade_original(os.path.join(AQUI, f'{sheet}_sheet.jpg')))
        img.save(os.path.join(SAIDA, f'{nome}.png'))
        print(nome, img.size)
