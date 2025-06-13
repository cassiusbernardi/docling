# Use uma imagem base Python com Bookworm (Debian 12)
FROM python:3.11-slim-bookworm

# Definir o diretório de trabalho dentro do contêiner
WORKDIR /app

# Configurar o ambiente para evitar prompts SSH e otimizar downloads
ENV GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"
ENV HF_HOME=/tmp/
ENV TORCH_HOME=/tmp/
ENV OMP_NUM_THREADS=4 # Para evitar congestionamento de threads em ambientes de contêiner

# Instalar dependências de sistema necessárias (libgl, libglib, curl, wget, git, procps)
# Adicione 'poetry' aqui também, pois o Docling usa-o para gerenciamento de dependências.
RUN apt-get update \
    && apt-get install -y libgl1 libglib2.0-0 curl wget git procps poetry \
    && rm -rf /var/lib/apt/lists/*

# Copiar os arquivos de definição de dependência do Docling (pyproject.toml, poetry.lock)
# Isso deve estar na raiz do seu repositório Docling
COPY pyproject.toml poetry.lock ./

# Instalar as dependências Python usando poetry
# --no-root: não instala o próprio pacote docling como um pacote editável
# --no-dev: não instala dependências de desenvolvimento
# --no-interaction --no-ansi: para evitar prompts interativos durante o build
RUN poetry install --no-root --no-dev --no-interaction --no-ansi

# Copiar o restante do código da aplicação Docling para o diretório de trabalho
# O '.' no final significa copiar tudo do contexto de build (sua raiz do repo) para /app
COPY . .

# Baixar os modelos do Docling (como EasyOCR e outros)
# Isso usa o poetry para rodar o comando docling-tools
RUN poetry run docling-tools models download

# Expor a porta em que a API Docling vai escutar
EXPOSE 8000

# Comando para iniciar o servidor Docling usando Uvicorn e poetry
# 'docling.app:app' é o módulo e a instância do aplicativo FastAPI
# --host 0.0.0.0 permite que o contêiner escute em todas as interfaces de rede
# --port 8000 define a porta de escuta
CMD ["poetry", "run", "uvicorn", "docling.app:app", "--host", "0.0.0.0", "--port", "8000"]

# As linhas abaixo são comentários do Dockerfile original e não são mais necessárias
# para o deploy da API, mas são úteis para entendimento:
# On container shell:
# > cd /root/
# > python minimal.py
# Running as `docker run -e DOCLING_ARTIFACTS_PATH=/root/.cache/docling/models` will use the
# model weights included in the container image.
