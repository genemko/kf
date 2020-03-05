# Base Image
FROM nvidia/cuda

# Forces Jupyter to open terminal in Bash
ENV SHELL=/bin/bash

# Create dir app
RUN mkdir /app

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Update and Upgrade
RUN apt-get update && apt-get upgrade -y && apt-get install -y wget

# Install required library for OpenCV
# https://github.com/conda-forge/opencv-feedstock/issues/111#issuecomment-404355280
RUN apt-get install -y libgl1-mesa-glx

# Download and Install Anaconda
#RUN wget https://repo.anaconda.com/archive/Anaconda3-2019.10-Linux-x86_64.sh
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda

# Setup conda bin PATH as symlinks.
#RUN mkdir ${HOME}/.symlinks/
#RUN ln -s /opt/miniconda/bin/conda ${HOME}/.symlinks/conda
#RUN ln -s /opt/miniconda/bin/activate ${HOME}/.symlinks/activate
#RUN ln -s /opt/miniconda/bin/deactivate ${HOME}/.symlinks/deactivate

# Conda Virtual Env Variables
# Note: ${HOME} does not work here because it is a bash env variable and not
# a dockerfile env variable.
# Note: Env variables are only for dockerfile use.
#ENV PATH="/root/.symlinks/:$PATH"
ENV VIRTUAL_ENV="/opt/miniconda"
ENV OLDPATH="$PATH"
ENV PATH="$VIRTUAL_ENV/bin/:$PATH"

#RUN echo $PATH

RUN conda init bash

# Updating Anaconda packages
RUN conda update conda

# Install Tensorflow
#RUN source activate base && \
#    conda install -y tensorflow-gpu

# Install RAPIDS + Plot.ly
RUN conda env create -n kf -f kf2.yml

# Clean up by removing /app
WORKDIR /
RUN rm -rf /app

# Clean up downloaded conda packages
RUN conda clean -tpy

# Conda Programs added to PATH: conda, activate, deactivate.
# Note: Only for bash enterypoint use.
#RUN echo 'export PATH="${HOME}/.symlinks/:$PATH"' >> ${HOME}/.bashrc
# needed for when the container is used as a bash entrypoint.
#RUN echo 'source activate base' >> ${HOME}/.bashrc
RUN echo 'PS1="\u@Kubeflow:\w $ "' >> ${HOME}/.bashrc
RUN echo 'conda activate kf' >> ${HOME}/.bashrc

# Source and setup conda env
# Setup Juyptor Env
#RUN mkdir ${HOME}/.jupyter/

ENV PATH="$VIRTUAL_ENV/envs/kf/bin/:$PATH"
ENV CONDA_DEFAULT_ENV kf
RUN jupyter notebook --generate-config
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager

# Plotly
RUN jupyter labextension install jupyterlab-plotly --no-build
RUN jupyter labextension install plotlywidget --no-build
RUN jupyter lab build

# Bokeh
RUN jupyter labextension install @bokeh/jupyter_bokeh

# NVDashboard
RUN jupyter labextension install jupyterlab-nvdashboard

# Jupyter listens port: 8888
EXPOSE 8008

# Start command
WORKDIR /root
CMD jupyter lab --allow-root --no-browser --ip 0.0.0.0 --port 8008

