# 🚀 XMRig Auto Installer & Configurator

![XMRig](https://img.shields.io/badge/XMRig-6.24.0-blue?style=flat-square)
![Ubuntu](https://img.shields.io/badge/OS-Ubuntu%2FDebian-orange?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

Este repositório contém um **script automatizado para instalar, compilar e configurar o XMRig** no Ubuntu/Debian. Ele gera automaticamente um `config.json` otimizado para mineração de Monero (XMR) usando CPU.

---

## ⚡ Funcionalidades

- Atualiza o sistema automaticamente (`apt update && apt upgrade`).  
- Instala todas as dependências necessárias: `git`, `cmake`, `libuv`, `libssl`, `libhwloc`.  
- Baixa a última versão do XMRig diretamente do GitHub.  
- Compila o XMRig usando todos os núcleos da CPU disponíveis.  
- Cria automaticamente um **config.json avançado e otimizado** para mineração CPU.  
- Configuração inclui: RandomX, huge pages, gerenciamento de threads, TLS na pool e logging detalhado.

---

## 🛠️ Pré-requisitos

- Ubuntu 20.04+ / Debian 10+  
- CPU compatível (x86_64 recomendado; ARM para Raspberry Pi também funciona com ajustes)  
- Acesso root (sudo)  
- Conexão à Internet para baixar dependências e XMRig

---

## 📥 Como usar

1. Clone este repositório:

```bash
git clone https://github.com/linux-ur/github-mining.git
cd xmrig-auto
```
```bash
sudo chmod +x install.sh
```
```bash
./install.sh
