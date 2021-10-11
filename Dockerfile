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
#
# This file is derived from https://github.com/ContinuumIO/docker-images/blob/737e57d3997a079897cc6fc95ff9097ffee19fad/miniconda3/alpine/Dockerfile
# and the corresponding copyright notice is reproduced below.
#
# Except where noted below, docker-miniconda is released under the following terms:
#
# (c) 2012 Continuum Analytics, Inc. / http://continuum.io
# All Rights Reserved
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Continuum Analytics, Inc. nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL CONTINUUM ANALYTICS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
FROM alpine:3.14.0 as alpine-glibc

LABEL maintainer="Vlad Frolov"
LABEL src=https://github.com/frol/docker-alpine-glibc
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# hadolint ignore=DL3018
RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.33-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add -q --no-cache --virtual=.build-dependencies wget ca-certificates && \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget -q \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add -q --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del -q glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del -q .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"


FROM alpine-glibc

LABEL maintainer="Anaconda, Inc"

ENV PATH /opt/conda/bin:$PATH

# Leave these args here to better use the Docker build cache
ARG CONDA_VERSION=py38_4.10.3
ARG SHA256SUM=935d72deb16e42739d69644977290395561b7a6db059b316958d97939e9bdf3d

# hadolint ignore=DL3018
RUN apk add -q --no-cache bash procps && \
    wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh -O miniconda.sh && \
    echo "${SHA256SUM}  miniconda.sh" > miniconda.sha256 && \
    if ! sha256sum -cs miniconda.sha256; then exit 1; fi && \
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
                     matplotlib=3.3 \
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

CMD ["/bin/bash"]
