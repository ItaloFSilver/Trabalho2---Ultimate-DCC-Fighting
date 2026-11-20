"""Gera as imagens de texto do menu inicial (título e botões) em pixel art.

Uso: python3 tools/menu/gera_textos_menu.py   (requer Pillow e numpy)
Saída em assets/ui/menu/:
  titulo.png                      "ULTIMATE" + "DCC FIGHTING"
  botao_<id>.png                  opção não selecionada (amarelo apagado)
  botao_<id>_selecionado.png      opção selecionada (amarelo forte + seta)

Para mudar um texto, edite TITULO / OPCOES abaixo e rode de novo.
"""
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFont

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.normpath(os.path.join(AQUI, '..', '..'))
FONTES = os.path.join(RAIZ, 'assets', 'fonts')
SAIDA = os.path.join(RAIZ, 'assets', 'ui', 'menu')

FONTE_TITULO = 'PixelOperator8-Bold.ttf'
FONTE_OPCAO = 'PixelOperator-Bold.ttf'   # a versão "8" achata maiúsculas acentuadas (É)

# (texto, tamanho da fonte, deslocamento da sombra)  — tamanhos múltiplos do nativo
TITULO = [("ULTIMATE", 16, 2), ("DCC FIGHTING", 24, 2)]
TITULO_BASES = [26, 53]          # linha de base de cada linha, no espaço 320x180
OPCOES = [("jogar", "JOGAR"), ("creditos", "CRÉDITOS"), ("sair", "SAIR")]
TAM_OPCAO = 32

CONTORNO = (10, 8, 20)
AMARELO = ((255, 236, 120), (246, 178, 40))        # topo -> base
SOMBRA = (150, 70, 10)
SEL = ((255, 240, 130), (250, 190, 50))
APAGADO = ((170, 140, 70), (140, 105, 40))
SOMBRA_APAGADO = (40, 25, 10)
COR_SETA = (255, 220, 90)
LARG_SETA = 16                   # espaço reservado de cada lado do texto do botão


def _mascara(texto, fonte, tam, w, h, x, base):
    im = Image.new('L', (w, h))
    d = ImageDraw.Draw(im)
    d.fontmode = '1'            # sem antialiasing
    ft = ImageFont.truetype(os.path.join(FONTES, fonte), tam)
    d.text((x, base), texto, font=ft, fill=255, anchor='ls')
    return np.asarray(im) > 0


def _largura(texto, fonte, tam):
    ft = ImageFont.truetype(os.path.join(FONTES, fonte), tam)
    return int(ImageDraw.Draw(Image.new('L', (1, 1))).textlength(texto, font=ft))


def _pinta(rgba, m, cor, sombra, desloc):
    """Contorno escuro + sombra deslocada + preenchimento em degradê vertical."""
    sh = np.roll(np.roll(m, desloc, 0), desloc, 1)
    tudo = m | sh
    out = np.zeros_like(m)
    for a in (-1, 0, 1):
        for b in (-1, 0, 1):
            out |= np.roll(np.roll(tudo, a, 0), b, 1)
    rgba[out] = (*CONTORNO, 255)
    rgba[sh & ~m] = (*sombra, 255)
    ys = np.where(m)[0]
    y0, y1 = ys.min(), ys.max()
    for y, x in zip(*np.where(m)):
        k = (y - y0) / max(1, y1 - y0)
        c = np.array(cor[0]) * (1 - k) + np.array(cor[1]) * k
        rgba[y, x] = (*c.astype(int), 255)


def _recorta(rgba):
    a = rgba[..., 3] > 0
    ys, xs = np.where(a)
    return rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1], int(xs.min()), int(ys.min())


def gera_titulo():
    W, H = 320, 70
    rgba = np.zeros((H, W, 4), np.uint8)
    for (texto, tam, desl), base in zip(TITULO, TITULO_BASES):
        x = (W - _largura(texto, FONTE_TITULO, tam)) // 2
        m = _mascara(texto, FONTE_TITULO, tam, W, H, x, base)
        _pinta(rgba, m, AMARELO, SOMBRA, desl)
    rec, x0, y0 = _recorta(rgba)
    Image.fromarray(rec).save(os.path.join(SAIDA, 'titulo.png'))
    print(f'titulo.png {rec.shape[1]}x{rec.shape[0]}  posição no 320x180: ({x0}, {y0})')


def gera_botoes():
    alt = 30
    base = 24
    for ident, texto in OPCOES:
        lt = _largura(texto, FONTE_OPCAO, TAM_OPCAO)
        w = lt + 2 * LARG_SETA + 4
        x = LARG_SETA + 1
        m = _mascara(texto, FONTE_OPCAO, TAM_OPCAO, w, alt, x, base)
        # não selecionado
        rgba = np.zeros((alt, w, 4), np.uint8)
        _pinta(rgba, m, APAGADO, SOMBRA_APAGADO, 1)
        Image.fromarray(rgba).save(os.path.join(SAIDA, f'botao_{ident}.png'))
        # selecionado + seta ▶ à esquerda
        rgba = np.zeros((alt, w, 4), np.uint8)
        _pinta(rgba, m, SEL, SOMBRA, 1)
        seta = np.zeros((alt, w), bool)
        for r in range(7):
            larg = r + 1 if r < 4 else 7 - r
            seta[base - 13 + r * 2: base - 11 + r * 2, 2: 2 + larg * 2] = True
        borda = np.zeros_like(seta)
        for a in (-1, 0, 1):
            for b in (-1, 0, 1):
                borda |= np.roll(np.roll(seta, a, 0), b, 1)
        rgba[borda & ~seta] = (*CONTORNO, 255)
        rgba[seta] = (*COR_SETA, 255)
        Image.fromarray(rgba).save(os.path.join(SAIDA, f'botao_{ident}_selecionado.png'))
        print(f'botao_{ident}.png {w}x{alt}')


if __name__ == '__main__':
    os.makedirs(SAIDA, exist_ok=True)
    gera_titulo()
    gera_botoes()
