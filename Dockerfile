FROM ruby:2.7-slim

RUN apt-get update && apt-get upgrade -y && apt-get install -y build-essential curl git && apt-get -y autoremove
RUN gem install bundler

WORKDIR /code

COPY . /code
RUN bundle install --jobs=4 --retry=3

RUN bundle exec rake build
