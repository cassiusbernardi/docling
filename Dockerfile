# Use uma imagem base Python com Bookworm (Debian 12)
FROM python:3.11-slim-bookworm

# Definir o diretório de trabalho dentro do contêiner
WORKDIR /app

# Configurar o ambiente para evitar prompts SSH e otimizar downloads
ENV GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"
ENV HF_HOME=/tmp/
ENV TORCH_HOME=/tmp/
# Para evitar congestionamento de threads em ambientes de contêiner.
ENV OMP_NUM_THREADS=4 

# Instalar dependências de sistema necessárias (libgl, libglib, curl, wget, git, procps)
# Adicionar build-essential para compiladores C/C++ e zlib1g-dev para compressão (muitas libs Python usam)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    curl \
    wget \
    git \
    procps \
    build-essential \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Instalar poetry separadamente via pip.
RUN pip install poetry

# Copiar APENAS o pyproject.toml para o diretório de trabalho.
COPY pyproject.toml ./

# Instalar as dependências Python usando poetry.
# O '--no-ansi' pode ser removido para ver as cores e facilitar a leitura, mas pode causar problemas em logs que não suportam ANSI. Vamos mantê-lo por enquanto.
RUN poetry install --no-root --no-dev --no-interaction --no-ansi

# Copiar o restante do código da aplicação Docling para o diretório de trabalho
COPY . .

# Baixar os modelos do Docling (como EasyOCR e outros)
RUN poetry run docling-tools models download

# Expor a porta em que a API Docling vai escutar
EXPOSE 8000

# Comando para iniciar o servidor Docling usando Uvicorn e poetry
CMD ["poetry", "run", "uvicorn", "docling.app:app", "--host", "0.0.0.0", "--port", "8000"]
