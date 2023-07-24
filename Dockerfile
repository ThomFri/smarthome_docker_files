# Use the official Python image as intermediate image
# -> Intermediate image is just there to download files from repo
FROM python:3.9 as intermediate

# To specify main repo
ARG MAIN_REPO
ENV MAIN_REPO $MAIN_REPO
ARG SSH_PRIVATE_KEY
ENV SSH_PRIVATE_KEY $SSH_PRIVATE_KEY
ARG CHAIN_PEM
ENV CHAIN_PEM $CHAIN_PEM

# Create private SSH key in container
RUN mkdir /root/.ssh/
RUN echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa
#ADD id_rsa /root/.ssh/id_rsa
#RUN curl http://192.168.221.188:5000/docker-files/ssh_key --user "admin:admin" --output /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa
RUN touch /root/.ssh/known_hosts
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

# Clone repo from GitHub (using the the SSH link -> this automatically loads "/root/.ssh/id_rsa")
RUN git clone git@github.com:ThomFri/${MAIN_REPO}.git /app
RUN git clone git@github.com:ThomFri/smarthome_modules.git /app/smarthome_modules

# Copy cert file for connect
# COPY ./cert/chain.pem /app/resources/cert/chain.pem
RUN mkdir /app/resources
RUN mkdir /app/resources/cert
# RUN curl http://192.168.221.188:5000/docker-files/chain --user "admin:admin" --output /app/resources/cert/chain.pem
RUN echo "${CHAIN_PEM}" > /app/resources/cert/chain.pem

# Remove SSH key
RUN rm /root/.ssh/id_rsa


# Create acutal image
# -> copies /app data from intermediate image so the SSH key is protected
FROM python:3.9
# Set work dir
WORKDIR /app

# Install git and other dependencies
RUN apt-get update && apt-get install -y git

COPY --from=intermediate /app /app

# Change the access permissions of your repo to avoid any issues (Optional)
RUN chmod -R 777 /app

# Install Python dependencies
RUN pip install --no-cache-dir -r /app/requirements.txt

# Set the entry point to run the main.py script (Replace main.py with your actual main script name)
CMD ["python", "/app/main.py"]

