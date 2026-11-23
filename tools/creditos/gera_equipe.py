"""Gera os sprites da equipe para os créditos (2 quadros cada: parado e acenando).

A imagem (tools/creditos/equipe.png) é pixel art ampliada 12,5x. Cada pessoa é
recortada, o fundo cinza é removido e a imagem é reduzida para que 1 pixel da arte
vire 3 pixels na tela (cerca de 180 px de altura).

O 2º quadro é feito na imagem original, antes da redução: a mão levantada inclina
para fora (a ponta dos dedos anda 2 pixels da arte, o pulso fica parado) e, no
Gustavo, o joinha sobe 1 pixel da arte.

Uso: python3 tools/creditos/gera_equipe.py   (requer Pillow, numpy e scipy)
Saída: assets/ui/creditos/<nome>_1.png e <nome>_2.png
"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage

AQUI = os.path.dirname(os.path.abspath(__file__))
FONTE = os.path.join(AQUI, 'equipe.png')
SAIDA = os.path.join(AQUI, '..', '..', 'assets', 'ui', 'creditos')
PIXEL_ARTE = 12.5                 # tamanho de 1 pixel da arte na imagem
FATOR = 3 / PIXEL_ARTE            # 1 pixel da arte = 3 px na tela
MARGEM = 32                       # folga à direita para a mão balançar

# colunas de cada pessoa na imagem e retângulo da mão levantada (x0, y0, x1, y1)
PESSOAS = {
    'nina':    ((70, 462),    (350, 400, 462, 490),   'inclina'),
    'gustavo': ((462, 830),   (715, 412, 805, 525),   'sobe'),
    'italo':   ((835, 1205),  (1095, 400, 1195, 495), 'inclina'),
    'arthur':  ((1205, 1590), (1485, 400, 1590, 500), 'inclina'),
}


def separa(a, fundo, x0, x1):
    reg = a[:, x0:x1]
    perto = np.abs(reg - fundo).sum(2) <= 30
    m = ndimage.binary_opening(~perto, iterations=1)
    rot, n = ndimage.label(m)
    tam = ndimage.sum(np.ones_like(rot), rot, range(1, n + 1))
    m = ndimage.binary_fill_holes(rot == (np.argmax(tam) + 1)) & ~perto
    rgba = np.dstack([reg, np.where(m, 255, 0)]).astype(np.uint8)
    return np.pad(rgba, ((0, 0), (0, MARGEM), (0, 0)))


def aceno(rgba, caixa, tipo, x_corte):
    x0, y0, x1, y1 = caixa
    x0 -= x_corte
    x1 -= x_corte
    novo = rgba.copy()
    mao = rgba[y0:y1, x0:x1].copy()
    novo[y0:y1, x0:x1, 3] = 0
    if tipo == 'inclina':
        linhas = y1 - y0
        for y in range(linhas):
            passos = round(2 * (1 - y / (linhas - 1)))            # 2, 1 ou 0 pixels da arte
            dx = int(round(passos * PIXEL_ARTE))
            src = mao[y]
            alvo = novo[y0 + y, x0 + dx:x1 + dx]
            visivel = src[:alvo.shape[0], 3:] > 0
            novo[y0 + y, x0 + dx:x0 + dx + alvo.shape[0]] = np.where(visivel, src[:alvo.shape[0]], alvo)
    else:
        dy = int(round(PIXEL_ARTE))
        novo[y0 - dy:y1 - dy, x0:x1] = np.where(mao[..., 3:] > 0, mao, novo[y0 - dy:y1 - dy, x0:x1])
        # repete a base da mão para não abrir buraco entre a mão e o braço
        base = mao[-dy:]
        novo[y1 - dy:y1, x0:x1] = np.where(base[..., 3:] > 0, base, novo[y1 - dy:y1, x0:x1])
    return novo


def reduz(rgba, fundo, caixa_util):
    ys0, ys1, xs0, xs1 = caixa_util
    rgba = rgba[ys0:ys1, xs0:xs1]
    arr = rgba.astype(float)
    al = arr[..., 3:] / 255
    pm = Image.fromarray(np.dstack([arr[..., :3] * al, arr[..., 3:]]).astype(np.uint8), 'RGBA')
    w, h = pm.size
    p = np.asarray(pm.resize((round(w * FATOR), round(h * FATOR)), Image.LANCZOS)).astype(float)
    rgb = np.clip(p[..., :3] / np.clip(p[..., 3:] / 255, 1e-6, 1), 0, 255)
    alpha = np.where(p[..., 3] > 128, 255, 0)
    # pixels da borda acinzentados (mistura com o fundo) viram contorno escuro
    op = alpha > 0
    borda = op & ~ndimage.binary_erosion(op)
    cinza = (np.abs(rgb - fundo).sum(2) < 120) & (rgb.max(2) - rgb.min(2) < 25)
    rgb[borda & cinza] = (18, 16, 20)
    return Image.fromarray(np.dstack([rgb, alpha]).astype(np.uint8), 'RGBA')


if __name__ == '__main__':
    os.makedirs(SAIDA, exist_ok=True)
    a = np.asarray(Image.open(FONTE).convert('RGB')).astype(int)
    fundo = a[5, 5]
    for nome, ((x0, x1), caixa, tipo) in PESSOAS.items():
        q1 = separa(a, fundo, x0, x1)
        q2 = aceno(q1, caixa, tipo, x0)
        # mesma área de recorte nos dois quadros, para a pessoa não "pular"
        op = (q1[..., 3] > 0) | (q2[..., 3] > 0)
        ys, xs = np.where(op)
        util = (ys.min(), ys.max() + 1, xs.min(), xs.max() + 1)
        for k, q in ((1, q1), (2, q2)):
            img = reduz(q, fundo, util)
            img.save(os.path.join(SAIDA, f'{nome}_{k}.png'))
        print(nome, img.size)
