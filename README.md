# 🥊 Ultimate DCC Fighting

![Godot Engine](https://img.shields.io/badge/Godot-4.x-478CBF?style=for-the-badge&logo=godot-engine&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Status](https://img.shields.io/badge/Status-Em%20Desenvolvimento-orange?style=for-the-badge)

Um jogo de luta 2D arcade inspirado em clássicos como **MUGEN** e **Street Fighter**, desenvolvido na **Godot Engine**. O elenco coloca os icônicos professores do **Departamento de Ciência da Computação (DCC)** em combates frenéticos, cada um equipado com habilidades especiais únicas e temáticas!

---

## 🎯 Objetivo do Trabalho

Este projeto é o **Trabalho 2** desenvolvido para a disciplina de desenvolvimento de jogos do DCC/UFJF. O objetivo é aplicar na prática os recursos da **Godot Engine** vistos em aula (cenas e nós, sinais, containers e temas de interface, animações, autoloads e física 2D) na construção de um jogo completo: menu inicial, seleção de personagens, combate entre dois jogadores no mesmo teclado, tela de fim de luta com revanche, instruções e créditos.

---

## 🎮 Elenco de Lutadores

Todos os personagens compartilham os movimentos básicos (andar, pular, soco e chute), mas possuem atributos balanceados individualmente e ataques especiais exclusivos:

| Professor | Especial | Estilo de Golpe |
| :--- | :--- | :--- |
| **Caniato** | 🤖 **Ataque Robótico** | Invoca um robô que surge correndo de trás dele e voa em direção ao oponente. |
| **Stroele** | 🪑 **Cadeirada Brutal** | Um golpe corpo a corpo devastador utilizando um banco/cadeira. |
| **Knop** | ⚡ **Feixe de Energia** | Dispara um raio contínuo de energia pura (estilo *Kamehameha*). |
| **Gleiph** | ❓ **Em Desenvolvimento** | Habilidade especial exclusiva em fase de definição. |

---

## ⚔️ Mecânicas de Combate

* **Sistema de Combos (Janela de `0.35s`):** Acertar golpes em sequência permite encadear finalizadores com multiplicador de **1.2x de dano**:
  * `Soco > Soco > Soco`: Sequência rápida com dano focado no último golpe.
  * `Soco > Soco > Chute`: Controle de espaço que aplica *knockback* e afasta o adversário.
  * `Soco > Soco > Baixo + Soco`: **Uppercut (Launcher)** que lança ambos os lutadores ao ar, permitindo um ataque aéreo adicional.
* **Barra de Especial (Meter):** Enche progressivamente durante a luta e libera o ataque especial ao atingir **100%**. Para equilibrar a disputa, o lutador que recebe dano carrega a barra **1,1x (10%) mais rápido** do que quem está batendo.

---

## 👥 Equipe

Nina Aguiar · Gustavo Bersan · Ítalo Fagundes · Arthur Marques

Agradecimentos aos professores Caniato, Gleiph, Victor e Igor.

---

## 🎵 Créditos

* **Músicas e efeitos sonoros:** [Pixabay](https://pixabay.com/pt/sound-effects/search/game%20menu%20mortal%20kombat/) (Licença Pixabay)
* **Fonte:** [Pixel Operator](https://www.dafont.com/pixel-operator.font), de Jayvee Enaguas (CC0)
