# MIT License
#
# Copyright (c) 2021 The NiPreps Developers
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
ENV DEBIAN_FRONTEND=noninteractive

# Prepare environment
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    apt-utils \
                    autoconf \
                    build-essential \
                    bzip2 \
                    ca-certificates \
                    curl \
                    git \
                    libtool \
                    locales \
                    lsb-release \
                    pkg-config \
                    unzip \
                    wget \
                    xvfb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Use unicode
RUN locale-gen en_US.UTF-8 || true
ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"

ENV PATH /opt/conda/bin:$PATH

# Leave these args here to better use the Docker build cache
ARG CONDA_VERSION=py38_4.10.3
ARG SHA256SUM=935d72deb16e42739d69644977290395561b7a6db059b316958d97939e9bdf3d

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh -O miniconda.sh && \
    echo "${SHA256SUM}  miniconda.sh" > miniconda.sha256 && \
    sha256sum -c --status miniconda.sha256 && \
    mkdir -p /opt && \
    sh miniconda.sh -b -p /opt/conda && \
    rm miniconda.sh miniconda.sha256 && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.js.map' -delete && \
    /opt/conda/bin/conda clean -afy

RUN /opt/conda/bin/conda install -c conda-forge -c anaconda \
                     python=3.8 \
                     attrs=21.2 \
                     codecov=2.1 \
                     colorclass \
                     coverage=6.0 \
                     datalad=0.15 \
                     dipy=1.4 \
                     flake8 \
                     git-annex=*=alldep* \
                     graphviz=2.49 \
                     h5py=3.2 \
                     indexed_gzip=1.6 \
                     jinja2=2.11 \
                     libxml2=2.9 \
                     libxslt=1.1 \
                     lockfile=0.12 \
                     "matplotlib>=3.3,<4" \
                     mkl=2021.3 \
                     mkl-service=2.4 \
                     nibabel=3.2 \
                     nilearn=0.8 \
                     nipype=1.6 \
                     nitime=0.9 \
                     nodejs=16 \
                     numpy=1.20 \
                     packaging=21 \
                     pandas=1.2 \
                     pandoc=2.14 \
                     pbr \
                     pip=21.2 \
                     pockets \
                     psutil=5.8 \
                     pydot=1.4 \
                     pydotplus=2.0 \
                     pytest=6.2 \
                     pytest-cov=3.0 \
                     pytest-env=0.6 \
                     pytest-xdist \
                     pyyaml=5.4 \
                     requests=2.26 \
                     scikit-image=0.18 \
                     scikit-learn=0.24 \
                     scipy=1.6 \
                     seaborn=0.11 \
                     setuptools=58.2 \
                     sphinx=4.2 \
                     sphinx_rtd_theme=1.0 \
                     "svgutils>=0.3.4,<0.4" \
                     toml=0.10 \
                     traits=6.2 \
                     zlib=1.2 \
                     zstd=1.5; sync && \
    chmod -R a+rX /opt/conda; sync && \
    chmod +x /opt/conda/bin/*; sync && \
    /opt/conda/bin/conda clean -afy && sync && \
    rm -rf ~/.conda ~/.cache/pip/*; sync
    
# Precaching fonts, set 'Agg' as default backend for matplotlib
RUN /opt/conda/bin/python -c "from matplotlib import font_manager" && \
    sed -i 's/\(backend *: \).*$/\1Agg/g' $( /opt/conda/bin/python -c "import matplotlib; print(matplotlib.matplotlib_fname())" )

# Install packages that are not distributed with conda
RUN /opt/conda/bin/python -m pip install --no-cache-dir -U \
                      etelemetry \
                      nitransforms \
                      templateflow \
                      transforms3d

# Installing SVGO and bids-validator
RUN /opt/conda/bin/npm install -g svgo@^2.3 bids-validator@1.8.0 && \
    rm -rf ~/.npm ~/.empty /root/.npm
