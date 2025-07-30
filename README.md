# speedtest-full.sh

Linux

Faz um teste de velocidade completo usando o speedtest da Ookla.

```txt
Uso:
   ./speedtest-full.sh [download] [upload]

Exemplos:
   ./speedtest-full.sh 500 500
   ./speedtest-full.sh 500
```

Mas para isso precisa ter instalado o teste de velocidade, da seguinte forma (compatível com a maioria das distros):

```shell
cd ~

# Baixa o pacote .tgz oficial para x86_64
wget -O speedtest.tgz https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz

# Extrai o pacote
tar -xvzf speedtest.tgz

# Move o binário para /usr/local/bin
sudo mv speedtest /usr/local/bin/

# Garante permissão de execução (só por segurança)
sudo chmod +x /usr/local/bin/speedtest

# Apaga quaisquer resquicios dos arquivos baixados
rm ~/speedtest*

# Limpa o cache e Verifica se obinário está acessível
hash -r
which speedtest

# Exibe a versão para confirmar
speedtest --version

```

Opcionalmente, caso queira criar o comando, basta criar um link simbolico em /usr/bin:

```shell
sudo ln -s /caminho/completo/do/speedtest-full.sh /usr/bin/speedtest-full
```

Dessa froma, de qualquer pasta, você poderá executar:

```txt
Uso:
   speedtest-full [download] [upload]

Exemplos:
   speedtest-full 500 500
   speedtest-full 500
```

> **Obs**.: Um arquivo de log com o nome `speedtest.log` será criada na sua área de usuario.
