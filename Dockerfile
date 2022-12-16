FROM node:16 as installer

ARG APIKEY
ARG API_ENDPOINT
ARG BASEPATH
ARG RECAPTCHA_KEY
ENV APIKEY=$APIKEY
ENV API_ENDPOINT=$API_ENDPOINT
ENV BASEPATH=$BASEPATH
ENV RECAPTCHA_KEY=$RECAPTCHA_KEY
RUN echo "API_ENDPOINT is $API_ENDPOINT"
RUN echo "BASEPATH is $BASEPATH"
RUN echo "APIKEY is $APIKEY"
RUN echo "RECAPTCHA_KEY is $RECAPTCHA_KEY"

COPY . /juice-shop
WORKDIR /juice-shop

RUN sed -i "s|{APIKEY}|$APIKEY|" frontend/src/environments/environment.prod.ts
RUN sed -i "s|{API_ENDPOINT}|$API_ENDPOINT|" frontend/src/environments/environment.prod.ts
RUN sed -i "s|{BASEPATH}|$BASEPATH|" frontend/src/environments/environment.prod.ts
RUN sed -i "s|{RECAPTCHA_KEY}|$RECAPTCHA_KEY|" frontend/src/index.html
RUN sed -i "s|{RECAPTCHA_KEY}|$RECAPTCHA_KEY|" frontend/src/app/app.module.ts

RUN npm i -g npm
RUN npm i -g typescript ts-node
RUN npm install --production --unsafe-perm
RUN npm dedupe
RUN rm -rf frontend/node_modules

FROM node:16-alpine
ARG BUILD_DATE
ARG VCS_REF
LABEL maintainer="Bjoern Kimminich <bjoern.kimminich@owasp.org>" \
    org.opencontainers.image.title="OWASP Juice Shop" \
    org.opencontainers.image.description="Probably the most modern and sophisticated insecure web application" \
    org.opencontainers.image.authors="Bjoern Kimminich <bjoern.kimminich@owasp.org>" \
    org.opencontainers.image.vendor="Open Web Application Security Project" \
    org.opencontainers.image.documentation="https://help.owasp-juice.shop" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.version="14.0.1" \
    org.opencontainers.image.url="https://owasp-juice.shop" \
    org.opencontainers.image.source="https://github.com/juice-shop/juice-shop" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.created=$BUILD_DATE
WORKDIR /juice-shop
RUN addgroup --system --gid 1001 juicer && \
    adduser juicer --system --uid 1001 --ingroup juicer
COPY --from=installer --chown=juicer /juice-shop .
RUN mkdir logs && \
    chown -R juicer logs && \
    chgrp -R 0 ftp/ frontend/dist/ logs/ data/ i18n/ && \
    chmod -R g=u ftp/ frontend/dist/ logs/ data/ i18n/
USER 1001
EXPOSE 3000
CMD ["npm", "start"]
