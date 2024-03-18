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
FROM ubuntu:focal-20210416

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

# Leave these args here to better use the Docker build cache
# miniconda index: https://conda.io/en/latest/miniconda_hashes.html
ENV CONDA_PATH="/opt/conda"
ARG CONDA_VERSION=py39_23.1.0-1
ARG SHA256SUM=5dc619babc1d19d6688617966251a38d245cb93d69066ccde9a013e1ebb5bf18

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh -O miniconda.sh && \
    echo "${SHA256SUM}  miniconda.sh" > miniconda.sha256 && \
    sha256sum -c --status miniconda.sha256 && \
    mkdir -p /opt && \
    sh miniconda.sh -b -p ${CONDA_PATH} && \
    rm miniconda.sh miniconda.sha256 && \
    ln -s ${CONDA_PATH}/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". ${CONDA_PATH}/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    find ${CONDA_PATH}/ -follow -type f -name '*.a' -delete && \
    find ${CONDA_PATH}/ -follow -type f -name '*.js.map' -delete && \
    ${CONDA_PATH}/bin/conda clean -afy

# Set CPATH for packages relying on compiled libs (e.g. indexed_gzip)
ENV PATH="${CONDA_PATH}/bin:$PATH" \
    CPATH="${CONDA_PATH}/include:$CPATH" \
    PYTHONNOUSERSITE=1

COPY condarc /root/.condarc

RUN ${CONDA_PATH}/bin/conda install mamba -n base && \
    mamba install -y \
        attrs=22.2 \
        codecov=2.1 \
        colorclass=2.2 \
        coverage=6.3 \
        curl=7.88 \
        datalad=0.18 \
        dipy=1.5 \
        flake8=4.0 \
        git=2.39 \
        graphviz=3.0 \
        h5py=3.8 \
        indexed_gzip=1.7 \
        jinja2=3.1 \
        libxml2=2.10 \
        libxslt=1.1 \
        lockfile=0.12 \
        matplotlib=3.5 \
        mkl=2022.1 \
        mkl-service=2.4 \
        nibabel=4.0 \
        nilearn=0.9 \
        nipype=1.8 \
        nitime=0.9 \
        nodejs=18 \
        numpy=1.24 \
        packaging=23.0 \
        pandas=1.5 \
        pandoc=2.19 \
        pbr=5.11 \
        pip=23.0 \
        pockets=0.9 \
        psutil=5.9 \
        pydot=1.4 \
        pytest=7.2 \
        pytest-cov=4.0 \
        pytest-env=0.8 \
        pytest-xdist=3.2 \
        pyyaml=6.0 \
        requests=2.28 \
        scikit-image=0.19 \
        scikit-learn=1.2 \
        scipy=1.10 \
        seaborn=0.12 \
        setuptools=65 \
        sphinx=4.5 \
        sphinx_rtd_theme=1.0 \
        svgutils=0.3 \
        toml=0.10 \
        traits=6.3 \
        zlib=1.2 \
        zstd=1.5; sync && \
    chmod -R a+rX ${CONDA_PATH}; sync && \
    chmod +x ${CONDA_PATH}/bin/*; sync && \
    ${CONDA_PATH}/bin/conda clean -afy && sync && \
    rm -rf ~/.conda ~/.cache/pip/*; sync

# Precaching fonts, set 'Agg' as default backend for matplotlib
RUN ${CONDA_PATH}/bin/python -c "from matplotlib import font_manager" && \
    sed -i 's/\(backend *: \).*$/\1Agg/g' $( ${CONDA_PATH}/bin/python -c "import matplotlib; print(matplotlib.matplotlib_fname())" )

# Install packages that are not distributed with conda
RUN ${CONDA_PATH}/bin/python -m pip install --no-cache-dir -U \
                      datalad-osf \
                      etelemetry \
                      nitransforms \
                      templateflow \
                      transforms3d

# Installing SVGO and bids-validator
RUN ${CONDA_PATH}/bin/npm install -g svgo@^2.3 bids-validator@1.8.0 && \
    rm -rf ~/.npm ~/.empty /root/.npm
