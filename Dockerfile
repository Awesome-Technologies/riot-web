# Builder
FROM node:10 as builder

# Support custom branches of the react-sdk and js-sdk. This also helps us build
# images of riot-web develop.
ARG USE_CUSTOM_SDKS=true
ARG REACT_SDK_REPO="https://github.com/awesome-technologies/matrix-react-sdk.git"
ARG REACT_SDK_BRANCH="2020.09.1-caritas"

RUN apt-get update && apt-get install -y git dos2unix

WORKDIR /src

COPY . /src
RUN dos2unix /src/scripts/docker-link-repos.sh && bash /src/scripts/docker-link-repos.sh
RUN yarn --network-timeout=100000 install
RUN yarn build

# Copy the config now so that we don't create another layer in the app image
RUN cp /src/config.sample.json /src/webapp/config.json

# Ensure we populate the version file
RUN dos2unix /src/scripts/docker-write-version.sh && bash /src/scripts/docker-write-version.sh


# App
FROM nginx:alpine

COPY --from=builder /src/webapp /app

# Insert wasm type into Nginx mime.types file so they load correctly.
RUN sed -i '3i\ \ \ \ application/wasm wasm\;' /etc/nginx/mime.types

RUN rm -rf /usr/share/nginx/html \
 && ln -s /app /usr/share/nginx/html
