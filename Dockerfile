FROM runpod/pytorch:3.10-2.0.0-117

SHELL ["/bin/bash", "-c"]

WORKDIR /workspace

# Install missing dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-utils zstd python3.10-venv git-lfs unzip && \
    apt clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash

# Install Python dependencies
COPY builder/requirements.txt /requirements.txt
RUN pip install --upgrade pip && \
    pip install -r /requirements.txt && \
    rm /requirements.txt

ADD workspace .

# Run the install script
COPY builder/install.py /workspace/install.py
RUN python -u /workspace/install.py
RUN rm /workspace/install.py

# Replace paths.py with the one that works with the new paths
RUN cd /workspace/sd/stable-diffusion-webui/modules && \
    wget -q -O paths.py https://raw.githubusercontent.com/TheLastBen/fast-stable-diffusion/main/AUTOMATIC1111_files/paths.py && \
    sed -i 's@/content/gdrive/MyDrive/sd/stablediffusion@/workspace/sd/stablediffusion@' /workspace/sd/stable-diffusion-webui/modules/paths.py

# Download the models
COPY builder/model_fetcher.sh /workspace/model_fetcher.sh
RUN sh /workspace/model_fetcher.sh
RUN rm /workspace/model_fetcher.sh

ENV DEBIAN_FRONTEND noninteractive

CMD [ "python", "-u", "/rp_handler.py" ]

ENV PYTHONUNBUFFERED=1
CMD python -u rp_handler.py
