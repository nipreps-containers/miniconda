# MIT License
#
# Copyright (c) 2022 The NiPreps Developers
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# Use Ubuntu 20.04 LTS
FROM ubuntu:jammy-20240125

# Make apt non-interactive
RUN echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/90circleci \
  && echo 'DPkg::Options "--force-confnew";' >> /etc/apt/apt.conf.d/90circleci
ARG DEBIAN_FRONTEND=noninteractive

# Prepare environment
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    apt-utils \
                    autoconf \
                    build-essential \
                    bzip2 \
                    ca-certificates \
                    curl \
                    libtool \
                    locales \
                    lsb-release \
                    netbase \
                    pkg-config \
                    unzip \
                    wget \
                    xvfb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Use unicode
RUN locale-gen en_US.UTF-8 || true
ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"

WORKDIR /
RUN curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba

ENV MAMBA_ROOT_PREFIX="/opt/conda"
COPY env.yml /tmp/env.yml
COPY requirements.txt /tmp/requirements.txt
WORKDIR /tmp
RUN micromamba create -y -f /tmp/env.yml && \
    micromamba clean -y -a

# Precaching fonts, set 'Agg' as default backend for matplotlib
RUN micromamba -n base run python -c "from matplotlib import font_manager" && \
    sed -i 's/\(backend *: \).*$/\1Agg/g' $( micromamba -n base run python -c "import matplotlib; print(matplotlib.matplotlib_fname())" )

# UV_USE_IO_URING for apparent race-condition (https://github.com/nodejs/node/issues/48444)
# Check if this is still necessary when updating the base image.
ENV PATH="/opt/conda/bin:$PATH" \
    UV_USE_IO_URING=0

# Installing SVGO and bids-validator
RUN npm install -g svgo@^3.2.0 bids-validator@^1.14.0 && \
    rm -rf ~/.npm ~/.empty /root/.npm

# Initialize templateflow
ENV TEMPLATEFLOW_HOME=/templateflow
RUN templateflow update

# Pacify DataLad
RUN git config --global user.name "NiPreps Miniconda" \
    && git config --global user.email "nipreps@gmail.com"
