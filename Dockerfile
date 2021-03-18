FROM balenalib/rpi-raspbian

# Install packages

RUN apt-get update
RUN apt-get install -y jq tzdata python3 python3-dev python3-pip \
        python3-six python3-pyasn1 libportaudio2 alsa-utils \
        portaudio19-dev libffi-dev libssl-dev libmpg123-dev pulseaudio
RUN pip3 install --upgrade pip

COPY requirements.txt /tmp
#ADD .asoundrc /root/

WORKDIR /tmp
RUN pip3 install -r requirements.txt
RUN pip3 install --upgrade six
RUN pip3 install --upgrade google-assistant-library google-auth \
        requests_oauthlib cherrypy flask flask-jsonpify flask-restful \
        grpcio google-assistant-grpc google-auth-oauthlib \
        setuptools wheel google-assistant-sdk[samples] pyopenssl
#RUN apt-get remove -y --purge python3-pip python3-dev

RUN apt-get clean -y
RUN rm -rf /var/lib/apt/lists/*

# Load pulseaudio virtual audio source
RUN pulseaudio -D --exit-idle-time=-1

# Create virtual output device (used for audio playback)
RUN pactl load-module module-null-sink sink_name=DummyOutput sink_properties=device.description="Virtual_Dummy_Output"

# Create virtual microphone output, used to play media into the "microphone"
RUN pactl load-module module-null-sink sink_name=MicOutput sink_properties=device.description="Virtual_Microphone_Output"

# Set the default source device (for future sources) to use the monitor of the virtual microphone output
RUN pacmd set-default-source MicOutput.monitor

# Create a virtual audio source linked up to the virtual microphone output
RUN pacmd load-module module-virtual-source source_name=VirtualMic

#RUN modprobe snd-dummy

# Copy data
COPY run.sh /
COPY *.py /

RUN chmod a+x /run.sh

ENTRYPOINT [ "/run.sh" ]
