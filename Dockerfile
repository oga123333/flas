# Use Python 3.11 as base image
FROM python:3.13-slim

# Set working directory
WORKDIR /app

# 1. Install system dependencies
# - curl/xz-utils: for FFmpeg
# - unzip: for Deno
# - nodejs: REQUIRED backup JS runtime
# - build-essential/python3-dev: often needed for compiling yt-dlp[default] dependencies
RUN apt-get update && apt-get install -y \
    curl \
    xz-utils \
    unzip \
    nodejs \
    build-essential \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Create local bin directory
RUN mkdir -p /app/bin

# 2. Install FFmpeg (BtbN Static Build with SVT-AV1)
RUN curl -L -o /app/bin/ffmpeg.tar.xz https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz && \
    tar -xf /app/bin/ffmpeg.tar.xz -C /app/bin --strip-components=2 --wildcards "*/bin/ffmpeg" "*/bin/ffprobe" && \
    rm /app/bin/ffmpeg.tar.xz

# 3. Install Deno (Primary JS runtime for yt-dlp)
RUN curl -fsSL https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip -o deno.zip && \
    unzip deno.zip && \
    mv deno /app/bin/deno && \
    rm deno.zip && \
    chmod +x /app/bin/deno

# 4. Set Permissions and PATH
RUN chmod +x /app/bin/ffmpeg /app/bin/ffprobe
ENV PATH="/app/bin:${PATH}"

# 5. Install Python dependencies (UPDATED)
# - Upgrades pip
# - Installs requirements.txt
# - Forces install of the latest NIGHTLY yt-dlp with optional dependencies
# - Installs gunicorn
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir -U "yt-dlp[default]" --pre && \
    pip install --no-cache-dir gunicorn

# 6. Copy Application Code
COPY . .

# Create downloads folder
RUN mkdir -p downloads

# Expose port
EXPOSE 5000

# Start command
CMD ["gunicorn", "app:app", "--workers", "1", "--threads", "8", "--timeout", "0", "--bind", "0.0.0.0:5000"]
