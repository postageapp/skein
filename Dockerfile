FROM ruby:3.0

COPY . /home/skein

WORKDIR /home/skein

RUN bundle install -j 8
