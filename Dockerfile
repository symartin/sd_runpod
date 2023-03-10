FROM runpod/stable-diffusion:base-v2.1 as build

WORKDIR /
RUN rm -rf /stable-diffusion
RUN mkdir stable-diffusion
ADD environment.yml /stable-diffusion/environment.yaml
WORKDIR /stable-diffusion
RUN conda update -n base -c defaults conda
RUN conda env create -f environment.yaml
SHELL ["conda", "run", "-n", "ldm", "/bin/bash", "-c"]

RUN conda install -c conda-forge conda-pack
RUN conda-pack --ignore-missing-files -n ldm -o /tmp/env.tar --ignore-editable-packages && \
    mkdir /venv && cd /venv && tar xf /tmp/env.tar && \
    rm /tmp/env.tar

RUN /venv/bin/conda-unpack

FROM debian:buster AS runtime

# Build with some basic utilities
RUN apt update && apt install -y \
    git openssh-server libglib2.0-0 libsm6 libxrender1 libxext6 ffmpeg wget curl &&\
    apt clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

WORKDIR /workspace

RUN git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
WORKDIR /workspace/stable-diffusion-webui
RUN git pull

RUN mkdir repositories; \
git clone https://github.com/CompVis/stable-diffusion.git repositories/stable-diffusion && \
git clone https://github.com/CompVis/taming-transformers.git repositories/taming-transformers && \
git clone https://github.com/sczhou/CodeFormer.git repositories/CodeFormer && \
git clone https://github.com/salesforce/BLIP.git repositories/BLIP && \
git clone https://github.com/crowsonkb/k-diffusion.git repositories/k-diffusion && \
git clone https://github.com/Stability-AI/stablediffusion.git  repositories/stable-diffusion-stability-ai && \
cd extensions && \
git clone https://github.com/d8ahazard/sd_dreambooth_extension.git && \
git clone https://github.com/yfszzx/stable-diffusion-webui-images-browser.git && \
git clone https://github.com/deforum-art/deforum-for-automatic1111-webui && \
git clone https://github.com/camenduru/stable-diffusion-webui-huggingface && \
git clone https://github.com/Extraltodeus/multi-subject-render.git && \
git clone https://github.com/zero01101/openOutpaint-webUI-extension.git && \
git clone https://github.com/7eu7d7/DreamArtist-sd-webui-extension.git && \
cd sd_dreambooth_extension && git fetch && cd .. && \
cd stable-diffusion-webui-images-browser && git fetch && cd ..

COPY --from=build /venv /venv
RUN rm /venv/bin/ffmpeg
COPY --from=build /models/v2-1_768-ema-pruned.ckpt /workspace/stable-diffusion-webui/models/Stable-diffusion/v2-1_768-ema-pruned.ckpt
COPY --from=build /models/v2-1_768-ema-pruned.yaml /workspace/stable-diffusion-webui/models/Stable-diffusion/v2-1_768-ema-pruned.yaml
COPY --from=build /root/.cache/huggingface /root/.cache/huggingface

SHELL ["/bin/bash", "-c"]
ENV PATH="${PATH}:/venv/bin"

RUN mkdir -p /root/.cache/huggingface
RUN mkdir -p /workspace/outputs

ADD ui-config.json /workspace/stable-diffusion-webui/ui-config.json
ADD relauncher.py .
ADD start.sh /start.sh
RUN chmod a+x /start.sh
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]
