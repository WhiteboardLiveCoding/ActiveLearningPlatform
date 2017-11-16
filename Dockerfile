FROM tensorflow/tensorflow:latest-gpu-py3

RUN apt-get update && apt-get install -y git

RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | \
    tee /etc/apt/sources.list.d/azure-cli.list
RUN apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893
RUN apt-get -y install apt-transport-https
RUN apt-get update && apt-get -y install azure-cli

RUN apt-get -y install python3-dev python3-setuptools
RUN apt-get -y install libtiff5-dev libjpeg8-dev zlib1g-dev \
    libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python-tk
RUN pip3 install Pillow

COPY requirements.txt requirements.txt
COPY training/requirements.txt training.txt
COPY wlc/requirements.txt wlc.txt

RUN pip3 install -r requirements.txt -r training.txt -r wlc.txt

RUN mkdir /alp
COPY . /alp

WORKDIR /alp
RUN chmod +x azure/alp.sh

CMD ["azure/alp.sh"]
