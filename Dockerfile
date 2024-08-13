ARG RUBY_VERSION=3.3
FROM ruby:$RUBY_VERSION-slim

RUN apt-get update \
  && apt-get install -y \
    build-essential \
    git \
    locales \
    nodejs \
    npm

COPY Gemfile Gemfile

RUN NOKOGIRI_USE_SYSTEM_LIBRARIES=true bundle install

RUN \
  echo "en_GB UTF-8" > /etc/locale.gen && \
  locale-gen en-GB.UTF-8
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB.UTF-8
ENV LC_ALL en_GB.UTF-8

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
